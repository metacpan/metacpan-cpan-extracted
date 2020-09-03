/*

This documentation can be also rendered with:

    perldoc ./SourceHighlight.hh

=pod

=encoding UTF-8

=head1 NAME

F<SourceHighlight.hh>, F<SourceHighlight.cc> – Perl to C++ glue for GNU
libsource-highlight

=head1 SYNOPSIS

    use parent 'DynaLoader';
    bootstrap Syntax::SourceHighlight;

=head1 DESCRIPTION

This library exports part of the
L<libsource-highlight API|https://www.gnu.org/software/src-highlite/api/> as
Perl classes. It is normally imported by the Syntax::SourceHighlight package.

=cut */

#include <string>
#include <iostream>
#include <sstream>

#include <srchilite/highlighttoken.h>
#include <srchilite/highlightevent.h>
#include <srchilite/highlighteventlistener.h>
#include <srchilite/sourcehighlight.h>
#include <srchilite/langmap.h>
#include <srchilite/ioexception.h>

using namespace srchilite;

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
=head1 CALLING FUNCTIONS AND MACROS

=head2 C<bad_arg()>

This function throws B<Perl> exception using the
C<< L<croak()|perlapi/croak> >> call. The general format for these exceptions
is I<Wrong argument ... for Syntax::SourceHighlight...> followed by the given
error message.

    static void bad_arg (
        char const *function,
        unsigned    argn,
        char const *error
    );

B<function> is the name of the calling function; it is normally taken from the
               __FUNCTION__ macro;
B<argn>     is the number of the argument for which the error occurred;
B<error>    is the actual message to be dispatched.

=cut */

static void bad_arg (char const *function, unsigned argn, char const *error);

/*
=head2 C<cppcall()>

This macro executes the statements included in the argument and converts any
C++ exceptions to Perl adding the calling function name. The
C<< L<croak()|perlapi/croak> >> call does not return, so it is not suitable
wherever there are any allocated C++ structures.

=cut */

#define cppcall(BLOCK) \
	try \
	{ \
		BLOCK; \
	} \
	catch (const std::exception &e) \
	{ \
		croak ("libsource-highlight (%s): %s", __FUNCTION__, e.what ()); \
	}

/*
=head2 C<cpptry()>

This macro executes the statements included in the argument and converts any
C++ exceptions to preallocated string called "exception". The string can be
later tested and passed to C<croak()> after deallocating any C++ structures
that were created.

    cpptry (
        allocations;
        statements;
    );
    if (*exception)
    {
        cleanup;
        croak (exception);
    }

=cut */

#define cpptry(BLOCK) \
	try \
	{ \
		memset (exception, 0, sizeof (exception)); \
		BLOCK; \
	} \
	catch (const std::exception &e) \
	{ \
		snprintf (exception, sizeof (exception) - 1, \
			 "libsource-highlight (%s): %s", __FUNCTION__, e.what ()); \
	}

/*
=head2 C<perlcall()>

This function executes the given Perl code passing any extra arguments to it.
The arguments should be allocated and freed by the caller with
C<< L<sv_free()|perlapi/sv_free> >>.

    static void perlcall (SV *callback, ...);

B<callback> is the Perl code reference that will be executed;
B<...>      is a NULL-terminated list of function arguments of type C<SV *>
            that will be passed to the code.

=cut */

static void perlcall (SV *callback, ...);

/*
=head1 ARGUMENT PROCESSING

All stack retrieving functions/macros below take one or two arguments: argument
number that will be returned in the exception string in case of an error, and
the default value in case of the C<*_opt> variants.

=head2 C<PScalar> class

This class wraps Perl scalar value (I<SV>) pointer and deallocates it on
destruction by calling C<< L<sv_free()|perlapi/sv_free> >>. The pointer can be
accessed either from the C<sv> attribute, or by casting to C<SV *>.

Example:

    PScalar s (new_string ("Hello, world!"));

=cut */

class PScalar
{
	public:
	SV *sv;
	PScalar (SV *const sv) : sv(sv) { }
	~PScalar () { sv_free (sv); }
	operator SV *() { return sv; }
};

/*
=head2 C<arguments()>

This macro is placed at the beginning of each XS callback and takes two numbers
– the minimum and the maximum number of arguments that the function accepts. It
throws B<Perl> exception I<Invalid number of arguments...> if the number of
variables in Perl's stack is outside the given range.

    #define arguments (min, max)

B<min> is the minimum number of arguments this function requires;
B<max> is the maximum number of arguments allowed.

=cut */

