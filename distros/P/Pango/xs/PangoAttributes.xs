/*
 * Copyright (c) 2005-2006, 2013-2014 by the gtk2-perl team (see the AUTHORS
 * file for a full list of authors)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top-level directory of this distribution for
 * the full license terms.
 *
 */

#include "pango-perl.h"

#define PANGO_PERL_ATTR_STORE_INDICES(offset, attr)	\
	if (items == offset + 2) {			\
		guint start = SvUV (ST (offset));	\
		guint end = SvUV (ST (offset + 1));	\
		attr->start_index = start;		\
		attr->end_index = end;			\
	}

/* ------------------------------------------------------------------------- */

static GPerlBoxedWrapperClass pango_color_wrapper_class;

static SV *
pango_color_wrap (GType gtype,
                  const char * package,
                  gpointer boxed,
		  gboolean own)
{
	PangoColor *color = boxed;
	AV *av;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	if (!color)
		return &PL_sv_undef;

	av = newAV ();

	av_push (av, newSVuv (color->red));
	av_push (av, newSVuv (color->green));
	av_push (av, newSVuv (color->blue));

	if (own)
		pango_color_free (color);

	return sv_bless (newRV_noinc ((SV *) av),
	       		 gv_stashpv ("Pango::Color", TRUE));
}

/* This uses gperl_alloc_temp so make sure you don't hold on to pointers
 * returned by SvPangoColor for too long. */
static gpointer
pango_color_unwrap (GType gtype,
		    const char * package,
		    SV * sv)
{
	PangoColor *color;
	AV * av;
	SV ** v;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	if (!gperl_sv_is_defined (sv))
		return NULL;

	if (!gperl_sv_is_array_ref (sv))
		croak ("a PangoColor must be an array reference with three values: "
		       "red, green, and blue");

	color = gperl_alloc_temp (sizeof (PangoColor));

	av = (AV *) SvRV (sv);

	v = av_fetch (av, 0, 0);
	if (v && gperl_sv_is_defined (*v))
		color->red = SvUV (*v);

	v = av_fetch (av, 1, 0);
	if (v && gperl_sv_is_defined (*v))
		color->green = SvUV (*v);

	v = av_fetch (av, 2, 0);
	if (v && gperl_sv_is_defined (*v))
		color->blue = SvUV (*v);

	return color;
}

static void
pango_color_destroy (SV * sv)
{
	/* We allocated nothing in wrap, so do nothing here. */
	PERL_UNUSED_VAR (sv);
}

/* ------------------------------------------------------------------------- */

GType
gtk2perl_pango_attribute_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("PangoAttribute",
		      (GBoxedCopyFunc) pango_attribute_copy,
		      (GBoxedFreeFunc) pango_attribute_destroy);
	return t;
}

static GHashTable *gtk2perl_pango_attribute_table = NULL;

/* Exported for Gtk2/xs/GdkPango.xs. */
void
gtk2perl_pango_attribute_register_custom_type (PangoAttrType type,
					       const char *package)
{
	if (!gtk2perl_pango_attribute_table)
		gtk2perl_pango_attribute_table =
			g_hash_table_new (g_direct_hash, g_direct_equal);
	g_hash_table_insert (gtk2perl_pango_attribute_table,
			     GINT_TO_POINTER (type), (gpointer) package);
}

static const char *
gtk2perl_pango_attribute_lookup_custom_type (PangoAttrType type)
{
	return g_hash_table_lookup (gtk2perl_pango_attribute_table,
	       			    GINT_TO_POINTER (type));
}

