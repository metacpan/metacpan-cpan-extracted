
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define LPM_MAX_INSTANCES 1024


#include <stdio.h>  
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <arpa/inet.h>

#define BUFFSIZE 60
#define ALOCSIZE 100000

#define HV_STORE_NV(r,k,v) (void)hv_store(r, k, strlen(k), newSVnv(v), 0)

const int lastAlocIndex = ALOCSIZE - 1;  

/// Structure of Node in Trie
typedef struct TrieNode{
  struct TrieNode *pTN0;
  struct TrieNode *pTN1;
  SV * Value;
  bool hasValue;
} TTrieNode;

/* linked list of TTrieNode(s) */
typedef struct TrieNodeList {
	struct TrieNode *pNode;
	struct TrieNodeList *pNext;
	int Depth;
	int AfType;
	char *Prefix;
} TTrieNodeList;

/// Structure of alokated chunks of Trie Nodes
typedef struct AlocTrieNodes{
  struct TrieNode TrieNodes[ALOCSIZE];
  struct AlocTrieNodes *pNextATN;
} TAlocTrieNodes;


/* instance data */
typedef struct lpm_instance_s
{
	TTrieNode *pTrieIPV4;
	TTrieNode *pTrieIPV6;
} lpm_instance_t;


/* array of initalized instances */
lpm_instance_t *lpm_instances[LPM_MAX_INSTANCES] = { NULL };


/// function Prototypes

void addPrefixToTrie(unsigned char *prefix, unsigned char prefixLen, SV * Value,  TTrieNode **ppTrie);
TTrieNode *createTrieNode();
void freeAlocTrieNodes(TAlocTrieNodes *pATN);
TTrieNode *lookupAddress(unsigned char *address, int addrLen, TTrieNode *pTN);
TTrieNode **lookupInTrie(unsigned char *prefix, unsigned char *byte, unsigned char *bit, unsigned char *makeMatches, TTrieNode **ppTN, bool *root); 
TTrieNode *myMalloc();
int listTrieNode(TTrieNode *pTN, TTrieNodeList **plTN, const int AfType, int *depth, unsigned char *prefix);


/// Alocation speeding variables
TAlocTrieNodes *pAlocated = NULL;
TAlocTrieNodes *pActual = NULL;
struct TrieNode *pActualTN = NULL;
struct TrieNode *pLastTN = NULL;

/// IPV4 Trie
TTrieNode *pTrieIPV4 = NULL;

/// IPV6 Trie
TTrieNode *pTrieIPV6 = NULL;

/* clean tree and decrement reference count */
void freeTrieNode(TTrieNode *pTN) {
	if (pTN != NULL) {
		if (pTN->hasValue) {
			pTN->hasValue = false;
			SvREFCNT_dec(pTN->Value);
		}
		freeTrieNode(pTN->pTN0);
		freeTrieNode(pTN->pTN1);
		free(pTN);
	}
}

/* count the number of nodes in subtree */
void countTrieNode(TTrieNode *pTN, int * totalNodes, int * valueNodes, int * trieBytes, int * dataBytes) {
	if (pTN != NULL) {
		if (pTN->hasValue) {
			(*valueNodes)++;
			(*dataBytes) += 0;
		}
		countTrieNode(pTN->pTN0, totalNodes, valueNodes, trieBytes, dataBytes);
		countTrieNode(pTN->pTN1, totalNodes, valueNodes, trieBytes, dataBytes);
		(*totalNodes)++;
		(*trieBytes) += sizeof(struct TrieNode);
	}
}

/* convert trie node into linked list  */
int listTrieNode(TTrieNode *pTN, TTrieNodeList **plTN, const int AfType, int *depth, unsigned char *prefix) {
	TTrieNodeList *ptmp;
	int allocsize;

	if (pTN != NULL) {
		if (pTN->hasValue) {
			ptmp = malloc(sizeof(TTrieNodeList));
			if (ptmp == NULL) {
				return 0;
			}
			/* get prefix len */
			allocsize = (((*depth) - 1) / 8) + 1;

			ptmp->pNext = *plTN;
			ptmp->pNode = pTN;
			ptmp->Depth = *depth;
			ptmp->AfType = AfType;
			ptmp->Prefix = malloc(allocsize);
			if (ptmp->Prefix == NULL) {
				return 0;
			}
			memcpy(ptmp->Prefix, prefix, allocsize);
			
			*plTN = ptmp;
		}
		(*depth)++;

		if (listTrieNode(pTN->pTN0, plTN, AfType, depth, prefix) == 0) return 0;

		prefix[((*depth) - 1 ) / 8] |= 0x80 >> ((((*depth) - 1) % 8) );
		if (listTrieNode(pTN->pTN1, plTN, AfType, depth, prefix) == 0) return 0;
		prefix[((*depth) - 1 ) / 8] &= 0xFF7F >> ((((*depth) - 1) % 8) );

		(*depth)--;

	}
	return 1;
}

