##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp - multi-page-state-preserving web applications

=head1 SYNOPSIS

I<This module requires quite an elaborate setup (see the INSTALL
file). Please read the LICENSE file: this version of PApp is neither GPL
nor BSD licensed).>

=head1 DESCRIPTION

PApp is a complete solution for developing multi-page web
applications that preserve state I<across> page views. It also tracks user
id's, supports a user access system and provides many utility functions
(html, sql...). You do not need (and should not use) the CGI module.

Advantages:

=over 4

=item * Speed. PApp isn't much slower than a hand-coded mod_perl handler,
and this is only due to the extra database request to fetch and restore
state, which typically you would do anyway. To the contrary: a non-trivial
Apache::Registry page is slower than the equivalent PApp application (or
much, much more complicated).

=item * Embedded Perl. You can freely embed perl into your documents. In
fact, You can do things like these:

   <h1>Names and amounts</h1>
   <:
      my $st = sql_exec \my($name, $amount), "select name, amount from ...",

      while ($st->fetch) {?>
         Name: $name, Amount: $amount<p>
      <:}
   :>
   <hr>

That is, mixing html and perl at statement boundaries.

=item * State-preserving: The global hash C<%state> is automaticaly
preserved during the session. Everything you save there will be available
in any subsequent pages that the user accesses.

=item * XML. PApp-applications are written in XML. While this is no
advantage in itself, it means that it uses a standardized file format that
can easily be extended. PApp comes with a DTD and a vim syntax
file, even ;)

=item * Easy internationalisation. I18n has never been that easy:
just mark you strings with __C<>"string", either in html or in the perl
source. The "poedit"-demo-application enables editing of the strings
on-line, so translaters need not touch any text files and can work
diretcly via the web.

=item * Feature-Rich. PApp comes with a I<lot> of
small-but-nice-to-have functionality.

=back

Have a look at the F<doc/> subdirectory of the distribution, which will
have some tutorials in sdf and html format.

=cut

package PApp;

use 5.010;

use common::sense;

#   imports
use Carp;
use FileHandle ();
use File::Basename qw(dirname);

use PApp::Storable;
use Compress::LZF qw(:compress :freeze);

use Crypt::Twofish2;

use PApp::Config qw(DBH $DBH); DBH;
use PApp::FormBuffer;
use PApp::Exception;
use PApp::I18n;
use PApp::HTML qw(escape_uri escape_html tag alink unixtime2http);
use PApp::SQL;
use PApp::Callback;
use PApp::Application;
use PApp::Util;
use PApp::Recode ();
use PApp::Prefs ();
use PApp::Session ();
use PApp::Event ();

<<' */'=~m>>;
 
/*
 * the DataRef (and Callback) modules must be included just in case
 * no application has been loaded and we need to deserialize state,
 * since overloaded packages must already exist before an object becomes
 * overloaded. Ugly.
 */

use PApp::DataRef ();

use Convert::Scalar qw(:utf8 weaken);

BEGIN {
   our $VERSION = 2.2;

   use base Exporter::;

   our @EXPORT = qw(
         debugbox

         surl slink sform cform suburl sublink retlink_p returl retlink
         multipart_form parse_multipart_form
         endform redirect internal_redirect abort_to content_type
         abort_with setlocale fixup_marker insert_fixup

         SURL_PUSH SURL_UNSHIFT SURL_POP SURL_SHIFT
         SURL_EXEC SURL_SAVE_PREFS SURL_SET_LOCALE SURL_SUFFIX
         SURL_EXEC_IMMED SURL_START_SESSION

         surl_style postpone
         SURL_STYLE_URL SURL_STYLE_GET SURL_STYLE_STATIC

         $request $NOW $papp *state %P *A *S
         $userid $sessionid
         reload_p switch_userid getuid

         dprintf dprint echo capture $request
         
         N_ language_selector preferences_url preferences_link
         $prefs $curprefs getpref setpref save_prefs
   );
   our @EXPORT_OK = qw(config_eval abort_with_file);

   # might also get loaded in PApp::Util
   require XSLoader;
   XSLoader::load PApp, $VERSION unless defined &PApp::bootstrap;

   our @ISA;
   unshift @ISA, "PApp::Base";
}

sub getuid(); # prototype needed

#   globals
#   due to what I call bugs in mod_perl, my variables do not survive
#   configuration time unless global

use vars qw(
   $translator $configured $cipher_d $libdir $i18ndir $sessionid $prevstateid $alternative
   $cookie_reset $cookie_expires $checkdeps $delayed $content_type $output_charset $surlstyle
   $in_cleanup $onerr $translator $configured $key $statedb $statedb_user $statedb_pass
   $pmod $uid
);

    $translator;

    $configured;

    $key          = $PApp::Config{CIPHERKEY};
our $cipher_e;
    $cipher_d;

    $libdir       = $PApp::Config{LIBDIR};
    $i18ndir      = $PApp::Config{I18NDIR};

our $stateid;     # uncrypted state-id
    $sessionid;
    $prevstateid;
    $alternative;

our $userid;      # uncrypted user-id

our %state;
our %arguments;
our %temporary;
our %P;

our %papp;        # toplevel ("mounted") applications

our $NOW;         # the current time (so you only need to call "time" once)

# other globals. must be globals since they should be accessible outside
our $output;      # the collected output (must be global)
our $routput = \$output; # the real output, even inside capture {}
our $doutput;     # debugging output
our @fixup;

our $location;    # the current location (a.k.a. application, pathname)
our $pathinfo;    # the "CGI"-pathinfo
our $papp;        # the current location (a.k.a. application)

our $curconf;     # the current configuration hash

our $request;     # the apache request object

our $langs;       # contains the current requested languages (e.g. "de, en-GB")

    $cookie_reset   = 86400;       # reset the cookie at most every ... seconds
    $cookie_expires = 86400 * 365; # cookie expiry time (one year, whooo..)

    $checkdeps;   # check dependencies (relatively slow)
    $delayed;     # delay loading of apps until needed

our %preferences; # keys that are preferences are marked here

    $content_type;
    $output_charset;
our $output_p = 0;# flush called already?

    $surlstyle  = 1; # scalar SURL_STYLE_URL;

    $in_cleanup = 0; # are we in a clean-up phase?

    $onerr      = 'sha';
our $warn_log; # all warnings will be logged here

our $url_prefix_nossl = undef;
our $url_prefix_ssl = undef;
our $url_prefix_sslauth = undef;

our $logfile = undef;

our $prefs    = new PApp::Prefs \"";       # the global preferences
our $curprefs = new PApp::Prefs *location; # the current application preferences

our ($st_reload_p, $st_replacepref, $st_deletepref, $st_newuserid, $st_insertstate,
     $_config, $st_newstateids, $st_fetchstate, $st_eventcount, $event_count);

%preferences = (  # system default preferences
   '' => [qw(
      papp_locale
      papp_cookie
   )],
);

# flush translation table caches when they are re-written
PApp::Event::on papp_i18n_flush => sub {
   PApp::I18n::flush_cache;
};

our $restart_flag;
if ($restart_flag) {
   die "FATAL ERROR: PerlFreshRestart is buggy\n";
   PApp::Util::_exit(0);
} else {
   $restart_flag = 1;
}

our $save_prefs_cb = create_callback {
   &save_prefs if $userid;
} name => "papp_save_prefs";

