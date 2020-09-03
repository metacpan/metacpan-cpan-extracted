#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#include "SourceHighlight.hh"

static void bad_arg (char const *function, unsigned const argn,
	 char const *const error)
{
	char const *subclass = NULL;
	if (!strncmp (function, "lm_", 3))
		subclass = "LangMap";
	croak ("Wrong argument %u for Syntax::SourceHighlight%s%s::%s: %s",
		 argn - 1, subclass ? "::" : "", subclass ? subclass : "", function + 3,
		 error);
}

static void perlcall (SV *callback, ...)
{
	va_list ap;
	SV *arg;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	va_start (ap, callback);
	while ((arg = va_arg (ap, SV *)))
		XPUSHs (arg);
	va_end (ap);

	PUTBACK;
	call_sv (callback, G_VOID | G_EVAL);
	FREETMPS;
	LEAVE;

	if (SvTRUE (ERRSV))
	{
		STRLEN len;
		throw std::runtime_error (SvPV (ERRSV, len));
	}
}

static void *_instance (SV *const sv, char const *const function,
	 unsigned const argn)
{
	if (!sv || !SvROK (sv) || SvTYPE (SvRV (sv)) != SVt_PVHV)
		bad_arg (function, argn, "object reference expected");
	HV *self = (HV *) SvRV (sv);
	SV **instance = hv_fetchs (self, "instance", 0);
	if (!instance || !SvIOK (*instance) || !SvIV (*instance))
		bad_arg (function, argn, "{instance} not found");
	return (SourceHighlight *) SvIV (*instance);
}

static char *_string (SV *const sv, char const *const function,
	 unsigned const argn)
{
	if (!sv || !SvPOK (sv))
		bad_arg (function, argn, "string expected");
	STRLEN str_len;
	char *str = SvPV (sv, str_len);
	if (memchr (str, 0, str_len))
		bad_arg (function, argn, "string contains null characters");
	return str;
}

static char *_string (SV *const sv, unsigned &utf8_flag,
	 char const *const function, unsigned const argn)
{
	if (!sv || !SvPOK (sv))
		bad_arg (function, argn, "string expected");
	STRLEN str_len;
	char *str = SvPV (sv, str_len);
	if (memchr (str, 0, str_len))
		bad_arg (function, argn, "string contains null characters");
	utf8_flag = SvUTF8 (sv);
	return str;
}

static unsigned long _unsignd (SV *const sv, char const *const function,
	 unsigned const argn)
{
	if (!sv || (!SvIOK (sv) && !SvUOK (sv)))
		bad_arg (function, argn, "positive number expected");
	if (SvIOK (sv))
	{
		long i = SvIV (sv);
		if (i < 0)
			bad_arg (function, argn, "positive number expected");
		return i;
	}
	return SvUV (sv);
}

static bool _istrue (SV *const sv, char const *const function,
	 unsigned const argn)
{
	if (!sv)
		bad_arg (function, argn, "true/false value expected");
	return SvTRUE (sv);
}

static SV *_sub (SV *const sv, char const *const function,
	 unsigned const argn)
{
	STRLEN len;
	char *type = SvPV(sv, len);
	if (!sv || !SvROK (sv) || strncmp (type, "CODE", 4))
		bad_arg (function, argn, "code reference expected");
	return sv;
}

static SV *create_object (void *const ptr, char const *const type)
{
	HV *obj = newHV ();
	if (!obj || (ptr && !hv_stores (obj, "instance", newSViv ((long) ptr))))
	{
		hv_undef (obj);
		throw "Internal error: cannot create object";
	}
	SV *ref = newRV_noinc ((SV *) obj);
	return sv_bless (ref, gv_stashpv (type, 0));
}

static SV *new_array ()
{
	return newRV_noinc ((SV *) newAV ());
}

static SV *new_string (std::string const &s, unsigned const utf8)
{
	SV *str = newSVpv (s.data(), s.length());
	if (utf8 && is_utf8_string ((unsigned char const *) s.data(), s.length()))
		SvUTF8_on(str);
	return str;
}

static void hash_add (SV *const hashref, char const *const key, SV *const value)
{
	hv_store ((HV *) SvRV (hashref), key, strlen (key), value, 0);
}