static const char *
gtk2perl_pango_attribute_get_package (PangoAttribute * attr)
{
	/* the interface is designed to allow extensibility by registering
	 * new PangoAttrType values, but pango doesn't allow us to query
	 * those.  but we have hacks in place, so we can try anyway. */
	switch (attr->klass->type) {
	    case PANGO_ATTR_INVALID:
		croak ("invalid PangoAttribute encountered; should not happen");
		return NULL;
	    case PANGO_ATTR_LANGUAGE:
		return "Pango::AttrLanguage";
	    case PANGO_ATTR_FAMILY:
		return "Pango::AttrFamily";
	    case PANGO_ATTR_STYLE:
	    	return "Pango::AttrStyle";
	    case PANGO_ATTR_WEIGHT:
		return "Pango::AttrWeight";
	    case PANGO_ATTR_VARIANT:
		return "Pango::AttrVariant";
	    case PANGO_ATTR_STRETCH:
		return "Pango::AttrStretch";
	    case PANGO_ATTR_SIZE:
#if PANGO_CHECK_VERSION (1, 8, 0)
	    case PANGO_ATTR_ABSOLUTE_SIZE:
#endif
		return "Pango::AttrSize";
	    case PANGO_ATTR_FONT_DESC:
		return "Pango::AttrFontDesc";
	    case PANGO_ATTR_FOREGROUND:
		return "Pango::AttrForeground";
	    case PANGO_ATTR_BACKGROUND:
		return "Pango::AttrBackground";
	    case PANGO_ATTR_UNDERLINE:
		return "Pango::AttrUnderline";
	    case PANGO_ATTR_STRIKETHROUGH:
		return "Pango::AttrStrikethrough";
	    case PANGO_ATTR_RISE:
		return "Pango::AttrRise";
	    case PANGO_ATTR_SHAPE:
		return "Pango::AttrShape";
	    case PANGO_ATTR_SCALE:
		return "Pango::AttrScale";
#if PANGO_CHECK_VERSION (1, 4, 0)
	    case PANGO_ATTR_FALLBACK:
		return "Pango::AttrFallback";
#endif
#if PANGO_CHECK_VERSION (1, 6, 0)
	    case PANGO_ATTR_LETTER_SPACING:
		return "Pango::AttrLetterSpacing";
#endif
#if PANGO_CHECK_VERSION (1, 8, 0)
	    case PANGO_ATTR_UNDERLINE_COLOR:
		return "Pango::AttrUnderlineColor";
	    case PANGO_ATTR_STRIKETHROUGH_COLOR:
		return "Pango::AttrStrikethroughColor";
#endif
#if PANGO_CHECK_VERSION (1, 16, 0)
	    case PANGO_ATTR_GRAVITY:
		return "Pango::AttrGravity";
	    case PANGO_ATTR_GRAVITY_HINT:
		return "Pango::AttrGravityHint";
#endif
	    default:
	    {
		const char *package =
			gtk2perl_pango_attribute_lookup_custom_type
				(attr->klass->type);
		if (package)
			return package;
		return "Pango::Attribute";
	    }
	}
}

static GPerlBoxedWrapperClass   gtk2perl_pango_attribute_wrapper_class;
static GPerlBoxedWrapperClass * default_wrapper_class;

static SV *
gtk2perl_pango_attribute_wrap (GType gtype,
                      	       const char * package,
                      	       gpointer boxed,
		      	       gboolean own)
{
	PangoAttribute * attr = boxed;
	HV * stash;
	SV * sv;

	sv = default_wrapper_class->wrap (gtype, package, boxed, own);

	/* Override the default package */
	package = gtk2perl_pango_attribute_get_package (attr);
	stash = gv_stashpv (package, TRUE);
	return sv_bless (sv, stash);
}

static gpointer
gtk2perl_pango_attribute_unwrap (GType gtype,
				 const char * package,
				 SV * sv)
{
	PangoAttribute * attr = default_wrapper_class->unwrap (gtype, package, sv);

	/* Override the default package */
	package = gtk2perl_pango_attribute_get_package (attr);

	if (!sv_derived_from (sv, package))
		croak ("%s is not of type %s",
		       gperl_format_variable_for_output (sv),
		       package);

	return attr;
}

/* ------------------------------------------------------------------------- */

GType
gtk2perl_pango_attr_iterator_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("PangoAttrIterator",
		      (GBoxedCopyFunc) pango_attr_iterator_copy,
		      (GBoxedFreeFunc) pango_attr_iterator_destroy);
	return t;
}

/* ------------------------------------------------------------------------- */

#if PANGO_CHECK_VERSION (1, 2, 0)

static GPerlCallback *
gtk2perl_pango_attr_filter_func_create (SV * func, SV * data)
{
	GType param_types [1];
	param_types[0] = PANGO_TYPE_ATTRIBUTE;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_BOOLEAN);
}

