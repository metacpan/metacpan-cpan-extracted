#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <ztxt.h>

/*
TODO: MAX_BOOKMARK_LENGTH
	Check compression_type, process_method, @ set time rather than
	  @ get_output() time
	Check bookmark & annotation offsets in get_output()
*/
typedef struct perl_ztxt {
	ztxt*	db;
} perl_ztxt_t;


static ztxt * extract_db (ztxt_sv)
	SV *ztxt_sv;
{
	HV *hash;
	SV **db;

	if (!SvOK(ztxt_sv) || !SvROK(ztxt_sv))
		croak("Invalid Database");

	hash = (HV *)SvRV(ztxt_sv);
	db = hv_fetch(hash, "db", 2,0);
	if (!db || !SvOK(*db))
		croak("Invalid Database");

	/* sv_dump(*db);
	sv_dump(SvRV(*db)); */
	return  (ztxt *)SvPVX(*db);
}

static HV * imp_hash (ztxt_sv)
	SV *ztxt_sv;
{
	HV *hash;
	SV **db;

	if (!SvOK(ztxt_sv) || !SvROK(ztxt_sv))
		croak("Invalid Database");

	hash = (HV *)SvRV(ztxt_sv);
	return hash;
}

MODULE = Palm::Ztxt		PACKAGE = Palm::Ztxt
PROTOTYPES: ENABLE


int
init(ztxt_sv)
	SV *ztxt_sv;
	PREINIT:
		SV *sv;
		ztxt *db;
		HV *hash;
	CODE:
		if (!SvOK(ztxt_sv) || !SvROK(ztxt_sv))
			croak("Invalid Database");

		db = ztxt_init();
		sv = newSV(0);
		SvUPGRADE(sv, SVt_PV);
		SvPVX(sv) = (char *)db;
		SvPOK_on(sv);
		SvREADONLY_on(sv);

		hash = (HV *)SvRV(ztxt_sv);
		hv_store(hash, "db", 2, sv,0);

		ztxt_set_data(db,"  ",2); /*If data < 2 segfault! on process*/
		ztxt_set_title(db,"");
		RETVAL = (int)db;
	OUTPUT:
		RETVAL


void
check_db(self, db_loc)
	SV *self;
	unsigned int db_loc;
	CODE:
		ztxt *db;
		db = extract_db(self);
		if (((unsigned int)db) != db_loc)
			croak("Db locs do not match %x, %x", db, db_loc);


void
set_title(ztxt_sv, title)
	SV *ztxt_sv;
	char *title;
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_sv);
		if (strlen(title) > 32)
			croak("Title Exceeds 32 chars");
		ztxt_set_title(db, title);

char *
get_title(ztxt_db)
	SV *ztxt_db;
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_db);
		RETVAL = (db)->dbHeader->name;
	OUTPUT:
		RETVAL



void
set_data(ztxt_sv, data_sv)
	SV *ztxt_sv;
	SV *data_sv;
	PREINIT:
		ztxt *db;
		char *data;
		STRLEN len;
		SV *text_sv;
	CODE:
		db = extract_db(ztxt_sv);
		if (SvPOK(data_sv))
			data = SvPV(data_sv, len);
		else if ( SvROK(data_sv) && (text_sv = SvRV(data_sv)) && 
		          SvOK(text_sv) && SvPOK(text_sv) )
			data = SvPV(text_sv, len);
		else
			croak("Invalid zTXT");

		if (len <2)
			croak("Data must be at least 2 characters long.");

		ztxt_set_data(db, data, (long)len);