/**
 * addPrefixToTrie adds prefix to Trie
 * prefix - prefix that will be added to Trie
 * prefixLen - prefix length
 * ASNum - number of AS
 * ppTrie - pointer at pointer of desired Trie(IPV4 or IPV6)
 * returns error if fails
 */
void addPrefixToTrie(unsigned char *prefix, unsigned char prefixLen, SV * Value, TTrieNode **ppTrie){
  unsigned char byte = 0;
  unsigned char bit = 128; 
  
  unsigned char makeMatches = prefixLen;
  bool root = false;
  TTrieNode *pFound = (*ppTrie);
  TTrieNode **ppTN = lookupInTrie(prefix, &byte, &bit, &makeMatches, &pFound, &root);
  if(root){
    ppTN = ppTrie;
  }
  if(ppTN != NULL){
    while(makeMatches){
      (*ppTN) = createTrieNode();
      unsigned char unmasked = (prefix[byte] & bit);
      
      if(unmasked){
        ppTN = &((*ppTN)->pTN1);        
      }
      else{
        ppTN = &((*ppTN)->pTN0);
      }
      
      makeMatches--;
      bit = (bit >> 1);
      if(!bit){
        byte++;
        bit = 128;
      }
    }
    
    (*ppTN) = createTrieNode();
    (*ppTN)->Value = Value;
    (*ppTN)->hasValue = true;
	SvREFCNT_inc(Value);
  }
  else{
    if(!pFound->hasValue){      
      pFound->Value = Value;
      pFound->hasValue = true;
	  SvREFCNT_inc(Value);
    }
  }
}

/**
 * createTrieNode creates Node of Trie and sets him implicitly up
 * returns NULL or created Node of Trie
 */
TTrieNode *createTrieNode(){
  //TTrieNode *pTN = myMalloc(sizeof(struct TrieNode));
  TTrieNode *pTN = malloc(sizeof(struct TrieNode));
  if(pTN == NULL){
    fprintf(stderr, "pTN malloc error.");
    return NULL;
  }
  
  // initialize
  pTN->pTN0 = NULL;
  pTN->pTN1 = NULL;
  pTN->hasValue = false;
  
  return pTN;
}


/**
 *  freeAlocTrieNodes
 *  pATN - pointer at structure to be freed  
 */ 
void freeAlocTrieNodes(TAlocTrieNodes *pATN){
  if(pATN->pNextATN != NULL){
    freeAlocTrieNodes(pATN->pNextATN);  
  }  
  free(pATN);
}

/** 
 * lookupAddressIPv6
 * address - field with address
 * addrLen - length of IP adress in bits (32 for IPv4, 128 for IPv6)
 * returns NULL when NOT match adress to any prefix in Trie
 */
TTrieNode *lookupAddress(unsigned char *address, int addrLen, TTrieNode *pTN){ 
  unsigned char byte = 0;
  unsigned char bit = 128; // most significant bit 
//  TTrieNode *pTN = pTrieIPV6;
  TTrieNode *pTNValue = NULL; 

  if (pTN == NULL) {
  	return NULL;
  }
  
  unsigned char addrPassed = 0;
  while(addrPassed++ <= addrLen){
    unsigned char unmasked = (address[byte] & bit);
    bit = (bit >> 1);    
    if(!bit){
      byte++;
      bit = 128;
    }
    
    // pTN with ASNum is desired
    if(pTN->hasValue){
      pTNValue = pTN;
    }
    
    if(unmasked){
      if(pTN->pTN1 != NULL){
        pTN = pTN->pTN1;
      }
      else{
        return pTNValue;
      }                   
    }
    else{
      if(pTN->pTN0 != NULL){
        pTN = pTN->pTN0;
      }
      else{
        return pTNValue;
      }       
    }           
  }       
  return pTNValue;
}

/** 
 * lookupInTrie
 * prefix - holds the prefix that is searched during Trie building
 * byte - byte of prefix
 * bit - bit of prefix byte
 * makeMatches - input and output,indicates prefixLen that can be used
 * ppTN - input and output, determines which Node of Trie was examined last during function proccess, at start holds the root of Trie  
 * root - return flag, true if root of Trie must be build first
 * returns NULL when match current prefix during Trie building
 */