static gboolean
gtk2perl_pango_attr_filter_func (PangoAttribute *attribute,
			      	 gpointer data)
{
	GPerlCallback * callback = (GPerlCallback*)data;
	GValue value = {0,};
	gboolean retval;

	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, attribute);
	retval = g_value_get_boolean (&value);
	g_value_unset (&value);

	return retval;
}

#endif

/* ------------------------------------------------------------------------- */

MODULE = Pango::Attributes	PACKAGE = Pango::Color	PREFIX = pango_color_

BOOT:
	PERL_UNUSED_VAR (file);
	pango_color_wrapper_class.wrap = pango_color_wrap;
	pango_color_wrapper_class.unwrap = pango_color_unwrap;
	pango_color_wrapper_class.destroy = pango_color_destroy;
	gperl_register_boxed (PANGO_TYPE_COLOR, "Pango::Color",
	                      &pango_color_wrapper_class);

##gboolean pango_color_parse (PangoColor *color, const char *spec);
PangoColor *
pango_color_parse (class, const gchar * spec)
    PREINIT:
	PangoColor color;
    CODE:
	if (! pango_color_parse (&color, spec))
		XSRETURN_UNDEF;
	RETVAL = &color;
    OUTPUT:
	RETVAL

#if PANGO_CHECK_VERSION (1, 16, 0)

=for apidoc
=for signature string = $color->to_string
=cut
##gchar *pango_color_to_string(const PangoColor *color);
gchar_own *
pango_color_to_string (...)
    CODE:
	if (items == 1)
		RETVAL = pango_color_to_string (SvPangoColor (ST (0)));
	else if (items == 2)
		RETVAL = pango_color_to_string (SvPangoColor (ST (1)));
	else
		croak ("Usage: Pango::Color::to_string($color)");
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #
# First, the base class of all attributes
# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::Attribute	PREFIX = pango_attribute_

BOOT:
	default_wrapper_class = gperl_default_boxed_wrapper_class ();
	gtk2perl_pango_attribute_wrapper_class = * default_wrapper_class;
	gtk2perl_pango_attribute_wrapper_class.wrap = gtk2perl_pango_attribute_wrap;
	gtk2perl_pango_attribute_wrapper_class.unwrap = gtk2perl_pango_attribute_unwrap;
	gperl_register_boxed (PANGO_TYPE_ATTRIBUTE, "Pango::Attribute",
	                      &gtk2perl_pango_attribute_wrapper_class);

guint
start_index (PangoAttribute * attr, ...)
    ALIAS:
	end_index = 1
    CODE:
	RETVAL = ix == 0 ? attr->start_index : attr->end_index;
	if (items > 1) {
		guint new_index = SvIV (ST (1));
		if (ix == 0)
			attr->start_index = new_index;
		else
			attr->end_index = new_index;
	}
    OUTPUT:
	RETVAL

gboolean pango_attribute_equal (PangoAttribute * attr1, PangoAttribute * attr2);

# --------------------------------------------------------------------------- #
# Then, a few abstract base classes
# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrString

BOOT:
	gperl_set_isa ("Pango::AttrString", "Pango::Attribute");

