//
// Copyright (C) 1997 Ken MacLeod
// See the file COPYING for distribution terms.
//
// $Id: SPGroveNew.cc,v 1.1.1.1 1998/01/17 23:47:37 ken Exp $
//

// The next two lines are only to ensure bool gets defined appropriately.
#include <stdio.h>
#include <stdlib.h>
#include "config.h"
#include "Boolean.h"

#include "ParserEventGeneratorKit.h"

extern "C" {
#define explicit nexplicit
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef explicit

SV *sp_grove_new (char *type, char *);
}

typedef unsigned char spgrove_char;
#define GROW_SIZE (1000)

#undef assert
#include <assert.h>

class SPGrove : public SGMLApplication {
public:
  SPGrove(char *type, SV **grove);
  ~SPGrove();
  void startElement(const StartElementEvent &event);
  void endElement(const EndElementEvent &);
  void data(const DataEvent &event);
  void sdata(const SdataEvent &event);
  void pi(const PiEvent &event);
  void externalDataEntityRef(const ExternalDataEntityRefEvent &event);
  void subdocEntityRef(const SubdocEntityRefEvent &);
  void nonSgmlChar(const NonSgmlCharEvent &);
  void error(const ErrorEvent &event);
private:
  AV *grove_;			// grove element, dereferenced
  AV *errors_;			// errors array, dereferenced
  AV *contents_;		// current element's contents
  AV *stack_;			// element stack
  HV *sdata_stash_;		// SData stash for blessing
  HV *element_stash_;		// Element stash for blessing
  HV *pi_stash_;		// PI stash for blessing
  HV *entity_stash_;		// Entity stash for blessing
  HV *extentity_stash_;		// ExtEntity stash for blessing
  HV *subdocentity_stash_;	// SubDocEntity stash for blessing
  HV *notation_stash_;		// Notation stash for blessing
  HV *entities_;		// entities defined in this document
  HV *notations_;		// notations defined in this document
  spgrove_char *ptr_;		// temporary 8bit string copy area
  size_t length_;		// points to '\0'
  size_t alloc_;		// must be at least length_ + 1
  void store_external_id (HV *, const SGMLApplication::ExternalId *);
  SV *entity (const SGMLApplication::Entity *);
  SV *notation (const SGMLApplication::Notation *);
  char *as_string (SGMLApplication::CharString);
  void append (SGMLApplication::CharString);
  void flushData() {		// create scalar from accumulated data
    if (length_ > 0) {
      av_push(contents_, newSVpv((char *)ptr_, length_));
      length_ = 0;
    }
  };
};

//
// This is the C-callable interface to the grove builder
//
SV *
sp_grove_new (char *type, char * file_name)
{
  SV *grove;

  ParserEventGeneratorKit parserKit;
  EventGenerator *egp = parserKit.makeEventGenerator(1, &file_name);
  SPGrove app(type, &grove);
  egp->inhibitMessages (1);
  unsigned nErrors = egp->run(app);
  delete egp;

  return (grove);
}

SPGrove::SPGrove(char *type, SV **grove_ref)
{
  grove_ = newAV();

  // create arrays and store in new grove
  errors_ = newAV();
  av_push(grove_, newRV_noinc ((SV*)errors_));
  entities_ = newHV();
  av_push(grove_, newRV_noinc((SV*)entities_));
  notations_ = newHV();
  av_push(grove_, newRV_noinc((SV*)notations_));
  contents_ = newAV();
  av_push(grove_, newRV_noinc((SV*)contents_));

  // save a blessed reference for the caller
  *grove_ref = newRV_noinc((SV*)grove_);
  HV *type_stash = gv_stashpv("SGML::Grove", 1);
  sv_bless (*grove_ref, type_stash);

  sdata_stash_ = gv_stashpv("SGML::SData", 1);
  element_stash_ = gv_stashpv("SGML::Element", 1);
  pi_stash_ = gv_stashpv("SGML::PI", 1);
  entity_stash_ = gv_stashpv("SGML::Entity", 1);
  extentity_stash_ = gv_stashpv("SGML::ExtEntity", 1);
  subdocentity_stash_ = gv_stashpv("SGML::SubDocEntity", 1);
  notation_stash_ = gv_stashpv("SGML::Notation", 1);

  stack_ = newAV();

  ptr_ = new spgrove_char[GROW_SIZE];
  length_ = 0;
  alloc_ = GROW_SIZE;
}

