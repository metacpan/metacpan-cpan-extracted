/* PSPP - computes sample statistics.
   Copyright (C) 2007, 2008, 2009 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
   02110-1301, USA. */


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <config.h>

#include "ppport.h"

#include "minmax.h"
#include <libpspp/message.h>
#include <libpspp/version.h>
#include <gl/xalloc.h>
#include <data/dictionary.h>
#include <data/case.h>
#include <data/casereader.h>
#include <data/variable.h>
#include <data/attributes.h>
#include <data/file-handle-def.h>
#include <data/sys-file-writer.h>
#include <data/sys-file-reader.h>
#include <data/value.h>
#include <data/vardict.h>
#include <data/value-labels.h>
#include <data/format.h>
#include <data/data-in.h>
#include <data/data-out.h>
#include <string.h>

typedef struct fmt_spec input_format ;
typedef struct fmt_spec output_format ;


/*  A thin wrapper around sfm_writer */
struct sysfile_info
{
  bool opened;

  /* A pointer to the writer. The writer is owned by the struct */
  struct casewriter *writer;

  /* A pointer to the dictionary. Owned externally */
  const struct dictionary *dict;

  /* The scalar containing the dictionary */
  SV *dict_sv;
};


/*  A thin wrapper around sfm_reader */
struct sysreader_info
{
  struct sfm_read_info opts;

  /* A pointer to the reader. The reader is owned by the struct */
  struct casereader *reader;

  /* A pointer to the dictionary. */
  struct dictionary *dict;
};



/*  A message handler which writes messages to PSPP::errstr */
static void
message_handler (const struct msg *m)
{
 SV *errstr = get_sv("PSPP::errstr", TRUE);
 sv_setpv (errstr, m->text);
}

static int
sysfile_close (struct sysfile_info *sfi)
{
  int retval ;
  if ( ! sfi->opened )
    return 0;

  retval = casewriter_destroy (sfi->writer);
  if (retval > 0 )
    sfi->opened = false;

  return retval;
}

static void
scalar_to_value (union value *val, SV *scalar, const struct variable *var)
{
  if ( var_is_numeric (var))
    {
	if ( SvNOK (scalar) || SvIOK (scalar) )
	   val->f = SvNV (scalar);
	else
	   val->f = SYSMIS;
    }
  else
    {
	STRLEN len;
	const char *p = SvPV (scalar, len);
	int width = var_get_width (var);
	value_set_missing (val, width);
	memcpy (value_str_rw (val, width), p, len);
    }
}


static SV *
value_to_scalar (const union value *val, const struct variable *var)
{
  if ( var_is_numeric (var))
    {
      if ( var_is_value_missing (var, val, MV_SYSTEM))
	return newSVpvn ("", 0);

      return newSVnv (val->f);
    }
  else
    {
      int width = var_get_width (var);
      return newSVpvn (value_str (val, width), width);
    }
}


static void
var_set_input_format (struct variable *v, input_format ip_fmt)
{
  struct fmt_spec *if_copy = malloc (sizeof (*if_copy));
  memcpy (if_copy, &ip_fmt, sizeof (ip_fmt));
  var_attach_aux (v, if_copy, var_dtor_free);
}

static void
make_value_from_scalar (union value *uv, SV *val, const struct variable *var)
{
 value_init (uv, var_get_width (var));
 scalar_to_value (uv, val, var);
}


MODULE = PSPP

MODULE = PSPP		PACKAGE = PSPP

void
onBoot (ver)
 const char *ver
CODE:
 assert (0 == strcmp (ver, bare_version));
 i18n_init ();
 msg_init (NULL, message_handler);
 settings_init (0, 0);
 fh_init ();

SV *
format_value (val, var)
 SV *val
 struct variable *var
CODE:
 SV *ret;
 const struct fmt_spec *fmt = var_get_print_format (var);
 const struct dictionary *dict = var_get_vardict (var)->dict;
 union value uv;
 char *s;
 make_value_from_scalar (&uv, val, var);
 s = data_out (&uv, dict_get_encoding (dict), fmt);
 value_destroy (&uv, var_get_width (var));
 ret = newSVpv (s, fmt->w);
 free (s);
 RETVAL = ret;
 OUTPUT:
RETVAL


int
value_is_missing (val, var)
 SV *val
 struct variable *var
CODE:
 union value uv;
 int ret;
 make_value_from_scalar (&uv, val, var);
 ret = var_is_value_missing (var, &uv, MV_ANY);
 value_destroy (&uv, var_get_width (var));
 RETVAL = ret;
 OUTPUT:
