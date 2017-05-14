#include "notessession.h"


STATUS session_new()
{
	STATUS error;						/* error code from API calls */

	error = NotesInitExtended((int)0, (char **)NULL);
	return(error);
}

void session_destroy()
{
	NotesTerm();
}