gchar_own *
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = g_strdup (((PangoAttrString*)attr)->value);
	if (items > 1) {
		/* this feels evil... */
		if (((PangoAttrString*)attr)->value)
			g_free (((PangoAttrString*)attr)->value);
		((PangoAttrString*)attr)->value = g_strdup (SvGChar (ST (1)));
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrInt

BOOT:
	gperl_set_isa ("Pango::AttrInt", "Pango::Attribute");

int
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*)attr)->value;
	if (items > 1)
		((PangoAttrInt*)attr)->value = SvIV (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrColor

BOOT:
	gperl_set_isa ("Pango::AttrColor", "Pango::Attribute");

##
## the PangoAttrColor holds an actual color, not a pointer...
## how can we make it editable from perl?  you can replace it,
## but you get a copy back and editing it does nothing...
##
PangoColor *
value (PangoAttribute * attr, ...)
    PREINIT:
	PangoColor copy;
    CODE:
	copy = ((PangoAttrColor*)attr)->color;
	RETVAL = &copy;
	if (items > 1) {
		PangoColor * color = SvPangoColor (ST (1));
		((PangoAttrColor*)attr)->color = *color;
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #
# And finally, the special-purpose attributes
# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrLanguage	PREFIX = pango_attr_language_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrLanguage");
	gperl_set_isa ("Pango::AttrLanguage", "Pango::Attribute");

=for apidoc
C<Pango::AttrLanguage> doesn't take a reference and doesn't copy the
C<Pango::Language> object, but demands its validity nonetheless.  So make
sure the language object stays alive at least as long as the attribute.
=cut
PangoAttribute_own * pango_attr_language_new (class, PangoLanguage *language, ...);
    C_ARGS:
	language
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoLanguage *
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrLanguage*)attr)->value;
	if (items > 1) {
		/* from the pango source, this is all we need to do. */
		((PangoAttrLanguage*)attr)->value = SvPangoLanguage (ST (1));
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrFamily	PREFIX = pango_attr_family_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrFamily");
	gperl_set_isa ("Pango::AttrFamily", "Pango::AttrString");

PangoAttribute_own * pango_attr_family_new (class, const char *family, ...);
    C_ARGS:
	family
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrForeground	PREFIX = pango_attr_foreground_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrForeground");
	gperl_set_isa ("Pango::AttrForeground", "Pango::AttrColor");

PangoAttribute_own * pango_attr_foreground_new (class, guint16 red, guint green, guint16 blue, ...);
    C_ARGS:
	red, green, blue
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (4, RETVAL);

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrBackground	PREFIX = pango_attr_background_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrBackground");
	gperl_set_isa ("Pango::AttrBackground", "Pango::AttrColor");

PangoAttribute_own * pango_attr_background_new (class, guint16 red, guint green, guint16 blue, ...);
    C_ARGS:
	red, green, blue
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (4, RETVAL);

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrSize	PREFIX = pango_attr_size_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrSize");
	gperl_set_isa ("Pango::AttrSize", "Pango::AttrInt");

PangoAttribute_own * pango_attr_size_new (class, int size, ...)
    C_ARGS:
	size
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

#if PANGO_CHECK_VERSION (1, 8, 0)

PangoAttribute_own * pango_attr_size_new_absolute (class, int size, ...)
    C_ARGS:
	size
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

#endif

# Later versions of pango use PangoAttrSize rather than PangoAttrInt, but
# they're compatible with respect to the value field.  So we can safely use the
# value accessor of Pango::AttrInt.

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrStyle	PREFIX = pango_attr_style_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrStyle");
	gperl_set_isa ("Pango::AttrStyle", "Pango::Attribute");

PangoAttribute_own * pango_attr_style_new (class, PangoStyle style, ...)
    C_ARGS:
	style
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoStyle
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*) attr)->value;
	if (items > 1)
		((PangoAttrInt*) attr)->value = SvPangoStyle (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrWeight	PREFIX = pango_attr_weight_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrWeight");
	gperl_set_isa ("Pango::AttrWeight", "Pango::Attribute");

PangoAttribute_own * pango_attr_weight_new (class, PangoWeight weight, ...);
    C_ARGS:
	weight
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoWeight
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*) attr)->value;
	if (items > 1)
		((PangoAttrInt*) attr)->value = SvPangoWeight (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrVariant	PREFIX = pango_attr_variant_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrVariant");
	gperl_set_isa ("Pango::AttrVariant", "Pango::Attribute");

PangoAttribute_own * pango_attr_variant_new (class, PangoVariant variant, ...)
    C_ARGS:
	variant
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoVariant
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*) attr)->value;
	if (items > 1)
		((PangoAttrInt*) attr)->value = SvPangoVariant (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrStretch	PREFIX = pango_attr_stretch_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrStretch");
	gperl_set_isa ("Pango::AttrStretch", "Pango::Attribute");

PangoAttribute_own * pango_attr_stretch_new (class, PangoStretch stretch, ...)
    C_ARGS:
	stretch
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoStretch
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*) attr)->value;
	if (items > 1)
		((PangoAttrInt*) attr)->value = SvPangoStretch (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrUnderline	PREFIX = pango_attr_underline_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrUnderline");
	gperl_set_isa ("Pango::AttrUnderline", "Pango::Attribute");

PangoAttribute_own * pango_attr_underline_new (class, PangoUnderline underline, ...)
    C_ARGS:
	underline
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoUnderline
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*) attr)->value;
	if (items > 1)
		((PangoAttrInt*) attr)->value = SvPangoUnderline (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrStrikethrough	PREFIX = pango_attr_strikethrough_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrStrikethrough");
	gperl_set_isa ("Pango::AttrStrikethrough", "Pango::Attribute");

PangoAttribute_own * pango_attr_strikethrough_new (class, gboolean strikethrough, ...)
    C_ARGS:
	strikethrough
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

gboolean
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*) attr)->value;
	if (items > 1)
		((PangoAttrInt*) attr)->value = SvTRUE (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrFontDesc	PREFIX = pango_attr_font_desc_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrFontDesc");
	gperl_set_isa ("Pango::AttrFontDesc", "Pango::Attribute");

PangoAttribute_own * pango_attr_font_desc_new (class, PangoFontDescription * font_desc, ...)
    C_ARGS:
	font_desc
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoFontDescription_own *
desc (PangoAttribute * attr, ...)
    CODE:
	RETVAL = pango_font_description_copy (((PangoAttrFontDesc*) attr)->desc);
	if (items > 1) {
		if (((PangoAttrFontDesc*) attr)->desc)
			pango_font_description_free (((PangoAttrFontDesc*) attr)->desc);
		((PangoAttrFontDesc*) attr)->desc =
			pango_font_description_copy (SvPangoFontDescription (ST (1)));
	}
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrScale	PREFIX = pango_attr_scale_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrScale");
	gperl_set_isa ("Pango::AttrScale", "Pango::Attribute");

PangoAttribute_own * pango_attr_scale_new (class, float scale, ...)
    C_ARGS:
	scale
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

double
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrFloat*) attr)->value;
	if (items > 1)
		((PangoAttrFloat*) attr)->value = SvNV (ST (1));
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrRise	PREFIX = pango_attr_rise_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrRise");
	gperl_set_isa ("Pango::AttrRise", "Pango::AttrInt");

