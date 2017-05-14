

typedef struct sarNode_t {
	char pathChar;
    int charNumber;
    char * sarPathChars;
    struct sarNode_t ** sarNodes;
    struct sarNode_t * plusNode;
    struct sarNode_t * negativeNode;
    struct sarNode_t * digitNode;
    struct sarNode_t * dotNode;
    struct sarNode_t * spaceNode;
    struct sarNode_t * alphaNumNode;
    struct sarNode_t * alphaNode;
    SV ** callFunc;
    sar_bool getCallFunc;
} sarNode_t;
typedef sarNode_t * sarNode_p;


typedef struct sarRootNode_t {
	sarNode_p sarNode;
	int procFlags;
	long continueFrom;
} sarRootNode_t;
typedef sarRootNode_t * sarRootNode_p;



