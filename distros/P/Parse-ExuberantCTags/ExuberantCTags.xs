#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "readtags.h"
#include "tagEntry_to_HV.h"

typedef struct {
  tagFile* file;
  tagFileInfo* fileInfo;
  tagEntry* entryBuffer;
} myTagFile;



/*tagResult
tagsSetSortType(file, type)
  tagFile *  file
  sortType  type
*/

MODULE = Parse::ExuberantCTags    PACKAGE = Parse::ExuberantCTags
PROTOTYPES: DISABLE

myTagFile*
new(CLASS, path)
    char* CLASS
    char* path
  PREINIT:
    tagFile* theFile;
    tagFileInfo* theInfo;
  CODE:
    theInfo = (tagFileInfo*)safemalloc( sizeof(tagFileInfo) );
    if( theInfo == NULL ){
      warn("unable to malloc tagFileInfo");
      XSRETURN_UNDEF;
    }

    theFile = tagsOpen(path, theInfo);
    if (theFile == NULL) {
      safefree(theInfo);
      XSRETURN_UNDEF;
    }

    if (theInfo->status.opened == 0) {
      safefree(theFile);
      safefree(theInfo);
      XSRETURN_UNDEF;
    }

    RETVAL = (myTagFile*)safemalloc( sizeof(myTagFile) );
    if( RETVAL == NULL ){
      warn("unable to malloc myTagFile");
      tagsClose(theFile);
      safefree(theInfo);
      XSRETURN_UNDEF;
    }

    RETVAL->entryBuffer = (tagEntry*)safemalloc( sizeof(tagEntry) );
    if( RETVAL == NULL ){
      warn("unable to malloc tagEntry");
      tagsClose(theFile);
      safefree(theInfo);
      safefree(RETVAL);
      XSRETURN_UNDEF;
    }
    RETVAL->file = theFile;
    RETVAL->fileInfo = theInfo;
  OUTPUT:
    RETVAL


void
DESTROY(self)
    myTagFile* self
  CODE:
    if (self->file != NULL)
      tagsClose(self->file);
    safefree(self->fileInfo);
    safefree(self->entryBuffer);
    safefree(self);


SV*
firstTag(self)
    myTagFile* self
  PREINIT:
    HV* result;
  CODE:
    if (self->file == NULL)
      XSRETURN_UNDEF;
    if (tagsFirst(self->file, self->entryBuffer) == TagFailure)
      XSRETURN_UNDEF;
    result = tagEntry_to_HV(self->entryBuffer);
    RETVAL = newRV_noinc((SV*) result);
  OUTPUT:
    RETVAL


SV*
nextTag(self)
    myTagFile* self
  PREINIT:
    HV* result;
  CODE:
    if (self->file == NULL)
      XSRETURN_UNDEF;
    if (tagsNext(self->file, self->entryBuffer) == TagFailure)
      XSRETURN_UNDEF;
    result = tagEntry_to_HV(self->entryBuffer);
    RETVAL = newRV_noinc((SV*) result);
  OUTPUT:
    RETVAL


SV*
findTag(self, name, ...)
    myTagFile* self
    char* name
  PREINIT:
    int options = TAG_FULLMATCH | TAG_OBSERVECASE;
    unsigned int i;
    SV* sv;
    HV* result;
  CODE:
    if ( (items % 2) == 1 )
      croak("Syntax: ->findTag('tagname', [option => value, ...])");
    
    if (self->file == NULL)
      XSRETURN_UNDEF;

    if (items > 2) {
      for (i = 2; i < (unsigned int)items; i += 2) {
        sv = ST(i);
        if ( SvOK(sv) ) {
          if ( strEQ(SvPV_nolen(sv), "partial") && SvTRUE(ST(i+1)) )
            options |= TAG_PARTIALMATCH;
          else if ( strEQ(SvPV_nolen(sv), "ignore_case") && SvTRUE(ST(i+1)) )
            options |= TAG_IGNORECASE;
        }
      }
    } /* end if optional args */
    if (tagsFind(self->file, self->entryBuffer, name, options) == TagFailure)
      XSRETURN_UNDEF;
    result = tagEntry_to_HV(self->entryBuffer);
    RETVAL = newRV_noinc((SV*) result);
  OUTPUT:
    RETVAL



SV*
findNextTag(self)
    myTagFile* self
  PREINIT:
    HV* result;
  CODE:
    if (self->file == NULL)
      XSRETURN_UNDEF;
    if (tagsFindNext(self->file, self->entryBuffer) == TagFailure)
      XSRETURN_UNDEF;
    result = tagEntry_to_HV(self->entryBuffer);
    RETVAL = newRV_noinc((SV*) result);
  OUTPUT:
    RETVAL

 