static void array_push (SV *const arrayref, SV *const value)
{
	av_push ((AV *) SvRV (arrayref), value);
}

XS (sh_new)
{
	arguments (1, 2);
	char exception [256];
	char const *lang = string_opt (2, "html.outlang");
	char const *clss = string (1);

	SourceHighlight *sh = NULL;
	SV *obj;
	cpptry (
		sh = new SourceHighlight (lang);
		obj = create_object ((void *) sh, clss);
	);
	if (*exception)
	{
		delete sh;
		croak (exception);
	}

	XPUSHs (obj);
	XSRETURN (1);
}

XS (sh_destroy)
{
	arguments (1, 1);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	delete sh;
	XSRETURN (0);
}

XS (sh_checkLangDef)
{
	arguments (2, 2);
	char *lang_file = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->checkLangDef (lang_file));
	XSRETURN_EMPTY;
}

XS (sh_checkOutLangDef)
{
	arguments (2, 2);
	char *out_file = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->checkOutLangDef (out_file));
	XSRETURN_EMPTY;
}

XS (sh_createOutputFileName)
{
	arguments (2, 2);
	char *input_file = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (
		std::string name = sh->createOutputFileName (input_file).c_str ();
		XSRETURN_PV (name.c_str ());
	);
}

XS (sh_highlight)
{
	arguments (4, 4);
	char *input_lang = string (4);
	char *output = string (3);
	char *input = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->highlight (input, output, input_lang));

	// if the text goes to standard output, then its buffer should be flushed
	// before returning back to Perl
	if (!strlen (output))
		fflush (stdout);

	XSRETURN_EMPTY;
}

XS (sh_highlights)
{
	arguments (4, 4);
	char *file_name = string (4);
	char *input_lang = string (3);
	unsigned input_utf8;
	char *input_str = ustring (2, input_utf8);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (
		std::stringstream in (input_str);
		std::stringstream out;
		sh->highlight (in, out, input_lang, file_name);
		XPUSHs (new_string (out.str (), input_utf8));
		XSRETURN (1);
	);
}

XS (sh_setBinaryOutput)
{
	arguments (1, 2);
	bool use_binary = istrue_opt (2, true);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setBinaryOutput (use_binary));
	XSRETURN_EMPTY;
}

XS (sh_setCanUseStdOut)
{
	arguments (1, 2);
	bool use_stdout = istrue_opt (2, true);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setCanUseStdOut (use_stdout));
	XSRETURN_EMPTY;
}

XS (sh_setCss)
{
	arguments (2, 2);
	char *css = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setCss (css));
	XSRETURN_EMPTY;
}

XS (sh_setDataDir)
{
	arguments (2, 2);
	char *data_dir = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setDataDir (data_dir));
	XSRETURN_EMPTY;
}

XS (sh_setFooterFileName)
{
	arguments (2, 2);
	char *footer_file = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setFooterFileName (footer_file));
	XSRETURN_EMPTY;
}

XS (sh_setGenerateEntireDoc)
{
	arguments (1, 2);
	bool entire_doc = istrue_opt (2, true);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setGenerateEntireDoc (entire_doc));
	XSRETURN_EMPTY;
}

XS (sh_setGenerateLineNumbers)
{
	arguments (1, 2);
	bool gln = istrue_opt (2, true);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setGenerateLineNumbers (gln));
	XSRETURN_EMPTY;
}

XS (sh_setGenerateLineNumberRefs)
{
	arguments (1, 2);
	bool glnr = istrue_opt (2, true);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setGenerateLineNumberRefs (glnr));
	XSRETURN_EMPTY;
}

XS (sh_setGenerateVersion)
{
	arguments (1, 2);
	bool generate_version = istrue_opt (2, true);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setGenerateVersion (generate_version));
	XSRETURN_EMPTY;
}

XS (sh_setHeaderFileName)
{
	arguments (2, 2);
	char *header_file = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setHeaderFileName (header_file));
	XSRETURN_EMPTY;
}