RETVAL



MODULE = PSPP		PACKAGE = PSPP::Dict

struct dictionary *
pxs_dict_new()
CODE:
 RETVAL = dict_create ();
OUTPUT:
 RETVAL


void
DESTROY (dict)
 struct dictionary *dict
CODE:
 dict_destroy (dict);


int
get_var_cnt (dict)
 struct dictionary *dict
CODE:
 RETVAL = dict_get_var_cnt (dict);
OUTPUT:
RETVAL

void
set_label (dict, label)
 struct dictionary *dict
 char *label
CODE:
 dict_set_label (dict, label);

void
set_documents (dict, docs)
 struct dictionary *dict
 char *docs
CODE:
 dict_set_documents (dict, docs);


void
add_document (dict, doc)
 struct dictionary *dict
 char *doc
CODE:
 dict_add_document_line (dict, doc);


void
clear_documents (dict)
 struct dictionary *dict
CODE:
 dict_clear_documents (dict);


void
set_weight (dict, var)
 struct dictionary *dict
 struct variable *var
CODE:
 dict_set_weight (dict, var);


struct variable *
pxs_get_variable (dict, idx)
 struct dictionary *dict
 SV *idx
INIT:
 SV *errstr = get_sv("PSPP::errstr", TRUE);
 sv_setpv (errstr, "");
 if ( SvIV (idx) >= dict_get_var_cnt (dict))
  {
    sv_setpv (errstr, "The dictionary doesn't have that many variables.");
    XSRETURN_UNDEF;
  }
CODE:
 RETVAL = dict_get_var (dict, SvIV (idx));
 OUTPUT:
RETVAL


struct variable *
pxs_get_var_by_name (dict, name)
 struct dictionary *dict
 const char *name
INIT:
 SV *errstr = get_sv("PSPP::errstr", TRUE);
 sv_setpv (errstr, "");
CODE:
 struct variable *var = dict_lookup_var (dict, name);
 if ( ! var )
      sv_setpv (errstr, "No such variable.");
 RETVAL = var;
 OUTPUT:
RETVAL


MODULE = PSPP		PACKAGE = PSPP::Var


struct variable *
pxs_dict_create_var (dict, name, ip_fmt)
 struct dictionary * dict
 char *name
 input_format ip_fmt
INIT:
 SV *errstr = get_sv("PSPP::errstr", TRUE);
 sv_setpv (errstr, "");
 if ( ! var_is_plausible_name (name, false))
  {
    sv_setpv (errstr, "The variable name is not valid.");
    XSRETURN_UNDEF;
  }
CODE:
 struct fmt_spec op_fmt;

 struct variable *v;
 op_fmt = fmt_for_output_from_input (&ip_fmt);
 v = dict_create_var (dict, name,
	fmt_is_string (op_fmt.type) ? op_fmt.w : 0);
 if ( NULL == v )
  {
    sv_setpv (errstr, "The variable could not be created (probably already exists).");
    XSRETURN_UNDEF;
  }
 var_set_both_formats (v, &op_fmt);
 var_set_input_format (v, ip_fmt);
 RETVAL = v;
OUTPUT:
 RETVAL


int
set_missing_values (var, v1, ...)
 struct variable *var;
 SV *v1;
INIT:
 int i;
 union value val[3];

 if ( items > 4 )
  croak ("No more than 3 missing values are permitted");

 for (i = 0; i < items - 1; ++i)
   scalar_to_value (&val[i], ST(i+1), var);
CODE:
 struct missing_values mv;
 mv_init (&mv, var_get_width (var));
 for (i = 0 ; i < items - 1; ++i )
   mv_add_value (&mv, &val[i]);
 var_set_missing_values (var, &mv);


void
set_label (var, label)
 struct variable *var;
 char *label
CODE:
  var_set_label (var, label);


void
clear_value_labels (var)
 struct variable *var;
CODE:
 var_clear_value_labels (var);

SV *
get_write_format (var)
 struct variable *var
CODE:
 HV *fmthash = (HV *) sv_2mortal ((SV *) newHV());
 const struct fmt_spec *fmt = var_get_write_format (var);

 hv_store (fmthash, "fmt", 3, newSVnv (fmt->type), 0);
 hv_store (fmthash, "decimals", 8, newSVnv (fmt->d), 0);
 hv_store (fmthash, "width", 5, newSVnv (fmt->w), 0);

 RETVAL = newRV ((SV *) fmthash);
 OUTPUT:
RETVAL