TTrieNode **lookupInTrie(unsigned char *prefix, unsigned char *byte, unsigned char *bit, unsigned char *makeMatches, TTrieNode **ppTN, bool *root){
  if((*ppTN) == NULL){
    (*root) = true;
    return ppTN;
  }
  
  while((*makeMatches)){    
    unsigned char unmasked = (prefix[(*byte)] & (*bit));
    (*makeMatches)--;
    (*bit) = ((*bit) >> 1);
    if(!(*bit)){
      (*byte)++;
      (*bit) = 128;
    }
    
    if(unmasked){
      if((*ppTN)->pTN1 != NULL){
        (*ppTN) = (*ppTN)->pTN1;
      }
      else{
        return &((*ppTN)->pTN1);
      }                      
    }
    else{
      if((*ppTN)->pTN0 != NULL){
        (*ppTN) = (*ppTN)->pTN0;
      }
      else{
        return &((*ppTN)->pTN0);
      }    
    }           
  }
  
  (*root) = false;
  return NULL;
}

/**
 * myMalloc
 * encapsulates real malloc function but call it less times 
 * and that is why it could save some presious time
 */ 
TTrieNode *myMalloc(){
  if(pAlocated == NULL){
    pAlocated = malloc(sizeof(struct AlocTrieNodes));
    if(pAlocated == NULL){
      return NULL;
    }
    
    pAlocated->pNextATN = NULL;
    pActual = pAlocated;
    pActualTN = &pActual->TrieNodes[0];
    pLastTN = &pActual->TrieNodes[lastAlocIndex]; 
  }
  
  // Save to return it later
  TTrieNode *pReturn = pActualTN;
  
  if(pActualTN == pLastTN){
    pActual->pNextATN = malloc(sizeof(struct AlocTrieNodes));
    pActual = pActual->pNextATN;
    if(pActual == NULL){
      return NULL;
    }
    
    pActual->pNextATN = NULL;
    pActualTN = &pActual->TrieNodes[0];
    pLastTN = &pActual->TrieNodes[lastAlocIndex];
  }
  else{
    pActualTN++;
  }
  
  return pReturn;  
}


/********************************************************************/
/* PERL INTERFACE                                                   */
/********************************************************************/

int lpm_init(void) {
int handle = 1;
lpm_instance_t *instance;
//int i;

	/* find the first free handler and assign to array of open handlers/instances */
	while (lpm_instances[handle] != NULL) {
		handle++;
		if (handle >= LPM_MAX_INSTANCES - 1) {
			croak("No free handles available, max instances %d reached", LPM_MAX_INSTANCES);
			return 0;
		}
	}

	instance = malloc(sizeof(lpm_instance_t));
	if (instance == NULL) {
		croak("can not allocate memory for instance");
		return 0;
	}

	memset(instance, 0, sizeof(lpm_instance_t));

	instance->pTrieIPV4 = NULL;
	instance->pTrieIPV6 = NULL;

    lpm_instances[handle] = instance;
	
	return handle;
}

int lpm_add_raw(int handle, SV * svprefix, int prefix_len, SV *value) {
lpm_instance_t *instance = lpm_instances[handle];
STRLEN len;
char * prefix;

	if (instance == NULL ) {
		croak("handler %d not initialized", handle);
		return 0;
	}

	prefix = SvPV(svprefix, len);

	if (len == 4){
		addPrefixToTrie((void *)prefix, prefix_len, value, &instance->pTrieIPV4);
	} 
	else if (len == 16) {
		addPrefixToTrie((void *)prefix, prefix_len, value, &instance->pTrieIPV6);
	}
	else{ // Corrupted input file
		croak("Cannot add prefix %s", prefix);
		return 0;
	}
	
	/* included code */
	return 1;
}

SV *lpm_lookup_raw(int handle, SV *svaddr) {
lpm_instance_t *instance = lpm_instances[handle];
//SV *out = NULL;
//char buf[BUFFSIZE];
//char *buf = NULL;
char *addr;
STRLEN len;

	if (instance == NULL ) {
		croak("handler %d not initialized", handle);
		return NULL;
	}

	TTrieNode *pTN = NULL;
	addr = SvPV(svaddr, len);
	 
    if(len == 4){
      pTN = lookupAddress((void *)addr, 32, instance->pTrieIPV4);
    }
    else if(len == 16){ // IPV6
      pTN = lookupAddress((void *)addr, 128, instance->pTrieIPV6);
    } 

    if ( pTN == NULL ){
		return &PL_sv_undef;
    } else {
		SvREFCNT_inc(pTN->Value);
		return pTN->Value;
    }
}