SPGrove::~SPGrove()
{
  av_undef(stack_);
  delete [] ptr_;
}

//
// `startElement' is called at the opening of each element in the instance.
// `startElement' creates a new `element' with empty contents, the
// element's name, and any attributes.  See `SGML::Element'.
//
void
SPGrove::startElement(const StartElementEvent &event)
{
  flushData();
  SV *element[3];

  // Create empty array for contents
  AV *contents = newAV();
  element[0] = newRV_noinc((SV*)contents);

  // Name
  element[1] = newSVpv(as_string(event.gi), event.gi.len);

  // Attributes
  HV *attributes = (HV*)&sv_undef;
  size_t nAttributes = event.nAttributes;

  if (nAttributes > 0) {
    // XXX we can optimize by using a C array and av_make instead of push
    const Attribute *att_ptr = event.attributes;

    while (nAttributes-- > 0) {
      switch (att_ptr->type) {
      case Attribute::implied:
	break;			// ignored
      case Attribute::tokenized:
	{
	  if (attributes == (HV*)&sv_undef) {
	    attributes = newHV();
	  }

	  if (att_ptr->nEntities != 0) {
	    AV *att_data = newAV();
	    size_t nEntities = att_ptr->nEntities;
	    const SGMLApplication::Entity *entities = att_ptr->entities;

	    while (nEntities-- > 0) {
	      SV *entity_ref = entity (entities);
	      SvREFCNT_inc (entity_ref);
	      av_push (att_data, entity_ref);
	      entities ++;
	    }
	    hv_store (attributes,
		      as_string(att_ptr->name), att_ptr->name.len,
		      newRV_noinc((SV*)att_data), 0);
	  } else if (att_ptr->notation.name.len > 0) {
	    SV *notation_ref = notation(&att_ptr->notation);
	    SvREFCNT_inc (notation_ref);
	    hv_store (attributes,
		      as_string(att_ptr->name), att_ptr->name.len,
		      notation_ref, 0);
	  } else {
	    SV *token = newSVpv(as_string(att_ptr->tokens), att_ptr->tokens.len);
	    hv_store (attributes,
		      as_string(att_ptr->name), att_ptr->name.len,
		      token, 0);
	  }
	}
        break;
      case Attribute::cdata:
	{
	  AV *att_data = newAV();
	  size_t nCdataChunks = att_ptr->nCdataChunks;
	  const SGMLApplication::Attribute::CdataChunk *cdataChunk
	    = att_ptr->cdataChunks;

	  if (attributes == (HV*)&sv_undef) {
	    attributes = newHV();
	  }

	  // XXX we can optimize by using a C array and av_make instead of push
	  while (nCdataChunks-- > 0) {
	    SV *data = NULL;

	    if (cdataChunk->isSdata) {
	      SV *sdata_a[2];
	      sdata_a[0] = newSVpv(as_string(cdataChunk->data),
				   cdataChunk->data.len);
	      sdata_a[1] = newSVpv(as_string(cdataChunk->entityName),
				   cdataChunk->entityName.len);
	      AV *sdata = av_make(2, &sdata_a[0]);
	      SvREFCNT_dec (sdata_a[0]);
	      SvREFCNT_dec (sdata_a[1]);
	      data = newRV_noinc((SV*)sdata);
	      sv_bless (data, sdata_stash_);
	    } else if (!cdataChunk->isNonSgml) {
	      data = newSVpv(as_string(cdataChunk->data), cdataChunk->data.len);
	    } else {
	      // XXX we need to do better than this
	      fprintf (stderr, "SPGroveNew: isNonSGML in cdata attribute\n");
	    }
	    if (data != NULL) {
	      av_push (att_data, data);
	    }
	    cdataChunk ++;
	  }

	  hv_store (attributes,
		    as_string(att_ptr->name), att_ptr->name.len,
		    newRV_noinc((SV*)att_data), 0);
	}
	break;
      default: {
	  // XXX this is a CANT_HAPPEN
	  av_push(errors_, newSVpv("SPGroveNew: invalid attribute type", 0));
	  break;
	}
      }
      att_ptr ++;
    }
  }

  // finish off adding the attributes to the element
  if (attributes == (HV*)&sv_undef) {
    element[2] = &sv_undef;
  } else {
    element[2] = newRV_noinc((SV*)attributes);
  }

  // create a reference so we can bless it and pass it around
  SV *element_ref = newRV_noinc((SV*)av_make(3, &element[0]));
  SvREFCNT_dec (element[0]);
  SvREFCNT_dec (element[1]);
  if (element[2] != &sv_undef) {
    SvREFCNT_dec (element[2]);
  }
  sv_bless (element_ref, element_stash_);

  av_push (contents_, element_ref);
  av_push (stack_, (SV*)contents_);

  // cache the contents array
  contents_ = contents;
}