SV *
get_print_format (var)
 struct variable *var
CODE:
 HV *fmthash = (HV *) sv_2mortal ((SV *) newHV());
 const struct fmt_spec *fmt = var_get_print_format (var);

 hv_store (fmthash, "fmt", 3, newSVnv (fmt->type), 0);
 hv_store (fmthash, "decimals", 8, newSVnv (fmt->d), 0);
 hv_store (fmthash, "width", 5, newSVnv (fmt->w), 0);

 RETVAL = newRV ((SV *) fmthash);
 OUTPUT:
RETVAL


void
pxs_set_write_format (var, fmt)
 struct variable *var
 output_format fmt
CODE:
 var_set_write_format (var, &fmt);


void
pxs_set_print_format (var, fmt)
 struct variable *var
 output_format fmt
CODE:
 var_set_print_format (var, &fmt);

void
pxs_set_output_format (var, fmt)
 struct variable *var
 output_format fmt
CODE:
 var_set_both_formats (var, &fmt);


int
add_value_label (var, key, label)
 struct variable *var
 SV *key
 char *label
INIT:
 SV *errstr = get_sv("PSPP::errstr", TRUE);
 sv_setpv (errstr, "");
CODE:
 union value the_value;
 int width = var_get_width (var);
 int ok;

 value_init (&the_value, width);
 if ( var_is_numeric (var))
 {
  if ( ! looks_like_number (key))
    {
      sv_setpv (errstr, "Cannot add label with string key to a numeric variable");
      value_destroy (&the_value, width);
      XSRETURN_IV (0);
    }
  the_value.f = SvNV (key);
 }
 else
 {
  value_copy_str_rpad (&the_value, width, SvPV_nolen(key), ' ');
 }
 ok = var_add_value_label (var, &the_value, label);
 value_destroy (&the_value, width);
 if (!ok)
 {
   sv_setpv (errstr, "Something went wrong");
   XSRETURN_IV (0);
 }
 XSRETURN_IV (1);


SV *
get_attributes (var)
 struct variable *var
CODE:
 HV *attrhash = (HV *) sv_2mortal ((SV *) newHV());

 struct attrset *as = var_get_attributes (var);

 if ( as )
   {
     struct attrset_iterator iter;
     struct attribute *attr;

     for (attr = attrset_first (as, &iter);
	  attr;
	  attr = attrset_next (as, &iter))
       {
	 int i;
	 const char *name = attribute_get_name (attr);

	 AV *values = newAV ();

	 for (i = 0 ; i < attribute_get_n_values (attr); ++i )
	   {
	     const char *value = attribute_get_value (attr, i);
	     av_push (values, newSVpv (value, 0));
	   }

	 hv_store (attrhash, name, strlen (name),
		   newRV_noinc ((SV*) values), 0);
       }
   }

 RETVAL = newRV ((SV *) attrhash);
 OUTPUT:
RETVAL


const char *
get_name (var)
 struct variable * var
CODE:
 RETVAL = var_get_name (var);
 OUTPUT:
RETVAL


const char *
get_label (var)
 struct variable * var
CODE:
 RETVAL = var_get_label (var);
 OUTPUT:
RETVAL


SV *
get_value_labels (var)
 struct variable *var
CODE:
 HV *labelhash = (HV *) sv_2mortal ((SV *) newHV());
 const struct val_lab *vl;
 struct val_labs_iterator *viter = NULL;
 const struct val_labs *labels = var_get_value_labels (var);

 if ( labels )
   {
     for (vl = val_labs_first (labels);
	  vl;
	  vl = val_labs_next (labels, vl))
       {
	 SV *sv = value_to_scalar (&vl->value, var);
	 STRLEN len;
	 const char *s = SvPV (sv, len);
	 hv_store (labelhash, s, len, newSVpv (val_lab_get_label (vl), 0), 0);
       }
   }

 RETVAL = newRV ((SV *) labelhash);
 OUTPUT:
RETVAL



MODULE = PSPP		PACKAGE = PSPP::Sysfile


struct sysfile_info *
pxs_create_sysfile (name, dict_ref, opts_hr)
 char *name
 SV *dict_ref
 SV *opts_hr