PangoAttribute_own * pango_attr_rise_new (class, int rise, ...)
    C_ARGS:
	rise
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrShape	PREFIX = pango_attr_shape_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrShape");
	gperl_set_isa ("Pango::AttrShape", "Pango::Attribute");

PangoAttribute_own * pango_attr_shape_new (class, PangoRectangle *ink_rect, PangoRectangle *logical_rect, ...)
    C_ARGS:
	ink_rect, logical_rect
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (3, RETVAL);

PangoRectangle *
ink_rect (PangoAttribute * attr, ...)
    ALIAS:
	logical_rect = 1
    PREINIT:
	PangoAttrShape * attrshape;
    CODE:
	attrshape = (PangoAttrShape *) attr;
	RETVAL = ix == 0 ? &(attrshape->ink_rect) : &(attrshape->logical_rect);
	if (items > 1) {
		PangoRectangle * rect = SvPangoRectangle (ST (1));
		if (ix == 0)
			attrshape->ink_rect = *rect;
		else
			attrshape->logical_rect = *rect;
	}
    OUTPUT:
	RETVAL

# FIXME: Needed?
# PangoAttribute * pango_attr_shape_new_with_data (const PangoRectangle  *ink_rect, const PangoRectangle *logical_rect, gpointer data, PangoAttrDataCopyFunc copy_func, GDestroyNotify destroy_func)

# --------------------------------------------------------------------------- #

#if PANGO_CHECK_VERSION (1, 4, 0)

MODULE = Pango::Attributes	PACKAGE = Pango::AttrFallback	PREFIX = pango_attr_fallback_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrFallback");
	gperl_set_isa ("Pango::AttrFallback", "Pango::Attribute");

PangoAttribute_own * pango_attr_fallback_new (class, gboolean enable_fallback, ...)
    C_ARGS:
	enable_fallback
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

gboolean
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*) attr)->value;
	if (items > 1)
		((PangoAttrInt*) attr)->value = SvTRUE (ST (1));
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

#if PANGO_CHECK_VERSION (1, 6, 0)

