#ifndef _bb188d3d_e320_11dc_8b9d_00502c05c241_
#define _bb188d3d_e320_11dc_8b9d_00502c05c241_

void call_StartElementHandlerCommon(char *tag, int hasChild);

void call_StartElementHandlerIdentifier(char *tag, int hasChild, char *identifier, char *replaceable);

void call_StartElementHandlerMacro(char *tag, int hasChild, char *identifier);

void call_StartElementHandlerText(char *tag, int hasChild, char *value);

void call_EndElementHandler(char *tag);

void call_CharacterDataHandler(char *string);

void call_ProcessingInstructionHandler(char *target,char *data);

void call_CommentHandler(char *string);

void call_StartCdataHandler();

void call_EndCdataHandler();

void call_XMLDeclHandler(char *version, char *encoding, char *standalone);

void call_StartElementHandlerFile(char *tag, int hasChild, char *path, 
    int lines, int guarded, char *guardId, char *atime, char *mtime);

void call_StartElementHandlerIncludePath(char *tag, int hasChild, char *path, int used);

#endif // _bb188d3d_e320_11dc_8b9d_00502c05c241_