SV * lpm_info(int handle) {
lpm_instance_t *instance = lpm_instances[handle];
int totalNodes, valueNodes, trieBytes, dataBytes;
HV * res;

	if (instance == NULL ) {
		croak("handler %d not initialized", handle);
		return &PL_sv_undef;
	}

	res = (HV *)sv_2mortal((SV *)newHV());

	totalNodes = 0;
	valueNodes = 0;
	trieBytes = 0;
	dataBytes = 0;
	countTrieNode(instance->pTrieIPV4, &totalNodes, &valueNodes, &trieBytes, &dataBytes);
	HV_STORE_NV(res, "ipv4_nodes_total", totalNodes);
	HV_STORE_NV(res, "ipv4_nodes_value", valueNodes);
	HV_STORE_NV(res, "ipv4_trie_bytes", trieBytes);
//	HV_STORE_NV(res, "ipv4_data_bytes", dataBytes);

	totalNodes = 0;
	valueNodes = 0;
	trieBytes = 0;
	dataBytes = 0;
	countTrieNode(instance->pTrieIPV6, &totalNodes, &valueNodes, &trieBytes, &dataBytes);
	HV_STORE_NV(res, "ipv6_nodes_total", totalNodes);
	HV_STORE_NV(res, "ipv6_nodes_value", valueNodes);
	HV_STORE_NV(res, "ipv6_trie_bytes", trieBytes);
//	HV_STORE_NV(res, "ipv6_data_bytes", dataBytes);

	return newRV((SV *)res);

}

SV * lpm_dump(int handle) {
lpm_instance_t *instance = lpm_instances[handle];
TTrieNodeList *ptmp;
TTrieNodeList *plist = NULL;
HV * res;
unsigned char prefix[BUFFSIZE];
int depth;

	if (instance == NULL ) {
		croak("handler %d not initialized", handle);
		return &PL_sv_undef;
	}

	res = (HV *)sv_2mortal((SV *)newHV());

	if (instance->pTrieIPV4 != NULL) {
		depth = 0;
		memset(&prefix, 0x0, sizeof(prefix));
		listTrieNode(instance->pTrieIPV4, &plist, AF_INET, &depth, prefix);
	}

	if (instance->pTrieIPV6 != NULL) {
		depth = 0;
		memset(&prefix, 0x0, sizeof(prefix));
		listTrieNode(instance->pTrieIPV6, &plist, AF_INET6, &depth, prefix);
	}


	while (plist != NULL) {
		STRLEN len;
		char buf[BUFFSIZE];
		char buf2[BUFFSIZE];
		int allocsize;

		allocsize = ((plist->Depth - 1) / 8) + 1;

		memset(prefix, 0x0, BUFFSIZE - 1);
		memcpy(prefix, plist->Prefix, allocsize); 

		inet_ntop(plist->AfType, prefix, buf, BUFFSIZE);

		sprintf(buf2, "%s/%d", buf, plist->Depth);

		SvREFCNT_inc(plist->pNode->Value);
		hv_store(res, buf2, strlen(buf2),  plist->pNode->Value, 0);

		ptmp = plist;
		plist = plist->pNext;
		free(ptmp);
	}

	return newRV((SV *)res);
}

void lpm_finish(int handle) {
lpm_instance_t *instance = lpm_instances[handle];

	if (instance == NULL ) {
		croak("handler %d not initialized", handle);
		return;
	}

	if (instance->pTrieIPV4 != NULL) {
		freeTrieNode(instance->pTrieIPV4);
		instance->pTrieIPV4 = NULL;
	}

	if (instance->pTrieIPV6 != NULL) {
		freeTrieNode(instance->pTrieIPV6);
		instance->pTrieIPV6 = NULL;
	}
	return;
}


void lpm_destroy(int handle) {
lpm_instance_t *instance = lpm_instances[handle];

	if (instance == NULL ) {
		croak("handler %d not initialized", handle);
		return;
	}

//	freeAlocTrieNodes(instance->pTrieIPV4);
//	freeAlocTrieNodes(instance->pTrieIPV6);

	lpm_finish(handle);
	free(instance);
	lpm_instances[handle] = NULL;

	return;
}


