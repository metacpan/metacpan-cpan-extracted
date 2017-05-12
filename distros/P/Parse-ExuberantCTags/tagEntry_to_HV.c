#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "readtags.h"
#include "tagEntry_to_HV.h"
#ifdef __cplusplus
}
#endif


/* Will convert a C tagEntry* to a Perl HV* */
HV*
tagEntry_to_HV(tagEntry* theEntry)
{
  HV* hv = newHV();
  HV* extHash;
  SV* sv;
  unsigned int i;

  /* put tag 'name' into hash */
  if (theEntry->name != NULL) {
    sv = newSVpv( theEntry->name, 0 );
    if ( hv_stores( hv, "name", sv ) == NULL )
      warn("tagEntry_to_HV: failed to store name elem");
  }

  /* put tag 'file' into hash */
  if (theEntry->file != NULL) {
    sv = newSVpv( theEntry->file, 0 );
    if ( hv_stores( hv, "file", sv ) == NULL )
      warn("tagEntry_to_HV: failed to store file elem");
  }

  /* put tag 'addressPattern' into hash */
  if (theEntry->address.pattern != NULL) {
    sv = newSVpv( theEntry->address.pattern, 0 );
    if ( hv_stores( hv, "addressPattern", sv ) == NULL )
      warn("tagEntry_to_HV: failed to store address/pattern elem");
  }

  /* put tag 'addressLineNumber' into hash */
  if (theEntry->address.lineNumber != 0) {
    sv = newSViv( theEntry->address.lineNumber );
    if ( hv_stores( hv, "addressLineNumber", sv ) == NULL )
      warn("tagEntry_to_HV: failed to store lineNumber elem");
  }

  /* put tag 'kind' into hash */
  if (theEntry->kind != NULL) {
    sv = newSVpv( theEntry->kind, 0 );
    if ( hv_stores( hv, "kind", sv ) == NULL )
      warn("tagEntry_to_HV: failed to store kind elem");
  }

  /* put tag 'fileScope' into hash */
  sv = newSViv( theEntry->fileScope );
  if ( hv_stores( hv, "fileScope", sv ) == NULL )
    warn("tagEntry_to_HV: failed to store filescope elem");

  /* create 'extension' sub-hash */
  extHash = (HV*)sv_2mortal((SV*)newHV());
  if ( hv_stores( hv, "extension", newRV((SV*)extHash) ) == NULL )
    warn("tagEntry_to_HV: failed to store extension elem");

  for (i = 0; i < theEntry->fields.count; ++i) {
    if (theEntry->fields.list[i].key != NULL
        && theEntry->fields.list[i].value != NULL)
    {
      sv = newSVpv( theEntry->fields.list[i].value, 0 );
      if ( hv_store( extHash, theEntry->fields.list[i].key, strlen(theEntry->fields.list[i].key), sv, 0 ) == NULL )
        warn("tagEntry_to_HV: failed to store kind elem");
    }
  }
  

  return hv;
}

