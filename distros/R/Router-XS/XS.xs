#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "uthash.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define WORDLEN 32
#define PATHLEN 1024

#ifdef DEBUG
#define DEBUG_PRINT(...) fprintf( stderr, __VA_ARGS__ )
#else
#define DEBUG_PRINT(...) do{ } while ( 0 )
#endif

typedef struct Node {
  char   word[WORDLEN];
  struct Node *children;
  void   *coderef;
  size_t *captures;
  size_t numcaptures;
  UT_hash_handle hh; // makes this structure hashable
} Node;

static char * WILD = "*";
static char SPLITBUF[WORDLEN][WORDLEN];
static size_t SPLITBUFLEN;
static Node * MATCHBUF[WORDLEN][WORDLEN];
static char SPLITCPY[PATHLEN];
static char CAPBUF[WORDLEN][WORDLEN];
Node *ROOT;

Node * NodeNew(char *word) {
  Node *n = malloc(sizeof(Node));
  strcpy(n->word, word);
  n->children = NULL;
  n->coderef  = NULL;
  return n;
}

Node * NodeAddChild(Node *n, char *word) {
  DEBUG_PRINT("adding child %s\n", word);
  Node *child;
  HASH_FIND_STR(n->children, word, child);

  if (!child) {
    child = NodeNew(word);
    HASH_ADD_STR(n->children, word, child);
  }
  return child;
}

void pathsplit(char* path, size_t pathlen, char* delim, size_t* numwords) {
  // +1 for the null terminator \0
  memcpy(SPLITCPY, path, pathlen + 1);
  size_t tokens_used = 0;
  char *token, *rest = SPLITCPY;
  while ((token = strsep(&rest, delim)) != NULL) {
    memcpy(SPLITBUF[tokens_used++], token, WORDLEN);
  }
  *numwords = tokens_used;
}

void NodeAddPath(Node *n, char *path, size_t pathlen, void *coderef) {
  DEBUG_PRINT("\nadding path: %s\n", path);
  pathsplit(path, pathlen, "/", &SPLITBUFLEN);
  size_t captures[WORDLEN], numcaptures = 0, skipped = 0;

  for (size_t i = 0; i < SPLITBUFLEN; i++) {
    // skip zero length strings
    if (! *(SPLITBUF[i]) ) {
      skipped += 1;
      continue;
    }
    // the first word is HTTP method: it can be wildcard but not captured
    if (i && strcmp(WILD, SPLITBUF[i]) == 0) {
      captures[numcaptures] = i - skipped;
      numcaptures += 1;
    }
    n = NodeAddChild(n, SPLITBUF[i]);
  }
  n->coderef = coderef;
  n->numcaptures = numcaptures;
  n->captures = malloc(sizeof(size_t) * numcaptures);
  for (int i = 0; i < numcaptures; i++) {
    *(n->captures + i) = captures[i];
  }
}

