

#include "EXTERN.h"
#include "perl.h"
#include "utf8.h"
#include "XSUB.h"
#define PERL_IN_UTF8_C


typedef enum {SAR_FALSE, SAR_TRUE} sar_bool; 
typedef enum {SAR_NOCLASS, SAR_CHAR, SAR_DIGIT, SAR_DOT, SAR_SPACE, SAR_ALPHA_NUM, SAR_ALPHA} sar_nodeClass; 

#define SAR_STOP_MATCH 1
#define SAR_PROC_FROM 2


#include "regex_sar.h"
#include "node_with_func.c"
#include "node_path.c"


MODULE = Regexp::SAR		PACKAGE = Regexp::SAR		



sarRootNode_t *
buildRootNode()
CODE:
    RETVAL = sar_buildRootNode_c();
OUTPUT:
    RETVAL


int
getCharsNumber(rootNode)
    sarRootNode_t * rootNode;
CODE:
    sarNode_p node = rootNode->sarNode;
    RETVAL = node->charNumber;
OUTPUT:
    RETVAL


char *
getCharsAsStr(rootNode)
    sarRootNode_t * rootNode;
INIT:
    char * retTmp;
    char * sarChars;
    int charsNumber;
    int currOffset;
CODE:
    sarNode_p node = rootNode->sarNode;
    charsNumber = node->charNumber;
    Newx(RETVAL, charsNumber + 1, char);
    retTmp = RETVAL;
    sarChars = node->sarPathChars;
    for(currOffset = 0; currOffset < charsNumber; ++currOffset) {
        *retTmp++ = *sarChars++;
    }
    * retTmp ='\0';
OUTPUT:
    RETVAL
CLEANUP:
    Safefree(RETVAL);




int
searchNode(rootNode, pathChar)
    sarRootNode_t * rootNode;
    char pathChar;
CODE:
    sarNode_p node = rootNode->sarNode;
    RETVAL = sar_searchChar_c(node->sarPathChars, node->charNumber, pathChar);
OUTPUT:
    RETVAL


void
buildPath(rootNode, regexp, len, callFunc)
    sarRootNode_t * rootNode;
    char * regexp;
    int len;
    SV * callFunc;
CODE:
    sarNode_p node = rootNode->sarNode;
    sar_buildPath_c(node, regexp, len, callFunc);



void
lookPath(rootNode, string, pos)
    sarRootNode_t * rootNode;
    SV * string;
    long pos;
PREINIT:
    const char * ptr;
    long len;
CODE:
    if (SvROK(string) && !SvOBJECT(SvRV(string))) {
        string = SvRV(string);
    }
    ptr = SvPV_const(string, len);
    sar_lookPath_c(rootNode, ptr, len, pos);


void
lookPathRef(rootNode, stringRef, pos)
    sarRootNode_t * rootNode;
    SV * stringRef;
    long pos;
PREINIT:
    const char * ptr;
    long len;
CODE:
    SV * string = (SV *)(SvRV(stringRef)); 
    if (SvROK(string) && !SvOBJECT(SvRV(string))) {
        string = SvRV(string);
    }
    ptr = SvPV_const(string, len);
    sar_lookPath_c(rootNode, ptr, len, pos);


void
lookPathAtPos(rootNode, string, pos)
    sarRootNode_t * rootNode;
    SV * string;
    long pos;
PREINIT:
    const char * ptr;
    long len;
CODE:
    if (SvROK(string) && !SvOBJECT(SvRV(string))) {
        string = SvRV(string);
    }
    ptr = SvPV_const(string, len);
    sarNode_p node = rootNode->sarNode;
    sar_lookPathFromPos_c(node, pos, ptr, len);




void
stop(rootNode)
    sarRootNode_t * rootNode;
CODE:
    rootNode->procFlags = SAR_STOP_MATCH;


void
continue(rootNode, from)
    sarRootNode_t * rootNode;
    long from;
CODE:
    rootNode->procFlags = SAR_PROC_FROM;
    rootNode->continueFrom = from;



void
cleanAll(rootNode)
    sarRootNode_t * rootNode;
CODE:
    sarNode_p node = rootNode->sarNode;
    sar_cleanAll_c(node);
    Safefree(rootNode);

  