XS (sh_setHighlightEventListener)
{
	arguments (2, 2);
	char exception [256];
	SV *callback = sub (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	PHighlightEventListener *el = NULL;
	cpptry (
		el = new PHighlightEventListener (callback);
		sh->setHighlightEventListener (el);
	);
	if (*exception)
	{
		delete el;
		croak (exception);
	}
	XSRETURN_EMPTY;
}

XS (sh_setLineNumberAnchorPrefix)
{
	arguments (2, 2);
	char *prefix = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setLineNumberAnchorPrefix (prefix));
	XSRETURN_EMPTY;
}

XS (sh_setLineNumberPad)
{
	arguments (2, 2);
	char *pad = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	if (strlen (pad) != 1)
		bad_arg ("sh_setLineNumberPad", 2, "single byte character expected");
	cppcall (sh->setLineNumberPad (pad [0]));
	XSRETURN_EMPTY;
}

XS (sh_setOptimize)
{
	arguments (1, 2);
	bool optimize = istrue_opt (2, true);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setOptimize (optimize));
	XSRETURN_EMPTY;
}

XS (sh_setOutputDir)
{
	arguments (2, 2);
	char *output_dir = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setOutputDir (output_dir));
	XSRETURN_EMPTY;
}

XS (sh_setRangeSeparator)
{
	arguments (2, 2);
	char *separator = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setRangeSeparator (separator));
	XSRETURN_EMPTY;
}

XS (sh_setStyleFile)
{
	arguments (2, 2);
	char *style_file = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setStyleFile (style_file));
	XSRETURN_EMPTY;
}

XS (sh_setStyleCssFile)
{
	arguments (2, 2);
	char *style_file = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setStyleCssFile (style_file));
	XSRETURN_EMPTY;
}

XS (sh_setStyleDefaultFile)
{
	arguments (2, 2);
	char *style_default_file = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setStyleDefaultFile (style_default_file));
	XSRETURN_EMPTY;
}

XS (sh_setTabSpaces)
{
	arguments (2, 2);
	unsigned spaces = unsignd (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setTabSpaces (spaces));
	XSRETURN_EMPTY;
}

XS (sh_setTitle)
{
	arguments (2, 2);
	char *title = string (2);
	SourceHighlight *sh = (SourceHighlight *) instance (1);
	cppcall (sh->setTitle (title));
	XSRETURN_EMPTY;
}

XS (lm_new)
{
	arguments (1, 3);
	char exception [256];
	char const *s3 = string_opt (3, NULL);
	char const *s2 = string_opt (2, "lang.map");
	char *clss = string (1);

	LangMap *lm;
	SV *obj;
	cpptry (
		 lm = s3 ? new LangMap (s2, s3) : new LangMap (s2);
		 obj = create_object ((void *) lm, clss);
	);
	if (*exception)
	{
		delete lm;
		croak (exception);
	}
	XPUSHs (obj);
	XSRETURN (1);
}

XS (lm_destroy)
{
	arguments (1, 1);
	LangMap *lm = (LangMap *) instance (1);
	delete lm;
	XSRETURN (0);
}

XS (lm_getMappedFileName)
{
	arguments (2, 2);
	char *lang = string (2);
	LangMap *lm = (LangMap *) instance (1);
	cppcall (
		std::string lang_file = lm->getMappedFileName (lang);
		XSRETURN_PV (lang_file.c_str ());
	);
}

XS (lm_getMappedFileNameFromFileName)
{
	arguments (2, 2);
	char *file_name = string (2);
	LangMap *lm = (LangMap *) instance (1);
	cppcall (
		std::string lang_file = lm->getMappedFileNameFromFileName (file_name);
		XSRETURN_PV (lang_file.c_str ());
	);
}

XS (lm_getLangNames)
{
	arguments (1, 1);
	LangMap *lm = (LangMap *) instance (1);
	std::set<std::string> ln;
	cppcall (ln = lm->getLangNames ());
	SV *names = new_array ();
	for (std::set<std::string>::const_iterator i = ln.begin();
		 i != ln.end(); i++)
		array_push (names, new_string (*i));
	XPUSHs (names);
	XSRETURN (1);
}