INIT:
 SV *dict_sv = SvRV (dict_ref);
 struct dictionary *dict = (void *) SvIV (dict_sv);
 struct sfm_write_options opts;
 if (!SvROK (opts_hr))
  {
    opts = sfm_writer_default_options ();
  }
 else
  {
    HV *opt_h = (HV *) SvRV (opts_hr);
    SV** readonly = hv_fetch(opt_h, "readonly", 8, 0);
    SV** compress = hv_fetch(opt_h, "compress", 8, 0);
    SV** version = hv_fetch(opt_h, "version", 7, 0);

    opts.create_writeable = readonly ? ! SvIV (*readonly) : true;
    opts.compress = compress ? SvIV (*compress) : false;
    opts.version = version ? SvIV (*version) : 3 ;
  }
CODE:
 struct file_handle *fh =
  fh_create_file (NULL, name, fh_default_properties () );
 struct sysfile_info *sfi = xmalloc (sizeof (*sfi));
 sfi->writer = sfm_open_writer (fh, dict, opts);
 sfi->dict = dict;
 sfi->opened = true;
 sfi->dict_sv = dict_sv;
 SvREFCNT_inc (sfi->dict_sv);
 
 RETVAL = sfi;
 OUTPUT:
RETVAL

int
close (sfi)
 struct sysfile_info *sfi
CODE:
 RETVAL = sysfile_close (sfi);
OUTPUT:
 RETVAL

void
DESTROY (sfi)
 struct sysfile_info *sfi
CODE:
 sysfile_close (sfi);
 SvREFCNT_dec (sfi->dict_sv);
 free (sfi);

int
append_case (sfi, ccase)
 struct sysfile_info *sfi
 SV *ccase
INIT:
 SV *errstr = get_sv("PSPP::errstr", TRUE);
 sv_setpv (errstr, "");
 if ( (!SvROK(ccase)))
  {
    XSRETURN_UNDEF;
  }
CODE:
 int i = 0;
 AV *av_case = (AV*) SvRV (ccase);

 const struct variable **vv;
 size_t nv;
 struct ccase *c;
 SV *sv;

 if ( av_len (av_case) >= dict_get_var_cnt (sfi->dict))
   XSRETURN_UNDEF;

 c =  case_create (dict_get_proto (sfi->dict));

 dict_get_vars (sfi->dict, &vv, &nv, 1u << DC_ORDINARY | 1u << DC_SYSTEM);

 for (sv = av_shift (av_case); SvOK (sv);  sv = av_shift (av_case))
 {
    const struct variable *v = vv[i++];
    const struct fmt_spec *ifmt = var_get_aux (v);

    /* If an input format has been set, then use it.
       Otherwise just convert the raw value.
    */
    if ( ifmt )
      {
	struct substring ss = ss_cstr (SvPV_nolen (sv));
	if ( ! data_in (ss, LEGACY_NATIVE, ifmt->type, 0, 0, 0,
			sfi->dict,
			case_data_rw (c, v),
			var_get_width (v)) )
	  {
	    RETVAL = 0;
	    goto finish;
	  }
      }
    else
      {
	scalar_to_value (case_data_rw (c, v), sv, v);
      }
 }

 /* The remaining variables must be sysmis or blank string */
 while (i < dict_get_var_cnt (sfi->dict))
 {
   const struct variable *v = vv[i++];
   union value *val = case_data_rw (c, v);
   value_set_missing (val, var_get_width (v));
 }
 RETVAL = casewriter_write (sfi->writer, c);
 finish:
 free (vv);
OUTPUT:
 RETVAL




MODULE = PSPP		PACKAGE = PSPP::Reader

struct sysreader_info *
pxs_open_sysfile (name)
 char * name
CODE:
 struct casereader *reader;
 struct sysreader_info *sri = NULL;
 struct file_handle *fh =
 	 fh_create_file (NULL, name, fh_default_properties () );

 sri = xmalloc (sizeof (*sri));
 sri->reader = sfm_open_reader (fh, &sri->dict, &sri->opts);

 if ( NULL == sri->reader)
 {
   free (sri);
   sri = NULL;
 }

 RETVAL = sri;
 OUTPUT:
RETVAL


struct dictionary *
pxs_get_dict (reader)
 struct sysreader_info *reader;
CODE:
 RETVAL = reader->dict;
 OUTPUT:
RETVAL


void
get_next_case (sfr)
 struct sysreader_info *sfr;
PPCODE:
 struct ccase *c;

 if (c = casereader_read (sfr->reader))
 {
  int v;

  EXTEND (SP, dict_get_var_cnt (sfr->dict));
  for (v = 0; v < dict_get_var_cnt (sfr->dict); ++v )
    {
      const struct variable *var = dict_get_var (sfr->dict, v);
      const union value *val = case_data (c, var);

      PUSHs (sv_2mortal (value_to_scalar (val, var)));
    }

  case_unref (c);
 }