our $start_session_cb = create_callback {
   &start_session;
} name => "papp_start_session";

sub SURL_PUSH         ($$){ ( "\x00\x01", undef, @_ ) }
sub SURL_UNSHIFT      ($$){ ( "\x00\x02", undef, @_ ) }
sub SURL_POP          ($) { ( "\x00\x81", @_ ) }
sub SURL_SHIFT        ($) { ( "\x00\x82", @_ ) }
#sub SURL_EXEC         ($) { SURL_PUSH("/papp_execonce" => $_[0]) }
sub SURL_EXEC_IMMED   ($) { "\x00\x91", \$_[0] }
sub SURL_EXEC         ($) { $_[0] }
sub SURL_SAVE_PREFS   ()  { $save_prefs_cb }
sub SURL_SET_LOCALE   ($) { ( SURL_SAVE_PREFS, "/papp_locale" => $_[0] ) }
sub SURL_START_SESSION()  { SURL_EXEC_IMMED ($start_session_cb) }

sub SURL_SUFFIX       ($) { ("\x00\x41", @_) }
sub SURL_STYLE        ($) { ("\x00\x42", @_) }
sub _SURL_STYLE_URL   ()  { 1 }
sub _SURL_STYLE_GET   ()  { 2 }
sub _SURL_STYLE_STATIC()  { 3 }

sub SURL_STYLE_URL    ()  { SURL_STYLE(_SURL_STYLE_URL    ) }
sub SURL_STYLE_GET    ()  { SURL_STYLE(_SURL_STYLE_GET    ) }
sub SURL_STYLE_STATIC ()  { SURL_STYLE(_SURL_STYLE_STATIC ) }

sub CHARSET (){ "utf-8" } # the charset used internally by PApp

# we might be slow, but we are rarely being called ;)
sub __($) {
   $translator
      ? $translator->get_table($langs)->gettext($_[0])
      : $_[0]
}

sub N_($) { $_[0] }

# constant
our $xmlnspapp = "http://www.plan9.de/xmlns/papp";

=head1 Global Variables

Some global variables are free to use and even free to change (yes, we
still are about speed, not abstraction). In addition to these variables,
the globs C<*state>, C<*S> and C<*A> (and in future versions C<*L>)
are reserved. This means that you cannot define a scalar, sub, hash,
filehandle or whatsoever with these names.

=over 4

=item $request [read-only]

The Apache request object (L<Apache>), the same as returned by C<< Apache->request >>.

=item %state [read-write, persistent]

A system-global hash that can be used for almost any purpose, such as
saving (global) preferences values. All keys with prefix C<papp> are
reserved for use by this module. Everything else is yours.

=item %P [read-write, input only]

Contains the parameters from forms submitted via GET or POST (C<see
parse_multipart_form>, however). Everything in this hash is insecure by
nature and must be sanitised before use.

Normally, the values stored in C<%P> are plain strings (in UTF-8,
though). However, it is possible to submit the same field multiple times,
in which case the value stored in C<$P{field}> is a reference to an array
with all strings, i.e. if you want to evaluate a form field that might be
submitted multiple times (e.g. checkboxes or multi-select elements) you
must use something like this:

   my @values = ref $P{field} ? @{$P{field}} : $P{field};

=item %temporary [not exported]

Is empty at the beginning of a request and will be cleared at request end.

=item $userid [read-only]

The current userid. User-Id's are automatically assigned, you are
encouraged to use them for your own user-databases, but you must not trust
them. C<$userid> is zero in case no userid has been assigned yet. In this
case you can force a userid by calling the function C<getuid>, which
allocated one if necessary,

=item $sessionid [read-only]

A unique number identifying the current session (not page). You could use
this for transactions or similar purposes. This variable might or might
not be zero indicating that no session has been allocated yet (similar to
C<$userid> == 0).

=item $curprefs, $prefs [L<PApp::Prefs>]

The current application's (C<$curprefs>) and the global (C<$prefs>) preferences object.

  $curprefs->get("bg_color");
  ef_string $curprefs->ref("bg_color"), 15;

=item $PApp::papp (a hash-ref) [read-only] [not exported] [might get replaced by a function call]

The current PApp::Application object (see L<PApp::Application>). The
following keys are user-readable:

 config   the argument to the C<config>option given to C<mount>.

=item $PApp::location [read-only] [not exported] [might get replaced by a function call]

The location value from C<mount>.

=item $NOW [read-only]

Contains the time (as returned by C<time>) at the start of the request.
Highly useful for checking cache time-outs or similar things, as it is
faster to use this variable than to call C<time>.

=back

=head1 Functions/Methods

=over 4

=item PApp->search_path(path...);

Add a directory in where to search for included/imported/"module'd" files.

=item PApp->configure(name => value...);

Configures PApp, must be called once and once only. Most of the
configuration values get their defaults from the secured config file
and/or give defaults for applications.

 pappdb        The (mysql) database to use as papp-database
               (default "DBI:mysql:papp")
 pappdb_user   The username when connecting to the database
 pappdb_pass   The password when connecting to the database
 cipherkey     The Twofish-Key to use (16 binary bytes),
               BIG SECURITY PROBLEM if not set!
               (you can use 'mcookie' from util-linux twice to generate one)
 cookie_reset  delay in seconds after which papp tries to
               re-set the cookie (default: one day)
 cookie_expires time in seconds after which a cookie shall expire
               (default: one year)
 logfile       The path to a file where errors and warnings are being logged
               to (the default is stderr which is connected to the client
               browser on many web-servers)

The following configuration values are used mainly for development:

 checkdeps     when set, papp will check the .papp file dates for
               every request (slow!!) and will reload the app when necessary.
 delayed       do not compile applications at server startup, only on first
               access. This greatly increases memory consumption but ensures
               that the httpd startup works and is faster.
 onerr         can be one or more of the following characters that
               specify how to react to an unhandled exception. (default: 'sha')
               's' save the error into the error table
               'v' view all the information (security problem)
               'h' show the error category only
               'a' give the admin user the ability to log-in/view the error

=item PApp->mount_appset($appset)

Mount all applications in the named application set. Usually used in the httpd.conf file
to mount many applications into the same virtual server etc... Example:

  mount_appset PApp 'default';

=item PApp->mount_app($appname)

Can be used to mount a single application.

The following description is no longer valid.

 location[*]   The URI the application is mounted under, must start with "/".
               Currently, no other slashes are allowed in it.
 src[*]        The .papp-file to mount there
 config        Will be available to the application as $papp->{config}
 delayed       see C<PApp->configure>.

 [*] required attributes

=item ($name, $version) = PApp->interface

Return name and version of the interface PApp runs under
(e.g. "PApp::Apache" or "PApp:CGI").

=cut

# undocumented interface. uarg. values %{$event_handler{type}} gives coderefs
our %event_handler;

sub event {
   my $self = shift;
   my $event = shift;
   $_->($event) for values %{$event_handler{$event}};
   for $papp (values %{$papp->{"/"}}) {
      $papp->event($event);
   }
}

sub search_path {
   shift;
   goto &PApp::Config::search_path;
}

