#include <stdlib.h>
#include <stdio.h>

#include "..\ln_globals.h"

#define LN_WARNING_NO_NEW_SESSION \
   "Notes::Session->new: NotesInitExtended error/thr. session counter:"
#define LN_WARNING_LENGTH_NO_NEW_SESSION    256
#define LN_STAT_TEXT_LMBCS_LENGTH           256
#define LN_STAT_TEXT_NATIVE_LENGTH          512

/* Module and process (???) global reference counter
 * NOTE: This is the only critical thing for multi-threading
 */
static int   ln_global_session_count;

STATUS   session_new();
void     session_destroy();