SV *
get_output (ztxt_sv)
	SV * ztxt_sv;
	PREINIT:
		ztxt *db;
		char *output;
		long output_len;
		HV *hash;
		SV **entry;
		unsigned int method = 2; /* No processing */
		unsigned int line_len = 0; /* Calculate line length */
	CODE:
		db = extract_db(ztxt_sv);
		hash = imp_hash(ztxt_sv); /* Hash must be good */
		entry = hv_fetch(hash, "compression_type", 
			    sizeof("compression_type")-1, 0);
		if (entry && SvIOK(*entry))
				ztxt_set_compressiontype(db, SvIV(*entry));

		entry = hv_fetch(hash, "process_method", 0, 0);

		if (entry && SvIOK(*entry)) method = SvIV(*entry);
			if (method != 0 && method !=1 && method != 2)
				croak("Unknown process method");

		entry = hv_fetch(hash,"line_length", sizeof("line_length"),0);
		if (entry && SvIOK(*entry))
			line_len = SvIV(*entry);

		entry = hv_fetch(hash,"wbits", sizeof("wbits"),0);
		/*TODO Check n<wbits<16 */
		if (entry && SvIOK(*entry))
			ztxt_set_wbits(db, SvIV(*entry));

		ztxt_process(db, method, line_len); /*FIXME */

		ztxt_generate_db(db);
		output = ztxt_get_output(db);
		output_len = ztxt_get_outputsize((db));
		RETVAL = newSVpvn(output, output_len);
	OUTPUT:
		RETVAL


SV *
get_input(ztxt_sv)
	SV *ztxt_sv;
	PREINIT:
		ztxt *db;
		char *input;
		long input_len;
	CODE:
		db=extract_db(ztxt_sv);
		input = ztxt_get_input(db);
		input_len = ztxt_get_inputsize(db);
		RETVAL =  newSVpv(input, input_len);
	OUTPUT:
		RETVAL


int
disect(ztxt_sv, data_sv)
	SV *ztxt_sv;
	SV * data_sv;
	PREINIT:
		ztxt *db;
		char *zbook;
		STRLEN len;
		HV *hash;
		SV *zbook_sv;
	CODE:
		db = extract_db(ztxt_sv);
		if (!SvOK(data_sv))
			croak("Invalid zTXT");


		if (SvPOK(data_sv))
			zbook = SvPV(data_sv, len);

		else if ( SvROK(data_sv) && (zbook_sv = SvRV(data_sv)) && 
		          SvOK(zbook_sv) && SvPOK(zbook_sv) )
			zbook = SvPV(zbook_sv, len);
		else
			croak("Invalid zTXT");

		ztxt_set_output(db, zbook, len);

		if (!ztxt_disect(db))
			croak("Could not disect ztxt");

		hash = imp_hash(ztxt_sv);
		hv_store(hash, "method", 0 , newSViv(2),0);
		hv_store(hash,"line_length",0, newSViv(0),0);
		hv_store(hash,"wbits", 0, newSViv(db->wbits),0);

		ztxt_set_output(db, NULL, 0);

		RETVAL=1;

	OUTPUT:
		RETVAL

void
set_type(ztxt_sv, type)
	SV *ztxt_sv;
	long type;
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_sv);
		ztxt_set_type(db, type);

long
get_type(ztxt_sv)
	SV *ztxt_sv;
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_sv);
		RETVAL = ntohl(db->dbHeader->type);
	OUTPUT:
		RETVAL


void
set_attribs(ztxt_sv, attribs)
	SV *ztxt_sv;
	short attribs;
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_sv);
		ztxt_set_attribs(db, attribs);

long
get_attribs(ztxt_sv)
	SV *ztxt_sv;
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_sv);
		RETVAL = ntohl(db->dbHeader->attributes);
	OUTPUT:
		RETVAL


void
set_creator(ztxt_sv, creator)
	SV *ztxt_sv;
	int creator;
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_sv);
		ztxt_set_creator(db, creator);

long
get_creator(ztxt_sv)
	SV *ztxt_sv;
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_sv);
		RETVAL = ntohl(db->dbHeader->creator);
	OUTPUT:
		RETVAL



SV *
get_bookmarks(ztxt_sv)
	SV *ztxt_sv;
	PREINIT:
		ztxt *db;
		bmrk_node *list;
		bmrk_node *node;
		SV *title;
		SV *offset;
		HV *bookmark;
		AV *array;
	CODE:
		db = extract_db(ztxt_sv);
		array = newAV();

		list = ztxt_get_bookmarks(db);

		if (list) {
		    for (node = list; node; node = node->next) {
			bookmark = newHV();
			title  = newSVpv(node->title, 0);
			offset = newSViv((IV)node->offset);
			hv_store(bookmark, "title",sizeof("title")-1, title, 0);
			hv_store(bookmark,"offset",sizeof("offset")-1,offset,0);
			av_push(array, newRV_noinc((SV *)bookmark));
		    }
		}
		RETVAL =  sv_2mortal(newRV_noinc((SV *)array));

	OUTPUT:
		RETVAL