sub PApp::Base::configure {
   my $self = shift;
   my %a = @_;
   my $caller = caller;

   $configured = 1;

   exists $a{libdir}		and $libdir	  = $a{libdir};
   exists $a{pappdb}		and $statedb	  = $a{pappdb};
   exists $a{pappdb_user}	and $statedb_user = $a{pappdb_user};
   exists $a{pappdb_pass}	and $statedb_pass = $a{pappdb_pass};

   exists $a{cookie_reset}	and $cookie_reset = $a{cookie_reset};
   exists $a{cookie_expires}	and $cookie_expires = $a{cookie_expires};

   exists $a{cipherkey}		and $key	  = $a{cipherkey};

   exists $a{onerr}		and $onerr	  = $a{onerr};

   exists $a{url_prefix_nossl}	and $url_prefix_nossl   = $a{url_prefix_nossl};
   exists $a{url_prefix_ssl}	and $url_prefix_ssl     = $a{url_prefix_ssl};
   exists $a{url_prefix_sslauth}and $url_prefix_sslauth = $a{url_prefix_sslauth};

   exists $a{checkdeps}		and $checkdeps	  = $a{checkdeps};
   exists $a{delayed}		and $delayed	  = $a{delayed};

   exists $a{logfile}		and $logfile	  = $a{logfile};

   my $lang = { lang => 'en', domain => 'papp' };
   
   #TODO#d# register internal modules in papp app
   # this loop autovivifies INC elements. d'oh.
#   for (
#         $INC{"PApp.pm"},
#         $INC{"PApp/FormBuffer.pm"},
#         $INC{"PApp/I18n.pm"},
#         $INC{"PApp/Exception.pm"},
#         $INC{"PApp/XPCSE.pm"},
#         $INC{"PApp/EditForm.pm"},
#       ) {
#      $papp_main->register_file($_, domain => "papp", lang => "en");
#   };

#   $papp{$papp_main->{appid}} = $papp_main;
}

sub PApp::Base::configured {
   # mod_perl does this to us....
   #$configured and warn "PApp::configured called multiple times\n";

   if ($configured == 1) {
      if (!$key) {
         warn "no cipherkey was specified, this is an insecure configuration";
         $key = "c9381ddf6cfe96f1dacea7e7a86887542d6aaa6476cf5bbf895df0d4f298e741";
      }
      my $key = pack "H*", $key;
      $cipher_d = new Crypt::Twofish2 $key;
      $cipher_e = new Crypt::Twofish2 $key;

      PApp::Event::skip_all_events;

      PApp::I18n::set_base($i18ndir);

      $translator = PApp::I18n::open_translator("papp", "en");

      $configured = 2;

      PApp->event('init');
   } elsif ($configured == 0) {
      fancydie "PApp: 'configured' called without preceding 'configure'";
   }
}

# must be called after fork, see PApp::Apache
sub post_fork_cleanup {
   PApp::I18n::flush_cache;
   PApp::SQL::reinitialize;
   undef $PApp::Config::DBH;
   PApp::Config::DBH;
}

sub configured_p {
   $configured;
}

#############################################################################

=item dprintf "format", value...

=item dprint value...

Work just like print/printf, except that the output is queued for later use by the C<debugbox> function.

=item echo value[, value...]

Works just like the C<print> function, except that it is faster for generating output.

=item capture { code/macros/html }

Captures the output of "code/macros/perl" and returns it, instead of
sending it to the browser. This is more powerful than it sounds, for
example, this works:

 <:
    my $output = capture {

       print "of course, this is easy\n";
       echo "this as well";
       :>

       Yes, this is captured as well!
       <:&this_works:>
       <?$captureme:>

       <:

    }; # close the capture
 :>

=cut

sub echo(@) {
   $output .= join "", @_;
}

sub capture(&) {
   local *output;
   &{$_[0]};
   $output;
}

sub dprintf(@) {
   my $format = shift;
   $doutput .= sprintf $format, @_;
}

sub dprint(@) {
   $doutput .= join "", @_;
}

=item my $guard = PApp::guard { ... }

This function still exists, but is deprecated. Please use the
C<Guard::guard> function instead.

=cut

use Guard ();
BEGIN { *guard = \&Guard::guard }

=item content_type $type [, $charset]

Sets the output content type to C<$type>. The content-type should be a
registered MIME type (see RFC 2046) like C<text/html> or C<image/png>. The
optional argument C<$charset> can be either "*", which selects a suitable
output encoding dynamically (e.g. according to C<$state{papp_locale}>)
or the name of a registered character set (STD 2). The special value
C<undef> suppresses output character conversion entirely. If not given,
the previous value will be unchanged (the default; currently "*").

Charset-negotiation is not yet implemented, but when it is implemented it
will work like this:

The charset argument might also be an array-reference giving charsets that
should be tried in order (similar to the language preferences). The last
charset will be I<forced>, i.e. characters not representable in the output
will be replaced by some implementation defined way (if possible, this
will be C<&#charcode;>, which is at least as good a replacement as any
other ;)

=cut

sub content_type($;$) {
   $content_type = shift;
   $output_charset = lc shift if @_;
}

=item setlocale [$locale]

Sets the locale used by perl to the given (PApp-style) locale string. This
might involve multiple calls to the "real" setlocale which in turn might
be very slow (C<setlocale> is very slow on glibc based systems for
example). If no argument is given it sets the locale to the current user's
default locale (see C<SURL_SET_LOCALE>). NOTE: Remember that PApp (and
Perl) requires iso-8859-1 or utf-8, so be prepared to do any conversion
yourself. In future versions PApp might help you doing this (e.g. by
setting LC_CTYPE to utf-8, but this is not supported on many systems).

At the moment, PApp does not automatically set the (Perl) locale on each
request, so you need to call setlocale before using any locale-based
functions.

Please note that PApp-style locale strings might not be compatible to your
system's locale strings (this function does the conversion).

=cut

sub setlocale(;$) {
   my $locale = @_ ? $_[0] : $state{papp_locale};
   require POSIX;
   POSIX::setlocale (LC_ALL => $locale);
}

=item $url = surl arg => value, ...

C<surl> is one of the most often used functions to create urls. The
arguments are parameters that are passed to the application. Unlike
GET or POST-requests, these parameters are directly passed into the
C<%state>-hash (unless prefixed with a dash), i.e. you can use this to
alter state values when the url is activated. This data is transfered in a
secure way and can be quite large (it will not go over the wire).

When a parameter name is prefixed with a minus-sign, the value will end up
in the (non-persistent) C<%A>-hash instead (for "one-shot" arguments).

Otherwise the argument name is treated similar to an absolute path under
unix. Examples:

 /papp_locale  $state{papp_locale}
 /tt/var       $state{'/tt'}{var} -OR- $S{var} in application /tt
 /tt/mod1/var  $state{'/tt'}{'/mod1'}{var}