XS (lm_getMappedFileNames)
{
	arguments (1, 1);
	LangMap *lm = (LangMap *) instance (1);
	std::set<std::string> mfn;
	cppcall (mfn = lm->getMappedFileNames ());
	SV *names = new_array ();
	for (std::set<std::string>::const_iterator i = mfn.begin();
		 i != mfn.end(); i++)
		array_push (names, new_string (*i));
	XPUSHs (names);
	XSRETURN (1);
}

void PHighlightEventListener::notify (const HighlightEvent &event)
{
	PScalar he (create_object ((void *) &event,
		 "Syntax::SourceHighlight::HighlightEvent"));
	SV *ht = create_object ((void *) &event.token,
		 "Syntax::SourceHighlight::HighlightToken");

	AV *matched = newAV ();
	std::string m;
	for (MatchedElements::const_iterator i = event.token.matched.begin();
		 i != event.token.matched.end(); i++)
	{
		m.clear();
		((m += i->first) += ':') += i->second;
		av_push (matched, new_string (m));
	}

	hash_add (he, "type", newSViv (event.type));
	hash_add (he, "token", ht);
	hash_add (ht, "prefix", new_string (event.token.prefix));
	hash_add (ht, "prefixOnlySpaces", newSVuv (event.token.prefixOnlySpaces));
	hash_add (ht, "suffix", new_string (event.token.suffix));
	hash_add (ht, "matched", newRV_noinc ((SV *) matched));
	hash_add (ht, "matchedSize", newSVuv (event.token.matchedSize));

	perlcall (callback, he.sv, NULL);
}

struct XSDef
{
	char const *const name;
	XSUBADDR_t const sub;
};

struct XSDef const xs_def [] = {
	{ "new",                         sh_new },
	{ "DESTROY",                     sh_destroy },
	{ "checkLangDef",                sh_checkLangDef },
	{ "checkOutLangDef",             sh_checkOutLangDef },
	{ "createOutputFileName",        sh_createOutputFileName },
	{ "highlight",                   sh_highlight },
	{ "highlights",                  sh_highlights },
	{ "setBinaryOutput",             sh_setBinaryOutput },
	{ "setCanUseStdOut",             sh_setCanUseStdOut },
	{ "setCss",                      sh_setCss },
	{ "setDataDir",                  sh_setDataDir },
	{ "setFooterFileName",           sh_setFooterFileName },
	{ "setGenerateEntireDoc",        sh_setGenerateEntireDoc },
	{ "setGenerateLineNumbers",      sh_setGenerateLineNumbers },
	{ "setGenerateLineNumberRefs",   sh_setGenerateLineNumberRefs },
	{ "setGenerateVersion",          sh_setGenerateVersion },
	{ "setHeaderFileName",           sh_setHeaderFileName },
	{ "setHighlightEventListener",   sh_setHighlightEventListener },
	{ "setLineNumberAnchorPrefix",   sh_setLineNumberAnchorPrefix },
	{ "setLineNumberPad",            sh_setLineNumberPad },
	{ "setOptimize",                 sh_setOptimize },
	{ "setOutputDir",                sh_setOutputDir },
	{ "setRangeSeparator",           sh_setRangeSeparator },
	{ "setStyleCssFile",             sh_setStyleCssFile },
	{ "setStyleDefaultFile",         sh_setStyleDefaultFile },
	{ "setStyleFile",                sh_setStyleFile },
	{ "setTabSpaces",                sh_setTabSpaces },
	{ "setTitle",                    sh_setTitle },

	{ "LangMap::new",                lm_new },
	{ "LangMap::DESTROY",            lm_destroy },
	{ "LangMap::getMappedFileName",  lm_getMappedFileName },
	{ "LangMap::getMappedFileNameFromFileName",
		                               lm_getMappedFileNameFromFileName },
	{ "LangMap::getLangNames",       lm_getLangNames },
	{ "LangMap::getMappedFileNames", lm_getMappedFileNames },

	{ }
};

XS (boot_Syntax__SourceHighlight)
{
	char name [256];
	unsigned i;
	dXSARGS;
	for (i = 0; xs_def[i].name; i++)
	{
		snprintf (name, sizeof (name) - 1, "Syntax::SourceHighlight::%s",
			 xs_def[i].name);
		newXS (name, xs_def[i].sub, (char *) __FILE__);
	}
	XSRETURN (0);
}