#define arguments(min, max) \
	dXSARGS; \
	if (items < min || items > max) \
		croak ("Invalid number of arguments supplied to " \
			 "Syntax::SourceHighlight::%s: %u given, %u-%u expected", \
			 __FUNCTION__, items, min, max) 

/*
=head2 C<instance()>

Takes a hashref from the Perl stack. The hashref should contain the {instance}
key, where pointer to the C++ object is stored. The C<< L</bad_arg()> >>
function will be called on any type mismatch.

Example:

    arguments (1, 1);
    Object *o = (Object *) instance (1);
    printf ("Got object %p\n", o);

=cut */

#define instance(...) _instance (POPs, __FUNCTION__, __VA_ARGS__)
static void *_instance (SV *sv, char const *function, unsigned argn);

/*
=head2 C<string()> and C<string_opt()>

These macros take one string off the Perl stack.

=cut */

#define string(n) _string (POPs, __FUNCTION__, n)
#define string_opt(n, dflt) \
	( (n <= items) ? _string (POPs, __FUNCTION__, n) : dflt )
static char *_string (SV *sv, char const *function, unsigned argn);

/*
=head2 C<ustring()>

This macro takes one string off the Perl stack and also retrieves its UTF-8
flag with SvUTF8().

=cut */

#define ustring(n, uf) _string (POPs, uf, __FUNCTION__, n)
#define ustring_opt(n, uf, dflt) \
	( (n <= items) ? _string (POPs, uf, __FUNCTION__, n) : dflt )
static char *_string (SV *sv, unsigned &utf8_flag, char const *function,
	 unsigned argn);

/*
=head2 C<unsignd()> and C<unsignd_opt()>

These macros retrieve an unsigned integer from the Perl stack.

=cut */

#define unsignd(n) _unsignd (POPs, __FUNCTION__, n)
#define unsignd_opt(n, dflt) \
	( (n <= items) ? _unsignd (POPs, __FUNCTION__, n) : dflt )
static unsigned long _unsignd (SV *sv, char const *function, unsigned argn);

/*
=head2 C<istrue()> and C<istrue_opt()>

These macros retrieve a true/false value from Perl stack. The state is verified
with the C<< L<SvTRUE()|perlapi/SvTRUE> >> call.

=cut */

#define istrue(n) _istrue (POPs, __FUNCTION__, n)
#define istrue_opt(n, dflt) \
	( (n <= items) ? _istrue (POPs, __FUNCTION__, n) : dflt )
static bool _istrue (SV *sv, char const *function, unsigned argn);

/*
=head2 C<sub()> and C<sub_opt()>

These macros retrieve a code reference from the Perl stack.

Example:

    SV *perl_sub = sub (2);
    perlcall (sub, NULL);

=cut */

#define sub(n) _sub (POPs, __FUNCTION__, n)
#define sub_opt(n, dflt) \
	( (n <= items) ? _sub (POPs, __FUNCTION__, n) : dflt )
static SV *_sub (SV *sv, char const *function, unsigned argn);

/*
=head1 OBJECT CREATION

All Perl objects created with these functions must be deallocated with
C<< L<sv_free()|perlapi/sv_free> >> or passed back to Perl as return values
with C<< L<XPUSHs()|perlapi/XPUSHs> >>.

=head2 C<create_object()>

This function creates Perl hashref, blesses it with desired class and
optionally stores C++ class instance pointer as the B<{instance}> value of the
hashref.

The instance can be later retrieved from C<$self> with the
C<< L</instance()> >> call.

    static SV *create_object (void *ptr, char const *type);

B<ptr>  (optional, may be C<NULL>) is a C++ pointer that will be stored in the
        I<{instance}> value of the newly created hash;
B<type> is the Perl class name the hashref will be blessed with.

=cut */

static SV *create_object (void *ptr, char const *type);

/*
=head2 C<new_array()>

This function creates a new arrayref.

    static SV *new_array ();

=cut */

static SV *new_array ();

/*
=head2 C<new_string()>

This function takes two arguments. The first one is the C<std::string> that
will be the new string's initial content. The other indicates whether UTF-8
flag should be set if applicable. It returns the newly allocated Perl scalar.

    static SV *new_string (std::string const &s, unsigned const utf8 = 1);

=cut */

static SV *new_string (std::string const &s, unsigned const utf8 = 1);