The following (symbolic) modifiers can also be used:

 SURL_PUSH(<path> => <value>)
 SURL_UNSHIFT(<path> => <value>)
   treat the following state key as an arrayref and push or unshift the
   argument onto it.

 SURL_POP(<path-or-ref>)
 SURL_SHIFT(<path-or-ref>)
   treat the following state key as arrayref and pop/shift it.

 SURL_EXEC(<coderef>) [obsolete]
   treat the following parameter as code-reference and execute it
   after all other assignments have been done. this SURL modifier
   is deprecated, PApp::Callback callbacks don't need this modifier
   anymore.

   Nowadays, code-references found anywhere in the surlargs are treated
   as if they had a SURL_EXEC wrapped around them. IF you want to pass a
   coderef, you therefore have to pass a reference to it or wrap it into
   an object.

 SURL_EXEC_IMMED(<coderef>)
   Like SURL_EXEC, but will be executed immediately when parsing. This
   can be used to implement special surl behaviour, because it can affect
   values specified after this specification. Normally, you don't want
   to use this call.

 SURL_SAVE_PREFS
   call save_prefs

 SURL_START_SESSION
   start a new session, tearing the connection to the current session.
   must be specified early in the surlargs. Right now, the %state is not
   being cleared and retains its old values, so watch out!

 SURL_STYLE_URL
 SURL_STYLE_GET
 SURL_STYLE_STATIC
   set various url styles, see C<surl_style>.

 SURL_SUFFIX(<file>)
   sets the filename in the generated url to the given string. The
   filename is the last component of the url commonly used by browsers as
   the default name to save files. Works only with SURL_STYLE_GET.

Examples:

 SURL_PUSH("/stack" => 5)   push 5 onto @{$S{stack}}
 SURL_SHIFT("/stack")       shift @{$S{stack}}
 SURL_SAVE_PREFS           save the preferences on click
 SURL_EXEC($cref->refer)   execute the PApp::Callback object

=item surl_style [newstyle]