void
add_bookmark(ztxt_sv, title_sv, offset)
	SV *ztxt_sv;
	SV *title_sv;
	unsigned long offset;
	PREINIT:
		ztxt *db;
		char *title;
		STRLEN len;
	CODE:
		db = extract_db(ztxt_sv);
		/*TODO: magick */
		if SvOK(title_sv) {
			title = SvPV(title_sv, len);
			if (len >20)
				croak("Title length exceeds 20 characters");
			ztxt_add_bookmark(db, title, offset);
		} else {
			croak("Invalid Title");

		}


int
delete_bookmark(ztxt_sv, title, offset)
	SV *ztxt_sv;
	char *title;
	long offset;
	PREINIT:
		ztxt *db;
		bmrk_node *list;
		bmrk_node *node;
		bmrk_node *prev;
	CODE:
		db = extract_db(ztxt_sv);
		list = ztxt_get_bookmarks(db);

		RETVAL = 0;
		if (list) {
			for (prev=node=list; node; prev=node,node=node->next) {
				if (strcmp(node->title, title) && 
				    node->offset == offset)
				{
					if (prev == node)
						db->bookmarks = node->next;
					else
						prev->next = node->next;

					if (node);
						free(node);
					RETVAL = 1;
					break;
				}
			}
		}
	OUTPUT:
		RETVAL



SV *
get_annotations(ztxt_sv)
	SV *ztxt_sv;
	PREINIT:
		ztxt *db;
		anno_node *list;
		anno_node *node;
		SV *title;
		SV *offset;
		SV *anno_txt;
		HV *anno;
		AV *array;
	CODE:
		db = extract_db(ztxt_sv);
		array = newAV();

		list = ztxt_get_annotations(db);

		if (list) {
		    for (node = list; node; node = node->next) {
			anno = newHV();
			title = newSVpv(node->title, 0);
			offset = newSViv((IV)node->offset);
			anno_txt = newSVpv(node->anno_text,0);
			hv_store(anno, "title", sizeof("title")-1, title, 0);
			hv_store(anno, "offset", sizeof("offset")-1,offset,0);
			hv_store(anno, "annotation", 
				sizeof("annotation")-1,anno_txt,0);

			av_push(array,newRV_noinc((SV *)anno));
		    }
		}

		RETVAL =  sv_2mortal(newRV((SV *)array));
	OUTPUT:
		RETVAL



int
delete_annotation(ztxt_sv, title, offset, annotation)
	SV *ztxt_sv;
	char *title;
	long offset;
	char *annotation;
	PREINIT:
		ztxt *db;
		anno_node *list;
		anno_node *node;
		anno_node *prev;
	CODE:
		db = extract_db(ztxt_sv);
		list = ztxt_get_annotations(db);

		RETVAL = 0;
		if (list) {
			for (prev=node=list; node; prev=node,node=node->next) {
				if (!strcmp(node->title, title) &&   
				    node->offset == offset &&
			    	    !strcmp(node->anno_text, annotation))
				{
					if (prev == node)
						db->annotations=node->next;
					else
						prev->next = node->next;

					if (node)
						free(node);
					RETVAL = 1;
					break;
				}
			}
		}
	OUTPUT:
		RETVAL


void
add_annotation(ztxt_sv, title_sv, offset, annotation)
	SV *ztxt_sv;
	SV *title_sv;
	long offset;
	char *annotation;
	PREINIT:
		ztxt *db;
		char *title;
		STRLEN len;
	CODE:
		db = extract_db(ztxt_sv);
		if SvOK(title_sv) {
			title = SvPV(title_sv, len);
			if (len >20)
				croak("Title length exceeds 20 characters");
			if (strlen(annotation) > 4095) /* should get form sv*/
				croak("Annotation Text exceeds 4095 chars");
			ztxt_add_annotation(db, title, offset, annotation);
		} else {
			croak("Invalid Annotation Title");

		}


void
DESTROY(ztxt_sv)
	SV *ztxt_sv
	PREINIT:
		ztxt *db;
	CODE:
		db = extract_db(ztxt_sv);
		ztxt_free(db);