//
// `endElement' is called at the closing of each element in the
// instance.  `endElement' pulls the parent element off the stack and
// copies it's contents to the `contents_' cache
//
void
SPGrove::endElement(const EndElementEvent &)
{
  flushData();

  contents_ = (AV*)av_pop(stack_);
}

//
// `data' is called when ordinary instance data comes across
//
// XXX we could provide an option for concatenation
void
SPGrove::data(const DataEvent &event)
{
  append (event.data);
}

//
// `sdata' is called when sdata comes through
// sdata is blessed into the SGML::SData class
//
void
SPGrove::sdata(const SdataEvent &event)
{
  flushData();
  SV *sdata_a[2];

  sdata_a[0] = newSVpv(as_string(event.text), event.text.len);
  sdata_a[1] = newSVpv(as_string(event.entityName), event.entityName.len);
  AV *sdata = av_make(2, &sdata_a[0]);
  SvREFCNT_dec (sdata_a[0]);
  SvREFCNT_dec (sdata_a[1]);
  SV *sdata_ref = newRV_noinc((SV*)sdata);

  sv_bless (sdata_ref, sdata_stash_);
  av_push(contents_, sdata_ref);
}

//
// `pi' is called for process instructions
// processing instructions are blessed into SGML::PI
//
void
SPGrove::pi(const PiEvent &event)
{
  flushData();

  SV *pi = newSVpv(as_string(event.data), event.data.len);
  SV *pi_ref = newRV_noinc(pi);

  sv_bless (pi_ref, pi_stash_);
  av_push(contents_, pi_ref);
}

//
// `externalDataEntity'
//
void
SPGrove::externalDataEntityRef(const ExternalDataEntityRefEvent &event)
{
  flushData();

  SV *entity_ref = entity(&event.entity);
  SvREFCNT_inc (entity_ref);
  av_push(contents_, entity_ref);
}

//
// `subdocEntityRef'
//
void SPGrove::subdocEntityRef(const SubdocEntityRefEvent &event)
{
  flushData();

  SV *entity_ref = entity(&event.entity);
  SvREFCNT_inc (entity_ref);
  av_push(contents_, entity_ref);
}

//
// `nonSgmlChar'
//
void SPGrove::nonSgmlChar(const NonSgmlCharEvent &event)
{
  flushData();

  fprintf (stderr, "SPGroveNew: nonSgmlChar not handled\n");
}

//
// `error' is called when an error is encountered during the parse.
//
void SPGrove::error(const ErrorEvent &event) {
  av_push(errors_, newSVpv(as_string(event.message), event.message.len));
}

