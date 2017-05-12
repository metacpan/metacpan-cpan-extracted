#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "opcapi.h"

const int opc_const_OPC_SEV_UNKNOWN()   { return OPC_SEV_UNKNOWN; }
const int opc_const_OPC_SEV_UNCHANGED() { return OPC_SEV_UNCHANGED; }
const int opc_const_OPC_SEV_NONE()      { return OPC_SEV_NONE; }
const int opc_const_OPC_SEV_NORMAL()    { return OPC_SEV_NORMAL; }
const int opc_const_OPC_SEV_WARNING()   { return OPC_SEV_WARNING; }
const int opc_const_OPC_SEV_MINOR()     { return OPC_SEV_MINOR; }
const int opc_const_OPC_SEV_MAJOR()     { return OPC_SEV_MAJOR; }
const int opc_const_OPC_SEV_CRITICAL()  { return OPC_SEV_CRITICAL; }


MODULE = Openview::Message::opcmsg  PACKAGE = Openview::Message::opcmsg	PREFIX = opc_const_

=cut
int
constant(name)
   char * name
   PPCODE:
   {
      SV      *Return;
      int     result;
      if ( (result = constant_int(name)) != 0 ) 
      {
         Return = sv_newmortal();
         sv_setiv(Return, (IV)result);	
         XPUSHs(Return);
      } else 
      {
         XSRETURN_UNDEF;
      }
   }
=cut

PROTOTYPES: ENABLE

int
opc_const_OPC_SEV_UNKNOWN()

int
opc_const_OPC_SEV_UNCHANGED()

int
opc_const_OPC_SEV_NONE()

int
opc_const_OPC_SEV_NORMAL()

int
opc_const_OPC_SEV_WARNING()

int
opc_const_OPC_SEV_MINOR()

int
opc_const_OPC_SEV_MAJOR()

int
opc_const_OPC_SEV_CRITICAL()

int 
opcmsg(sev,app,obj,text,group,host)
   int sev
   char * app
   char * obj
   char * text
   char * group
   char * host