MODULE = Pango::Attributes	PACKAGE = Pango::AttrLetterSpacing	PREFIX = pango_attr_letter_spacing_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrLetterSpacing");
	gperl_set_isa ("Pango::AttrLetterSpacing", "Pango::AttrInt");

PangoAttribute_own * pango_attr_letter_spacing_new (class, int letter_spacing, ...)
    C_ARGS:
	letter_spacing
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

#endif

# --------------------------------------------------------------------------- #

#if PANGO_CHECK_VERSION (1, 8, 0)

MODULE = Pango::Attributes	PACKAGE = Pango::AttrUnderlineColor	PREFIX = pango_attr_underline_color_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrUnderlineColor");
	gperl_set_isa ("Pango::AttrUnderlineColor", "Pango::AttrColor");

PangoAttribute_own * pango_attr_underline_color_new (class, guint16 red, guint16 green, guint16 blue, ...)
    C_ARGS:
	red, green, blue
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (4, RETVAL);

#endif

# --------------------------------------------------------------------------- #

#if PANGO_CHECK_VERSION (1, 8, 0)

MODULE = Pango::Attributes	PACKAGE = Pango::AttrStrikethroughColor	PREFIX = pango_attr_strikethrough_color_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrStrikethroughColor");
	gperl_set_isa ("Pango::AttrStrikethroughColor", "Pango::AttrColor");

PangoAttribute_own * pango_attr_strikethrough_color_new (class, guint16 red, guint16 green, guint16 blue, ...)
    C_ARGS:
	red, green, blue
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (4, RETVAL);

#endif

# --------------------------------------------------------------------------- #

#if PANGO_CHECK_VERSION (1, 16, 0)

MODULE = Pango::Attributes	PACKAGE = Pango::AttrGravity	PREFIX = pango_attr_gravity_

BOOT:
	gperl_register_boxed_alias (PANGO_TYPE_ATTRIBUTE, "Pango::AttrGravity");
	gperl_set_isa ("Pango::AttrGravity", "Pango::Attribute");

PangoAttribute_own * pango_attr_gravity_new (class, PangoGravity gravity, ...)
    C_ARGS:
	gravity
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoGravity
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*)attr)->value;
	if (items > 1)
		((PangoAttrInt*)attr)->value = SvPangoGravity (ST (1));
    OUTPUT:
	RETVAL

MODULE = Pango::Attributes	PACKAGE = Pango::AttrGravityHint	PREFIX = pango_attr_gravity_hint_

BOOT:
	gperl_set_isa ("Pango::AttrGravityHint", "Pango::Attribute");

PangoAttribute_own * pango_attr_gravity_hint_new (class, PangoGravityHint hint, ...)
    C_ARGS:
	hint
    POSTCALL:
	PANGO_PERL_ATTR_STORE_INDICES (2, RETVAL);

PangoGravityHint
value (PangoAttribute * attr, ...)
    CODE:
	RETVAL = ((PangoAttrInt*)attr)->value;
	if (items > 1)
		((PangoAttrInt*)attr)->value = SvPangoGravityHint (ST (1));
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrList	PREFIX = pango_attr_list_

=for position DESCRIPTION

=head1 DESCRIPTION

Pango::AttrList is a collection of Pango::Attributes.  These
attributes annotate text with styles.

=cut

PangoAttrList_own * pango_attr_list_new (class)
    C_ARGS:
	/*void*/

# The various insert functions assume ownership of the attribute, so we have to
# hand them a copy.

void pango_attr_list_insert (PangoAttrList *list, PangoAttribute *attr)
    C_ARGS:
	list, pango_attribute_copy (attr)

void pango_attr_list_insert_before (PangoAttrList *list, PangoAttribute *attr)
    C_ARGS:
	list, pango_attribute_copy (attr)

void pango_attr_list_change (PangoAttrList *list, PangoAttribute *attr)
    C_ARGS:
	list, pango_attribute_copy (attr)

void pango_attr_list_splice (PangoAttrList *list, PangoAttrList *other, gint pos, gint len);

#if PANGO_CHECK_VERSION (1, 2, 0)