//
// `entity' returns an entity definition, creating it if necessary
//
SV *
SPGrove::entity (const SGMLApplication::Entity *entity)
{
  char *name = as_string(entity->name);
  SV **entity_def = hv_fetch(entities_, name, entity->name.len, 0);
  if (!entity_def) {
    HV *new_entity = newHV();
    hv_store(new_entity, "name", 4, newSVpv(name, entity->name.len), 0);

    char *type = 0;
    HV *stash;
    switch (entity->dataType) {
    case Entity::cdata:  type = "CDATA"; stash = extentity_stash_; break;
    case Entity::sdata:  type = "SDATA"; stash = extentity_stash_; break;
    case Entity::ndata:  type = "NDATA"; stash = extentity_stash_; break;
    case Entity::subdoc: stash = subdocentity_stash_; break;
    default: {
        av_push(errors_, newSVpv("SPGroveNew: data type not handled", 0));
      }
    }
    if (type) {
      hv_store(new_entity, "type", 4, newSVpv(type, 5), 0);
    }
    if (entity->isInternal) {
      hv_store(new_entity, "data", 4,
	       newSVpv(as_string(entity->text), entity->text.len), 0);
      stash = entity_stash_;
    } else {
      store_external_id (new_entity, &entity->externalId);
      // XXX attributes

      if (entity->notation.name.len > 0) {
	SV *notation_ref = notation(&entity->notation);
	SvREFCNT_inc (notation_ref);
	hv_store(new_entity, "notation", 8,
		 notation_ref, 0);
      }
    }

    SV *entity_ref = newRV_noinc((SV*)new_entity);
    sv_bless (entity_ref, stash);
    name = as_string(entity->name); // again since it was overwritten
    entity_def = hv_store (entities_, name, entity->name.len, entity_ref, 0);
  }

  return (*entity_def);
}

//
// `notation' returns a notation definition, creating it if necessary
//
SV *
SPGrove::notation (const SGMLApplication::Notation *notation)
{
  char *name = as_string(notation->name);
  SV **notation_def = hv_fetch(notations_, name, notation->name.len, 0);
  if (!notation_def) {
    HV *new_notation = newHV();
    hv_store(new_notation, "name", 4, newSVpv(name, notation->name.len), 0);

    store_external_id (new_notation, &notation->externalId);

    SV *notation_ref = newRV_noinc((SV*)new_notation);
    sv_bless (notation_ref, notation_stash_);
    name = as_string(notation->name); // again since it was overwritten
    notation_def = hv_store (notations_, name, notation->name.len, notation_ref, 0);
  }

  return (*notation_def);
}

//
// `store_external_id' stores external ID values in `hash'
//
void
SPGrove::store_external_id (HV *hash,
			    const SGMLApplication::ExternalId *externalId)
{
  if (externalId->haveSystemId) {
    hv_store(hash, "system_id", 9,
	     newSVpv(as_string(externalId->systemId),
		     externalId->systemId.len), 0);
  }
  if (externalId->havePublicId) {
    hv_store(hash, "public_id", 9,
	     newSVpv(as_string(externalId->publicId),
		     externalId->publicId.len), 0);
  }
  if (externalId->haveGeneratedSystemId) {
    hv_store(hash, "generated_id", 12,
	     newSVpv(as_string(externalId->generatedSystemId),
		     externalId->generatedSystemId.len), 0);
  }
}

//
// `as_string' uses the temporary string area to convert a CharString
// to a 8bit string
//
// this clears (zero lengths) the temporary string buffer
//
char *
SPGrove::as_string (SGMLApplication::CharString text)
{
  size_t str_len = text.len + 1;
  const SGMLApplication::Char *uptr = text.ptr;

  if (alloc_ < str_len) {
    delete [] ptr_;
    ptr_ = new spgrove_char[str_len];
    alloc_ = str_len;
  }

  spgrove_char *cptr = ptr_;

  while (--str_len) {
    if ((*uptr & 0xff00) != 0) {
      av_push(errors_, newSVpv("SPGroveNew: character more than 8bits", 0));
    }
    *cptr++ = (spgrove_char) *uptr++;
  }
  *cptr = '\0';

  length_ = 0;

  return ((char *)ptr_);
}

void
SPGrove::append (SGMLApplication::CharString text)
{
  size_t str_len = text.len + 1;
  size_t new_len = length_ + text.len;
  const SGMLApplication::Char *uptr = text.ptr;

  if (alloc_ < new_len + 1) {
    spgrove_char *s = new spgrove_char[new_len + GROW_SIZE];
    memcpy (s, ptr_, length_);
    delete [] ptr_;
    ptr_ = s;
    alloc_ = new_len + GROW_SIZE;
  }

  spgrove_char *cptr = &ptr_[length_];
  length_ = new_len;

  while (--str_len) {
    if ((*uptr & 0xff00) != 0) {
      av_push(errors_, newSVpv("SPGroveNew: character more than 8bits", 0));
    }
    *cptr++ = (spgrove_char) *uptr++;
  }
  *cptr = '\0';
}