Set a new surl style and return the old one (actually, a token that can be
used with C<surl_style>. C<newstyle> must be one of:

 SURL_STYLE_URL
   The "classic" papp style, the session id gets embedded into the url,
   like C</admin/+modules-/bhWU3DBm2hsusnFktCMbn0>.

 SURL_STYLE_GET
   The session id is encoded as the form field named "papp" and appended
   to the url as a get request, e.g. C</admin/+modules-?papp=bhWU3DBm2hsusnFktCMbn0>.

 SURL_STYLE_STATIC
   The session id is not encoded into the url, e.g. C</admin/+modules->,
   instead, surl returns two arguments. This must never be set as a
   default using C<surl_style>, but only when using surl directly.

=cut

sub surl_style {
   my $old = $surlstyle;
   $surlstyle = $_[1] || $_[0];
   $old;
}

=item postpone { ... } [args...]

Can only be called inside (or before) SURL_EXEC callbacks, and postpones
the block to be executed after all other callbacks. Just like callbacks
themeselves, these callbacks are executed in FIFO order. The current
database handle will be restored.

=cut

sub postpone(&;@) {
   my ($cb, @args) = @_;
   my ($db, $dbh) = ($PApp::SQL::Database, $PApp::SQL::DBH);
   push @{$state{papp_execonce}}, sub {
      local $PApp::SQL::Database = $db;
      local $PApp::SQL::DBH      = $dbh;
      $cb->(@args);
   };
}

=item $ahref = slink contents,[ module,] arg => value, ...

This is just "alink shift, &url", that is, it returns a link with the
given contants, and a url created by C<surl> (see above). For example, to create
a link to the view_game module for a given game, do this:

 <? slink "Click me to view game #$gamenr", "view_game", gamenr => $gamenr :>

The view_game module can access the game number as $S{gamenr}.

=cut

# complex "link content, secure-args"
sub slink {
   alink shift, &surl;
}

=item ($marker, $ref) = fixup_marker [$initial_content]

Create a new fixup marker and return a scalar reference to it's
replacement text (initially empty if not specified). At page output time
any fixup markers in the document are replaced by this scalar.

The initial content can also be a code reference which will be evaluated
at page output time.

=item $ref = insert_fixup [$initial_content]

Similar to C<fixup_marker>, but inserts the marker into the current output stream.

=cut

sub fixup_marker {
   push @fixup, $_[0];
   (
      (sprintf "\x{fc00}%06d", $#fixup),
      \$fixup[-1],
   )
}

sub insert_fixup {
   my ($marker, $ref) = fixup_marker $_[0];
   $PApp::output .= $marker;
   $ref
}

=item sform [\%attrs,] [module,] arg => value, ...

=item cform [\%attrs,] [module,] arg => value, ...

=item multipart_form [\%attrs,], [module,] arg => value, ...

=item endform

Forms Support

These functions return a <form> or </form>-Tag. C<sform> ("simple form")
takes the same arguments as C<surl> and return a <form>-Tag with a
GET-Method.  C<cform> ("complex form") does the same, but sets method to
POST. Finally, C<multipart_form> is the same as C<cform>, but sets the
encoding-type to "multipart/form-data". The latter data is I<not> parsed
by PApp, you will have to call parse_multipart_form (see below)
when evaluating the form data.

All of these functions except endform accept an initial hashref with
additional attributes (see L<PApp::HTML>), e.g. to set the name attribute
of the generated form elements.

Endform returns a closing </form>-Tag, and I<must> be used to close forms
created via C<sform>/C<cform>/C<multipart_form>.

=cut

sub sform(@) {
   local $surlstyle = _SURL_STYLE_URL;
   tag "form", { ref $_[0] eq "HASH" ? %{+shift} : (), method => 'get', action => &surl };
}

sub cform(@) {
   tag "form", { ref $_[0] eq "HASH" ? %{+shift} : (), method => 'post', action => &surl };
}

sub multipart_form(@) {
   tag "form", { ref $_[0] eq "HASH" ? %{+shift} : (), method => 'post', action => &surl, enctype => "multipart/form-data" };
}

sub endform {
   "</form>";
}

=item parse_multipart_form \&callback;

Parses the form data that was encoded using the "multipart/form-data"
format. Returns true when form data was present, false otherwise.

For every parameter, the callback will be called with four
arguments: Handle, Name, Content-Type, Content-Type-Args,
Content-Disposition (the latter two arguments are hash-refs, with all keys
lowercased).

If the callback returns true, the remaining parameter-data (if any) is
skipped, and the next parameter is read. If the callback returns false,
the current parameter will be read and put into the C<%P> hash. This is a
no-op callback:

   sub my_callback {
      my ($fh, $name, $ct, $cta, $cd) = @_;
      my $data;
      read($fh, $data, 99999);
      if ($ct =~ /^text\/i) {
         my $charset = lc $cta->{charset};
         # do conversion of $data
      }
      (); # do not return true
   }

The Handle-object given to the callback function is actually an object of
type PApp::FormBuffer (see L<PApp::FormBuffer>). It will
not allow you to read more data than you are supposed to. Also, remember
that the C<READ>-Method will return a trailing CRLF even for data-files.

HINT: All strings (pathnames etc..) are probably in the charset specified
by C<$state{papp_lcs}>, but maybe not. In any case, they are octet
strings so watch out!

=cut

# parse a single mime-header (e.g. form-data; directory="pub"; charset=utf-8)
sub parse_mime_header {
   my $line = $_[0];
   $line =~ /([^ ()<>@,;:\\".[\]=]+)/g; # the tspecials from rfc1521, except /
   my @r = $1;
   no utf8; # devel7 has no polymorphic regexes
   use bytes; # these are octets!
   while ($line =~ /
            \G\s*;\s*
            (\w+)=
            (?:
             \"( (?:[^\\\015"]+|\\.)* )\"
             |
             ([^ ()<>@,;:\\".[\]]+)
            )
         /gxs) {
      push @r, lc $1;
      my $value = $2 || $3;
      # we dequote only the three characters that MUST be quoted, since
      # microsoft is obviously unable to correctly implement even mime headers:
      # filename="c:\xxx". *sigh*
      $value =~ s/\\([\015"\\])/$1/g;
      push @r, $value;
   }
   @r;
}

# see PApp::Handler near the end before deciding to call die in
# this function.
sub parse_multipart_form(&) {
   no utf8; # devel7 has no polymorphic regexes
   my $cb  = shift;
   my $ct = $request->header_in("Content-Type");
   $ct =~ m{^multipart/form-data} or return;
   $ct =~ m#boundary=\"?([^\";,]+)\"?#; #FIXME# should use parse_mime_header
   my $boundary = $1;
   my $fh = new PApp::FormBuffer
                fh => $request,
                boundary => $boundary,
                rsize => $request->header_in("Content-Length");

   $request->header_in("Content-Type", "");

   while ($fh->skip_boundary) {
      my ($ct, %ct, %cd);
      my $hdr = "";
      my $line;
      do {
	 $line = $fh->READLINE;
	 if ($line =~ /^\s/) {
	    $hdr .= $line;
	 } else {
	    if ($hdr =~ /^Content-Type:\s+(.*)$/i) {
	       ($ct, %ct) = parse_mime_header $1;
	    } elsif ($hdr =~ /^Content-Disposition:\s+(.*)/i) {
	       (undef, %cd) = parse_mime_header $1;
	       # ^^^ eq "form-data" or die ";-[";
	    }
	    $hdr = $line;
	 }
      } while ($line ne "");

      my $name = delete $cd{name};

      if (defined $name) {
         $ct ||= "text/plain";
         $ct{charset} ||= $state{papp_lcs} || "iso-8859-1";
         $cb->($fh, $name, $ct, \%ct, \%cd);

         # read (& skip) the remaining data, if any
         my $buf; 1 while $fh->read($buf, 16384) > 0;
      }
   }

   $request->header_in("Content-Length", 0);

   1;
}

=item PApp::flush [not exported by default]

Send generated output to the client and flush the output buffer. There is
no need to call this function unless you have a long-running operation
and want to partially output the page. Please note, however, that, as
headers have to be output on the first call, no headers (this includes the
content-type and character set) can be changed after this call. Also, you
must not change any state variables or any related info after this call,
as the result might not get saved in the database, so you better commit
everything before flushing and then just continue output (use GET or POST
to create new links after this).

Flushing does not yet harmonize with output stylesheet processing, for the
semi-obvious reason that PApp::XSLT does not support streaming operation.

BUGS: No links that have been output so far can be followed until the
document is finished, because the neccessary information will not reach
the disk until the document.... is finished ;)

=cut

sub _unicode_to_entity {
   sprintf "&#x%x;", $_[0];
}

sub flush_cvt {
   if (@fixup) {
      my @fixup = map { (ref) ? &$_ : $_ } @fixup;
      $$routput =~ s/\x{fc00}(......)/$fixup[$1]/sg;
   }

   # charset conversion
   if ($output_charset eq "*") {
      #d##FIXME#
      # do "output charset" negotiation, at the moment this is truely pathetic
#      if (utf8_downgrade $$routput, 1) {
#         $output_charset = "iso-8859-1";
#      } else {
         utf8_upgrade $$routput; # must be utf8 here, but why?
         $output_charset = "utf-8";
#      }
   } elsif ($output_charset) {
      # convert to destination charset
      if ($output_charset ne "iso-8859-1" || !utf8_downgrade $$routput, 1) {
         utf8_upgrade $$routput; # wether here or in pconv doesn't make much difference
         if ($output_charset ne "utf-8") {
            my $pconv = PApp::Recode::Pconv::open $output_charset, CHARSET, \&_unicode_to_entity
                           or fancydie "charset conversion to $output_charset not available";
            $$routput = PApp::Recode::Pconv::convert($pconv, $$routput);
         } # else utf-8 == transparent
      } # else iso-8859-1 == transparent
   } else {
      utf8_downgrade $$routput;
   }

   $state{papp_lcs} = $output_charset;
   $request->content_type($output_charset
                          ? "$content_type; charset=$output_charset"
                          : $content_type);
}

sub flush_snd {
   use bytes;

   $request->send_http_header unless $output_p++;
   # $routput should suffice in the next line, but it sometimes doesn't,
   # so just COPY THAT DAMNED THING UNTIL MODPERL WORKS. #d##FIXME#TODO#
   $request->print ($$routput) unless $request->header_only;

   $$routput = "";
}

sub flush {
   flush_cvt;
   local $| = 1;
   flush_snd;
}

sub flush_snd_length {
   use bytes;

   flush_cvt;
   $request->header_out('Content-Length', length $$routput);
   flush_snd;
}

=item PApp::set_output ($data) [not exported by default]

Clear the output so far and set it to C<data>. This only clears committed
output, not any partial output within C<capture> blocks.

=cut

sub set_output {
   $$routput = $_[0];
}

=item PApp::send_upcall BLOCK

Immediately stop processing of the current application and call BLOCK,
which is run outside the handler compartment and without state or other
goodies (like redirected STDOUT). It has to return one of the status codes
(e.g. &PApp::OK). Never returns.

If you want to output something in an upcall, try to use this sequence:

   PApp::send_upcall {
      content_type "text/html";
      $request->status ("401");
      $request->header_out ("WWW-Authenticate" => "Basic realm=\"$realm\"");
      PApp::set_output "...";
      PApp::flush;
   };

You should never need to call this function directly, rather use
C<internal_redirect> and other functions that use upcalls to do their
work.

=cut

sub send_upcall(&) {
   local $SIG{__DIE__};
   die bless $_[0], PApp::Upcall::;
}

=item redirect url

=item internal_redirect url

Immediately redirect to the given url. I<These functions do not
return!>. C<redirect_url> creates a http-302 (Page Moved) response,
changing the url the browser sees (and displays). C<internal_redirect>
redirects the request internally (in the web-server), which is faster, but
the browser might or might not see the url change.

=cut

sub internal_redirect {
   my $url = $_[0];
   send_upcall {
      # we have to get rid of the old request (think POST, and Apache->content)
      $request->method ("GET");
      $request->header_in ("Content-Type", "");
      $request->internal_redirect ($url);
      return &OK;
   };
}

sub _gen_external_redirect {
   my $url = $_[0];
   $request->status (302);
   $request->header_out (Location => $url);
   set_output "
<html>
<head><title>".__"page redirection"."</title></head>
<meta http-equiv=\"refresh\" content=\"0;URL=$url\">
</head>
<body text=\"black\" link=\"#1010C0\" vlink=\"#101080\" alink=\"red\" bgcolor=\"white\">
<large>
This page has moved to <tt>$url</tt>.<br />
<a href=\"$url\">
".__"The automatic redirection  has failed. Please try a <i>slightly</i> newer browser next time, and in the meantime <i>please</i> follow this link ;)"."
</a>
</large>
</body>
</html>
";
   eval { flush(1) };
   return &OK;
}

sub redirect {
   my $url = $_[0];
   send_upcall { _gen_external_redirect $url };
}

=item abort_to surl-args

Similar to C<internal_redirect>, but filters the arguments through
C<surl>. This is an easy way to switch to another module/webpage as a kind
of exception mechanism. For example:

 my ($name, ...) = sql_fetch "select ... from game where id = ", $S{gameid};
 abort_to "games_overview" unless defined $name;

This is used in the module showing game details. If it doesn't find the
game it just aborts to the overview page with the list of games.

=cut

sub abort_to {
   internal_redirect &surl;
}

=item abort_with BLOCK

Abort processing of all modules and execute BLOCK in an upcall (See
L<send_upcall> for limitations on the environment) and never return. This
function is handy when you are deeply nested inside a module stack but
want to output your own page (e.g. a file download). Example:

 abort_with {
    content_type "text/plain";
    echo "This is the only line ever output";
 };

=cut

sub abort_with(&) {
   local *output = $routput;
   &{$_[0]};
   send_upcall {
      flush(1);
      return &OK;
   }
}

=item PApp::abort_with_file *FH [, content-type]

Abort processing of the current module stack, set the content-type header
to the content-type given and sends the file given by *FH to the client.
No cleanup-handlers or similar functions will get called and the function
does of course not return. This function does I<not> call close on the
filehandle, so if you want to have the file closed after this function
does its job you should not leave references to the file around.

=cut

sub _send_file($$$) {
   my ($fh, $ct, $inclen) = @_;
   $request->content_type ($ct) if $ct;
   $request->header_out ('Content-Length' => $inclen + (-s _) - tell $fh) if -f $fh;
   $request->send_http_header;
   $request->send_fd ($fh) unless $request->header_only;
}

sub abort_with_file($;$) {
   my ($fh, $ct) = @_;
   send_upcall {
      _send_file ($fh, $ct, 0);
      return &OK;
   }
}

=item PApp::cookie $name

Returns an arrayref containing all cookies sent by the client of the given
name, or C<undef>, if no cookies of this name have been sent.

=cut

sub cookie($) {
   $temporary{cookie}{$_[0]}
}

=item PApp::add_cookie $key => $value, %param

Add a given cookie too be sent to the client.

The optional parameter "expires" should be specified as a unix timestamp,
if given. The optional parameter "secure" should be specified as C<undef>.

=cut

sub add_cookie($$;%) {
   my ($name, $value, %param) = @_;

   $value = "$name=$value";

   $param{expires} = unixtime2http ($param{expires}, "cookie")
      if exists $param{expires};

   while (my ($k, $v) = each %param) {
      $value .= ";$k";
      $value .= "=$v" if defined $v;
   }

   # most clients (including firefox) are broken and need separate set-cookie headers
   # this currently breaks PApp::CGI
   $request->headers_out->add ('Set-Cookie' => $value);
}

sub _set_cookie {
   add_cookie papp_1984 => (PApp::X64::enc $cipher_e->encrypt(pack "VVVV", $userid, 0, 0, $state{papp_cookie})),
      path    => "/",
      expires => $NOW + $cookie_expires;
}

sub _debugbox {
   my $r;

   my $pre1 = "<font color='black' size='3'><pre>";
   my $pre0 = "</pre></font>";

   $r .= "<h2>Status:</h2>$pre1\n",
   $r .= "UsSAS = ($userid,$prevstateid,$stateid,$alternative,$sessionid); location = $location;\n";
   $r .= "langs = $langs;\n";

   $r .= "$pre0<h3>Debug Output (dprint &amp; friends):</h3>$pre1\n";
   $r .= escape_html($doutput);

   $r .= "$pre0<h3>Input Parameters (%P):</h3>$pre1\n";
   $r .= escape_html(PApp::Util::dumpval(\%P));

   $r .= "$pre0<h3>Input Arguments (%arguments):</h3>$pre1\n";
   $r .= escape_html(PApp::Util::dumpval(\%arguments));

   $r .= "${pre0}<h3>Global State (%state):</h3>$pre1\n";
   $r .= escape_html(PApp::Util::dumpval(\%state));

   if (0) { # nicht im moment, nutzen sehr gering
   $r .= "$pre0<h3>Application Definition (%\$papp):</h3>$pre1\n";
   $r .= escape_html(PApp::Util::dumpval($papp,{
            #CB     => $papp->{cb}||{},
            #CB_SRC => $papp->{cb_src}||{},
         }));
   }

   $r .= "$pre0<h3>Apache->request:</h3>$pre1\n";
   $r .= escape_html($request->as_string);

   $r .= "$pre0\n";

   $r =~ s/&#0;/\\0/g; # escape binary zero
   $r;
}

=item debugbox

Create a small table with a single link "[switch debug mode
ON]". Following that link will enable debugigng mode, reload the current
page and display much more information (%state, %P, %$papp and the request
parameters). Useful for development. Combined with the admin package
(L<macro/admin>), you can do nice things like this in your page:

 #if admin_p
   <: debugbox :>
 #endif

=cut

sub debugbox {
   echo "<br /><table cellpadding='10' bgcolor='#e0e0e0' width='100%' align='center'><tr><td id='debugbox'><font size='6' face='Helvetica' color='black'>";
   if (0||$state{papp_debug}) {
      echo slink("[switch debug mode OFF]", "/papp_debug" => undef);
      echo _debugbox;
   } else {
      echo slink("[switch debug mode ON]", "/papp_debug" => 1);
   }
   echo "</font></td></tr></table>";
}

=item language_selector $translator [, $current_langid]

Create (and output) html code that allows the user to select one of the
languages reachable through the C<$translator>. If C<$current_langid> is
missing, uses $PApp::langs to select a suitable candidate.

This function is slightly out-of-place in the PApp module and might move
to a more appropriate place in the future.

Usually used like this:

   <:language_selector $papp_translator:>

If you want to build your own language selector, here's how:

   # iterate over all languages supported by this translator
   for my $lang ($translator->langs) {

      # translate the language id into the vernacular language name
      my $name = PApp::I18n::translate_langid($lang, $lang);

      if ($lang eq $current) {
         # this is the currently selected language...
         echo "[$name]";
      } else {
         # or a language we could switch to
         echo slink "[$name]", SURL_SET_LOCALE($lang);
      }

   }

=cut

sub language_selector {
   my $translator = shift;
   my $current = shift || $translator->get_table($langs)->lang;
   for my $lang ($translator->langs) {
      next if $lang eq "*" || lc $lang eq "mul";
      my $name = PApp::I18n::translate_langid($lang, $lang);
      if ($lang ne $current) {
         echo slink "[$name]", SURL_SET_LOCALE($lang);
      } else {
         echo "<b>[$name]</b>";
      }
   }
   
}

#############################################################################

=item reload_p

Return the count of reloads, i.e. the number of times this page
was reloaded (which means the session was forked).

This is a relatively costly operation (a database access), so do not do it
by default, but only when you need it.

=cut

sub reload_p {
   if ($prevstateid) {
      $st_reload_p->execute($prevstateid, $alternative);
      $st_reload_p->fetchrow_arrayref->[0]
   } else {
      0;
   }
}

=item getpref $key

Return the named user-preference variable (or undef, when the variable
does not exist) for the current application.

User preferences can be abused for other means, like timeout-based session
authenticitation. This works, because user preferences, unlike state
variables, change their values simultaneously in all sessions.

See also L<PApp::Prefs>.

=item setpref $key, $value

Set the named preference variable. If C<$value> is C<undef>, then the
variable will be deleted. You can pass in (serializable) references.

See also L<PApp::Prefs>.

=cut

sub getpref($) {
   $curprefs->get ($_[0])
}

sub setpref($;$) {
   $curprefs->set ($_[0], $_[1]);
}

# forcefully (re-)read the user-prefs and returns the "new-user" flag
# reads all user-preferences (no args) or only the preferences
# for the given path (argument is given)
sub load_prefs($) {
   if ($userid) {
      my $st = sql_exec $DBH, \my($prefs),
                        "select value from prefs where uid = ? and path = ? and name = 'papp_prefs'",
                        $userid, $_[0];
      if ($st->fetch) {
         $prefs &&= PApp::Storable::thaw decompress $prefs;

         my $h = $_[0] ? $state{$_[0]} : \%state;
         @$h{keys %$prefs} = values %$prefs;

         return 0;
      } else {
         return 1;
      }
   }
}

=item save_prefs

Save the preferences for all currently loaded applications.

=cut

sub save_prefs {
   my %prefs;
   my $userid = getuid;

   while (my ($path, $keys) = each %preferences) {
      next if $path && !exists $state{$path};
      
      my $h = $path ? $state{$path} : \%state;
      $prefs{$path} = { map { $_ => $h->{$_} } grep { defined $h->{$_} } @$keys };
   }

   while (my ($path, $keys) = each %prefs) {
      if (%$keys) {
         $st_replacepref->execute($userid, $path, "papp_prefs", 
                                  compress PApp::Storable::nfreeze($keys));
      } else {
         $st_deletepref->execute($uid, $path, "papp_prefs");
                        $userid, $path, "papp_prefs";
      }
   }
}

sub start_session {
   ($sessionid, $prevstateid, $alternative) = ($stateid, 0, 0);
}

=item switch_userid $newuserid

Switch the current session to a new userid. This is useful, for example,
when you do your own user accounting and want a user to log-in. The new
userid must exist, or bad things will happen, with the exception of userid
zero, which sets the current user to the anonymous user (userid zero)
without changing anything else.

=cut

sub switch_userid {
   if ($userid != $_[0]) {
      $userid = $_[0];

      if ($userid) {
         load_prefs "";
         for (keys %preferences) {
            load_prefs $_ if exists $state{$_};
         }
      }

      $state{papp_switch_newuserid} = $_[0];
      $state{papp_cookie} = 0; # unconditionally re-set the cookie
   }
}

=item $userid = PApp::newuid

Create a new (anonymous) user id.

=item $userid = getuid

Return a user id, allocating it if necessary (i.e. if the user has no
unique id so far). This can be used to force usertracking, just call
C<getuid> in your C<newuser>-callback. See also C<$userid> to get the
current userid (which might be zero).

=cut

sub newuid() {
   $st_newuserid->execute;
   return sql_insertid $st_newuserid;
}

sub getuid() {
   $userid ||= do {
      switch_userid newuid;
      $userid;
   }
}

sub update_state {
   %arguments = ();

   $st_insertstate->execute($stateid,
                            compress PApp::Storable::mstore(\%state),
                            $userid, $prevstateid, $sessionid, $alternative)
      if @{$state{papp_alternative}};

   &_destroy_state; # %P = %state = (), but in a safe way
   undef $stateid;
}

################################################################################################

sub warnhandler {
   my $msg = $_[0];
   PApp->warn ("Warning[$$]: $msg");
}

sub PApp::Base::warn {
   if ($request) {
      (my $msg = $_[1]) =~ s/\n$//;
      $request->warn ($msg);
      $warn_log .= "$msg\n";
   } else {
      print STDERR $_[1];
   }
};

=item PApp::config_eval BLOCK

Evaluate the block and call PApp->config_error if an error occurs. This
function should be used to wrap any perl sections that should NOT keep
the server from starting when an error is found during configuration
(e.g. Apache <Perl>-Sections or the configuration block in CGI
scripts). PApp->config_error is overwritten by the interface module and
should usually do the right thing.

=cut

our $eval_level = 0;

sub config_eval(&) {
   if (!$eval_level) {
      local $eval_level = 1;
      local $SIG{__DIE__} = \&PApp::Exception::diehandler;
      my $retval = eval { &{$_[0]} };
      config_error PApp $@->as_string if $@;
      return $retval;
   } else {
      return &{$_[0]};
   }
}

my %app_cache;

# find app by mountid or name
sub load_app($$) {
   my $class = shift;
   my $appid_or_name = shift;

   return $app_cache{$appid_or_name} if exists $app_cache{$appid_or_name};

   my $st = sql_exec DBH,
                     \my($appid, $name, $path, $mountconfig, $config),
                     "select id, name, path, mountconfig, config from app
                      where "
                      . ($appid_or_name+0 eq $appid_or_name ? "id =" : "name like")
                      . " ?", "$appid_or_name"; #D#D "" workaround for DBD::mysql
   $st->fetch or fancydie "load_app: no such application", "appid => $appid_or_name";

   my %config = eval $config;

   $@ and fancydie "error while evaluating config for [appid=$appid]", $@,
      info => [path => $path],
      info => [name => $name],
      info => [appid => $appid],
      info => [config => PApp::Util::format_source $_config];

   my $class;

   if ($path =~ /^(PApp::[^\/]+)(.*)$/) {
      $class = $1;
      $path = $2;
   } else {
      fancydie "PApp::Application::PApp is no longer supported, downgrade to PApp 1.x";
   }

   $app_cache{$appid} =
   $app_cache{$name} = new $class
      delayed	         => 1,
      mountconfig	 => $mountconfig,
      url_prefix_nossl   => $url_prefix_nossl,
      url_prefix_ssl     => $url_prefix_ssl,
      url_prefix_sslauth => $url_prefix_sslauth,
      %config,
      appid		 => $appid,
      path		 => $path,
      name		 => $name;
}

sub PApp::Base::mount_appset {
   my $self = shift;
   my $appset = shift;
   my @apps;

   config_eval {
      my $setid = sql_fetch DBH, "select id from appset where name like ?", $appset;
      $setid or fancydie "$appset: unable to mount nonexistant appset";
   };

   my $st = sql_exec
               DBH,
               \my($id),
               "select app.id from app, appset where app.appset = appset.id and appset.name = ?",
               $appset;

   while ($st->fetch) {
      config_eval {
         my $papp = PApp->load_app($id);
         PApp->mount($papp);
         push @apps, $papp;
      }
   }
   @apps;
}

sub PApp::Base::mount_app {
   my $self = shift;
   my $app = shift;
   my $id;

   config_eval {
      $id = sql_fetch DBH, "select id from app where name like ?", $app;
      $id or fancydie "$app: unable to mount nonexistant application $id";

      $app = PApp->load_app($id);
      PApp->mount($app);
   };

   $app;
}

sub PApp::Base::mount {
   my $self = shift;
   my $papp = shift;

   my %arg = @_;

   $papp{$papp->{appid}} = $papp;

   $papp->mount;

   $papp->load unless $arg{delayed} || $PApp::delayed;
}

sub list_apps() {
   keys %papp;
}

sub handle_error($) {
   my $exc = $_[0];

   UNIVERSAL::isa $exc, PApp::Exception::
      or $exc = new PApp::Exception error => 'Script evaluation error',
                                    info => [$exc];
   $exc->errorpage;
   $request->status(500);
   eval { update_state };
   eval { flush_cvt };
   if ($request) {
      $request->log_reason ($exc, $request->filename);
   } else {
      print STDERR $exc;
   }
}

# return a new stateid, pool stateids a bit
{
   my ($id1, $id2);

   sub newstateid {
      if ($id1 == $id2) {
         $st_newstateids->execute(16);
         $id1 = sql_insertid $st_newstateids;
         $id2 = $id1 + 16;
      }
      $id1++;
   }
}

my $last_bench;
sub bench {
   my $n = Time::HiRes::time;
   if ($NOW <= $last_bench && @_) {
      warn "($_[0]): " . ($n - $last_bench);
   }
   $last_bench = $n;
}

################################################################################################
#
#   the PApp request handler
#
# on input, $location, $pathinfo, $request and $papp must be preset
#
sub _handler {
   # for debugging only, maybe?
   local $SIG{QUIT} = sub { Carp::confess "SIGQUIT" };

   $NOW = time;

   undef $stateid;

   defined $logfile and open (local *STDERR, ">>", $logfile);

   $output = "";
   $output_p = 0;
   $doutput = "";
   @fixup = ();
   tie *STDOUT, "PApp::Catch_STDOUT";
   $content_type = "text/html";
   $output_charset = "*";
   $warn_log = "";

   local %temporary;

   eval {
      local $SIG{__DIE__}  = \&PApp::Exception::diehandler;
      local $SIG{__WARN__} = \&warnhandler;

      local $PApp::SQL::Database = $PApp::Config::Database;
      local $PApp::SQL::DBH      = $DBH = DBH;

      %P = %arguments = ();
      _set_params PApp::HTML::parse_params $request->query_string;
      _set_params PApp::HTML::parse_params $request->content
         if $request->header_in("Content-Type") eq "application/x-www-form-urlencoded";

      my $state =
            delete $P{papp}
            || ($pathinfo =~ s%/([\-.a-zA-Z0-9]{22,22})$%% && $1);

      if ($state) {
         ($userid, $prevstateid, $alternative, $sessionid) =
            unpack "VVVxxxx", $cipher_d->decrypt(PApp::X64::dec $state);

         $st_fetchstate->execute($prevstateid);
         $state = $st_fetchstate->fetchrow_arrayref;
      } else {
         $st_eventcount->execute;
         $state = $st_eventcount->fetchrow_arrayref;
      }

      $stateid = newstateid;

      PApp::Event::handle_events ($state->[0])
         if $event_count != $state->[0];

      if (defined (my $cookie = $request->header_in ('Cookie'))) {
         # parse NAME=VALUE
         my @kv;

         for ($cookie) {
            while (/\G\s* ([^=;,[:space:]]+) (?: \s*=\s* (?: "( (?:[^\\"]+ | \\.)*)" | ([^;,[:space:]]*) ) )?/gcxs) {
               my $name = $1;
               my $value = $3;

               unless (defined $value) {
                  # also catches $2=$3=undef
                  $value = $2;
                  $value =~ s/\\(.)/$1/gs;
               }

               push @{$temporary{cookie}{lc $name}}, $value;

               last unless /\G\s*;/gc;
            }
         }
      }

      if (defined $state->[1]) {
         $stateid = newstateid;

         $sessionid = $state->[4];

         *state = PApp::Storable::mretrieve decompress $state->[1];

         if ($state->[2] != $userid) {
            if ($state->[2] != $state{papp_switch_newuserid}) {
               fancydie "user id mismatch ($state->[2] <> $state{papp_switch_newuserid}", "maybe someone is tampering?";
            } else {
               $userid = $state{papp_switch_newuserid};
            }
         }
         delete $state{papp_switch_newuserid};

         set_alternative $state{papp_alternative}[$alternative];

#         $papp = $papp{$state{papp_appid}}
#                 or fancydie "Application not mounted", $location,
#                             info => [appid => $state{papp_appid}];

      } else {
         start_session;

#         $state{papp_appid} = $papp->{appid};

         #$modules = $pathinfo =~ m%/(.*?)/?$% ? modpath_thaw $1 : {}; #d#

         if ($temporary{cookie}{papp_1984}[0] =~ /^([0-9a-zA-Z.-]{22,22})$/) {
            ($userid, undef, undef, $state{papp_cookie}) = unpack "VVVV", $cipher_d->decrypt(PApp::X64::dec $1);
            load_prefs "";
         } else {
            $userid = 0;
         }
      }
      $state{papp_alternative} = [];

      $langs = $state{papp_lcs};
      if ($langs eq "utf-8") {
         # force utf8 on
         for (keys %P) {
            utf8_on $_ for ref $P{$_} ? @{$P{$_}} : $P{$_};
         }
      } elsif ($langs !~ /^(?:|ascii|us-ascii|iso-8859-1)$/i) {
         my $pconv = PApp::Recode::Pconv::open CHARSET, $langs
                        or fancydie "charset conversion from $langs not available";
         for (keys %P) {
            $_ = utf8_on $pconv->convert_fresh($_) for ref $P{$_} ? @{$P{$_}} : $P{$_};
         }
      }

      $langs = "$state{papp_locale},".$request->header_in("Content-Language").",en";

      $papp->check_deps if $checkdeps;

      # do not use for, as papp_execonce might actually grow during
      # execution of these callbacks.
      while (@{$state{papp_execonce}}) {
         eval {
            (shift @{$state{papp_execonce}})->() while @{$state{papp_execonce}};
            1;
         } or (UNIVERSAL::isa $@, PApp::Upcall:: and die)
           or $papp->uncaught_exception ($@, 1);
      }
      delete $state{papp_execonce};

      if ($state{papp_cookie} < $NOW - $cookie_reset) {
         $state{papp_cookie} = $NOW;
         _set_cookie;
      }

      eval { $papp->run; 1; }
         or (UNIVERSAL::isa $@, PApp::Upcall:: and die)
         or $papp->uncaught_exception ($@, 0);

      flush_cvt;

      update_state;
      undef $stateid;

      1;
   } or do {
      delete $state{papp_execonce};

      if (UNIVERSAL::isa $@, PApp::Upcall::) {
         my $upcall = $@;
         eval { update_state };
         untie *STDOUT; open STDOUT, ">&1";
         return &$upcall;
      } else {
         handle_error $@;
      }
   };

   untie *STDOUT; open STDOUT, ">&1";

   flush_snd_length;

   # now eat what the browser sent us (might give locking problems, but
   # that's not our bug).
   parse_multipart_form {} if $request->header_in("Content-Type") =~ m{^multipart/form-data};

   undef $request; # preserve memory

   return &OK;
}

sub PApp::Catch_STDOUT::TIEHANDLE {
   bless \(my $unused), shift;
}

sub PApp::Catch_STDOUT::PRINT {
   shift;
   $output .= join "", @_;
   1;
}

sub PApp::Catch_STDOUT::PRINTF {
   shift;
   $output .= sprintf(shift,@_);
   1;
}

sub PApp::Catch_STDOUT::WRITE {
   my ($self, $data, $length) = @_;
   $output .= $data;
   $length;
}

1;

=back

=head1 SEE ALSO

The C<macro/admin>-package in the distribution, the demo-applications
(.papp-files).

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