##PangoAttrList *pango_attr_list_filter (PangoAttrList *list, PangoAttrFilterFunc  func, gpointer data);
PangoAttrList_own_ornull *
pango_attr_list_filter (PangoAttrList *list, SV *func, SV *data = NULL)
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gtk2perl_pango_attr_filter_func_create (func, data);
	RETVAL = pango_attr_list_filter (
	       	   list, gtk2perl_pango_attr_filter_func, callback);
	gperl_callback_destroy (callback);
    OUTPUT:
	RETVAL

#endif

PangoAttrIterator *pango_attr_list_get_iterator (PangoAttrList *list);

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango::AttrIterator	PREFIX = pango_attr_iterator_

void pango_attr_iterator_range (PangoAttrIterator *iterator, OUTLIST gint start, OUTLIST gint end);

gboolean pango_attr_iterator_next (PangoAttrIterator *iterator);

PangoAttribute_ornull *pango_attr_iterator_get (PangoAttrIterator *iterator, PangoAttrType type);

##void pango_attr_iterator_get_font (PangoAttrIterator *iterator, PangoFontDescription *desc, PangoLanguage **language, GSList **extra_attrs);
=for apidoc
=for signature ($desc, $lang, $extra_attrs) = $iterator->get_font
=cut
void
pango_attr_iterator_get_font (PangoAttrIterator *iterator)
    PREINIT:
	PangoFontDescription *desc;
	PangoLanguage *language;
	GSList *extra_attrs, *i;
    PPCODE:
	desc = pango_font_description_new ();
	language = NULL;
	extra_attrs = NULL;
	pango_attr_iterator_get_font (iterator, desc, &language, &extra_attrs);
	XPUSHs (sv_2mortal (newSVPangoFontDescription_copy (desc)));
	XPUSHs (sv_2mortal (newSVPangoLanguage_ornull (language)));
	for (i = extra_attrs; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVPangoAttribute_own (i->data)));
	if (extra_attrs)
		g_slist_free (extra_attrs);

#if PANGO_CHECK_VERSION (1, 2, 0)

##GSList * pango_attr_iterator_get_attrs (PangoAttrIterator *iterator);
void
pango_attr_iterator_get_attrs (PangoAttrIterator *iterator)
    PREINIT:
	GSList *result, *i;
    PPCODE:
	result = pango_attr_iterator_get_attrs (iterator);
	for (i = result; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVPangoAttribute_own (i->data)));
	g_slist_free (result);

#endif

# --------------------------------------------------------------------------- #

MODULE = Pango::Attributes	PACKAGE = Pango	PREFIX = pango_

# don't clobber the pod for Pango!
=for object Pango::AttrList
=cut

##gboolean pango_parse_markup (const char                 *markup_text,
##                             int                         length,
##                             gunichar                    accel_marker,
##                             PangoAttrList             **attr_list,
##                             char                      **text,
##                             gunichar                   *accel_char,
##                             GError                    **error);
##
=for apidoc __gerror__
=for signature ($attr_list, $text, $accel_char) = Pango->parse_markup ($markup_text, $accel_marker)
Parses marked-up text to create a plaintext string and an attribute list.

If I<$accel_marker> is supplied and nonzero, the given character will mark the
character following it as an accelerator.  For example, the accel marker might
be an ampersand or underscore.  All characters marked as an acclerator will
receive a PANGO_UNDERLINE_LOW attribute, and the first character so marked will
be returned in I<$accel_char>.  Two I<$accel_marker> characters following each
other reduce to a single literal I<$accel_marker> character.
=cut
void
pango_parse_markup (class, const gchar_length * markup_text, int length(markup_text), gunichar accel_marker=0)
    PREINIT:
	PangoAttrList * attr_list;
	char * text;
	gunichar accel_char;
	GError * error = NULL;
    PPCODE:
	if (! pango_parse_markup (markup_text, XSauto_length_of_markup_text,
				  accel_marker, &attr_list, &text,
				  &accel_char, &error))
		gperl_croak_gerror (NULL, error);
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVPangoAttrList (attr_list)));
	PUSHs (sv_2mortal (newSVGChar (text)));
	g_free (text);
	if (accel_char) {
		/* adapted from Glib/typemap */
		gchar temp[6];
		gint length = g_unichar_to_utf8 (accel_char, temp);
		PUSHs (sv_2mortal (newSVpv (temp, length)));
		SvUTF8_on (ST (2));
	}