/*
=head2 C<hash_add()>

Adds one scalar to a hash by calling C<< L<hv_store()|perlapi/hv_store> >>.

    static void hash_add (SV *hashref, char const *key, SV *value);

=cut */

static void hash_add (SV *hashref, char const *key, SV *value);

/*
=head2 C<array_push()>

Appends the array with yet another item by calling
C<< L<av_push|perlapi/av_push> >>.

    static void array_push (SV *arrayref, SV *value);

=cut */

static void array_push (SV *arrayref, SV *value);

/*
=head1 PERL TO LIBRARY GLUE

The library functions are exported to Perl under the same names as they are in
the syntax-sourcehighlight library along with their class names except for the
C<SourceHighlight> class which is exported directly to
C<Syntax::SourceHighlight> namespace.

Internal function names are prepended with two letter class code and
underscore, followed with C++ method name as is. They are mapped in the
C<xs_def> array and exported to Perl by the C<boot_Syntax__SourceHighlight()>
function.

Any public C++ attributes are exported as hash values by their constructors.

=head2 C<SourceHighlight> class

The C<SourceHighlight> methods are exported to the C<Syntax::SourceHighlight>
namespace. Their naming and arguments are the same as documented in the
L<API reference|https://www.gnu.org/software/src-highlite/api/classsrchilite_1_1SourceHighlight.html>,
with the following exceptions:

=over

=item

there is one additional function, C<sh_highlights()> which accepts three
arguments (input string, input language, and optional file name reported to the
user) returning string that allows direct convertion of string data instead of
IO streams,

=item

the four argument variant of C<highlight()> that works on streams is not
implemented.

=back

=cut */

XS (sh_new);
XS (sh_destroy);
XS (sh_checkLangDef);
XS (sh_checkOutLangDef);
XS (sh_createOutputFileName);
XS (sh_highlight);
XS (sh_highlights);
XS (sh_setBinaryOutput);
XS (sh_setCanUseStdOut);
XS (sh_setCss);
XS (sh_setDataDir);
XS (sh_setFooterFileName);
XS (sh_setGenerateEntireDoc);
XS (sh_setGenerateLineNumbers);
XS (sh_setGenerateLineNumberRefs);
XS (sh_setGenerateVersion);
XS (sh_setHeaderFileName);
XS (sh_setHighlightEventListener);
XS (sh_setLineNumberAnchorPrefix);
XS (sh_setLineNumberPad);
XS (sh_setOptimize);
XS (sh_setOutputDir);
XS (sh_setRangeSeparator);
XS (sh_setStyleCssFile);
XS (sh_setStyleDefaultFile);
XS (sh_setStyleFile);
XS (sh_setTabSpaces);
XS (sh_setTitle);

/*
=head2 C<LangMap> class

The C<LangMap> class internals are exported to the
C<Syntax::SourceHighlight::LangMap> namespace. The C<getFileName()>, C<open()>,
C<print()>, and C<reload()> calls are not implemented. The constructor accepts
invocation with no arguments with the default value for I<lang> being
C<"lang.map">.

=cut */

XS (lm_new);
XS (lm_destroy);
XS (lm_getMappedFileName);
XS (lm_getMappedFileNameFromFileName);
XS (lm_getLangNames);
XS (lm_getMappedFileNames);

/*
=head2 C<HighlightEventListener> class

This class does not exist in Perl code, but it used for internal purposes as
C<PHighlightEventListener>. Here it extends the base class with one extra
attribute – C<SV *callback> which stores the address of the Perl subroutine
that serves as the equivalent of C<notify()>.

=cut */

class PHighlightEventListener : public HighlightEventListener
{
	public:
	SV *callback;
	PHighlightEventListener (SV *const callback) : HighlightEventListener()
	{
		this->callback = callback;
		SvREFCNT_inc (callback);
	}
	~PHighlightEventListener()
	{
		SvREFCNT_dec (callback);
	}
	virtual void notify (const HighlightEvent &);
};

/*
=head1 DYNALOADER'S BOOT

The C<boot_Syntax__SourceHighlight()> entry is called upon loading the shared
object. Its job is to export the L<glue functions|/PERL TO LIBRARY GLUE> to
Perl namespace. The name mapping is defined in the C<xs_def> array inside of
the C++ code.

=cut */

XS (boot_Syntax__SourceHighlight);

/*

=head1 SEE ALSO

=over

=item

L<Introduction to the Perl API|perlguts> (perlguts)

=item

L<Autogenerated documentation for the perl public API|perlapi> (perlapi)

=back

=cut

*/