Node * NodeSearch(size_t bufidx, size_t matchidx, size_t matchcount) {
  DEBUG_PRINT("starting NodeSearch part %zu matchcount: %zu\n", bufidx, matchcount);
  size_t newmatches = 0;

  // skip zero length strings
  if (! *(SPLITBUF[bufidx])) {
    DEBUG_PRINT("Found zero length string\n");
    // if there are more words in the split buffer, keep going
    if (bufidx + 1 < SPLITBUFLEN) {
      bufidx += 1;
    }
    else if (matchcount) {
      // we're at the end of the path
      // update vars to the previous iteration
      newmatches = matchcount;
      matchidx -= 1;
      DEBUG_PRINT("goto MATCHES\n");
      goto MATCHES;
    }
    else {
      goto ENDNODESEARCH;
    }
  }
  for (int i = 0; i < matchcount; i++) {
    DEBUG_PRINT("searching %s\n", SPLITBUF[bufidx]);

    Node *n;
    HASH_FIND_STR(MATCHBUF[matchidx][i]->children, SPLITBUF[bufidx], n);
    if (n) {
      MATCHBUF[matchidx + 1][newmatches] = n;
      newmatches += 1;
    }
    DEBUG_PRINT("searching %s\n", WILD);
    // check for a wildcard match
    Node *w;
    HASH_FIND_STR(MATCHBUF[matchidx][i]->children, WILD, w);
    if (w) {
      MATCHBUF[matchidx + 1][newmatches] = w;
      newmatches += 1;

      // the first word is always the HTTP method, which we never capture
      if (matchidx) {
        DEBUG_PRINT("capturing %s\n", SPLITBUF[bufidx]);
      }
    }
  }
  DEBUG_PRINT("Found %zu matches\n", newmatches);
  // if there are no new matches
  if (newmatches) {
    // keep going if there are more words in the path to match
    if (bufidx + 1 < SPLITBUFLEN) {
      return NodeSearch(bufidx + 1, matchidx + 1, newmatches);
    }
    else {
      MATCHES:
      // we've matched all the words in the path return the first match
      for (int i = 0; i < newmatches; i++) {
        Node *n = MATCHBUF[matchidx + 1][i];
        // only a complete path match will have the coderef set in the leaf node
        if (n->coderef)
          return n;
      }
    }
  }
  ENDNODESEARCH:
  DEBUG_PRINT("returning NULL\n");
  return NULL;
}

void * NodeTestPath(Node *r, char *path, size_t pathlen, size_t *numcaptures) {
  DEBUG_PRINT("\ntesting path: %s\n", path);
  pathsplit(path, pathlen, "/", &SPLITBUFLEN);

  MATCHBUF[0][0] = r;
  Node *n = NodeSearch(0, 0, 1);

  if (n) {
    DEBUG_PRINT("matched full path\n");
    for (int i = 0; i < n->numcaptures; i++) {
      memcpy(CAPBUF[i], SPLITBUF[ *(n->captures + i) ], WORDLEN);
    }
    *numcaptures = n->numcaptures;
    return n->coderef;
  }
  return NULL;
}

MODULE = Router::XS PACKAGE = Router::XS
PROTOTYPES: DISABLED

BOOT:
ROOT = NodeNew("");

void
add_route(path, coderef)
  SV *path
  SV *coderef
  PREINIT:
    char *pathstr;
    size_t pathlen, numcaptures = 0;

  PPCODE:
    SvGETMAGIC(path);

    /* check for undef, empty string */
    if (!SvOK(path) || !SvCUR(path) || !SvROK(coderef))
    {
      croak("requires path and coderef arguments");
    }

    pathstr = SvPV_nomg(path, pathlen);

    if (NodeTestPath(ROOT, pathstr, pathlen, &numcaptures)) {
      croak("Attempted to add duplicate path %s", pathstr);
    }

    // increment the refcount to stop Perl deleting it
    SvREFCNT_inc(coderef);

    NodeAddPath(ROOT, pathstr, pathlen, coderef);

    // return undef
    EXTEND(SP, 1);
    PUSHs(sv_newmortal());

void
check_route(path)
  SV *path
  PREINIT:
    char *pathstr;
    SV *coderef;
    size_t numcaptures = 0, caplen, pathlen;

  PPCODE:
    SvGETMAGIC(path);

    /* check for undef, empty string */
    if (!SvOK(path) || !SvCUR(path))
    {
      croak("requires path");
    }

    pathstr = SvPV_nomg(path, pathlen);
    coderef = NodeTestPath(ROOT, pathstr, pathlen, &numcaptures);
    EXTEND(SP, 1);

    if (coderef) {
      PUSHMARK(SP);
      PUSHs(coderef);
      if (numcaptures) {
        EXTEND(SP, numcaptures);
        for (int i = 0; i < numcaptures; i++) {
          caplen = strlen(CAPBUF[i]);
          PUSHs( sv_2mortal(newSVpvn(CAPBUF[i], caplen)) );
        }
      }
      PUTBACK;
    }
    else {
      // return undef
      PUSHs(sv_newmortal());
    }
