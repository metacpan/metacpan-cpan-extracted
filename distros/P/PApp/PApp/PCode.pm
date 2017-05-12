##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::PCode - PCode compiler/decompiler and various other utility functions.

=head1 SYNOPSIS

   use PApp::PCode;

   eval pcode2perl perl2pcode "pcode";
   eval pcode2perl pxml2pcode "pcode";
   eval pcode2perl xml2pcode "pcode";

=head1 DESCRIPTION

PApp stores a lot of things in pcode format, which is simply an escaping
mechanism to store pxml/xml/html/perl sections inside a single data
structure that can be efficiently converted to pxml or perl code.

You will rarely if ever need to use this module directly.

=over 4

=cut

package PApp::PCode;

use Carp;
use Convert::Scalar ':utf8';
use Encode ();

use PApp::Exception;

use base 'Exporter';

no bytes;
use utf8;

use common::sense;

our $VERSION = 2.1;
our @EXPORT_OK = qw(pxml2pcode xml2pcode perl2pcode pcode2pxml pcode2perl);

=item pxml2pcode "phtml or pxml code"

Protect the contents of the phtml or pxml string (xml with embedded perl
sections), i.e. make it an xml-parseable-document by resolving all E<lt>: and
E<lt>? sections.

The following four mode-switches are allowed, the initial mode is ":>"
(i.e. non-interpolated html/xml). You can force the initial mode to ":>"
by prefixing the string with "E<lt>:?>".

 <:	start verbatim perl section ("perl-mode")
 :>	start plain string section (non-interpolated string)
 <?	start perl expression (single expr, result will be interpolated)
 ?>	illegal(!) (was deprecated before)

INTERNATIONALISATION (__"xxx")

Within plain and interpolated string sections you can also use the
__I<>"string" construct to mark (and map) internationalized text. The
construct must be used verbatim: two underlines, one double-quote, text,
and a trailing double-quote. For more complex uses, just escape to perl
(e.g. <?__I<>"xxx":>).

PREPROCESSOR COMMANDS ("#if...")

In string sections (and only there!), you can also use preprocessor
commands (the C<#> must be at the beginning of the line, between the C<#>
and the command name can be any amount of white space, just like in C!)

 #if any_perl_condition
   any phtml code
 #elsif any_perl_conditon
   ...
 #else
   ...
 #endif

Preprocessor-commands are ignored at the very beginning of a string
section (that is, they must follow a linebreak). They are I<completely>
removed on output (i.e. the linebreak before and after it will not be
reflected in the output).

White space will be mostly preserved (especially line-number and
-ordering).

CALLBACKS ("{: xxx :}(args)")

Within perl sections, one can automatically create PApp::Callback
objects by enclosing code in C<{:> and C<:}> pairs. This creates a
PApp::Callback object from the enclosed code fragment. A refer will be
created automatically If the closing bracket is followed by an opening
parenthesis, e.g.:

 # callback object alone
 my $cb = {: print "hallo" :};

 # callback & refer
 surl {: warn "called with $_[0]" :}(55);

Implementation: a callback of the form "{:code:}(args)" will be compiled
like this (which might change anytime).

 +do {
    BEGIN {
       $_some_global_var = {{register_function}} sub { {{callback_preamble}} code }, name => "hash";
       # hash is a hash of the code, i.e. code changes => callback changes.
    }
    $_some_global_var
 }->({{argument_preamble}}arguments)

An experimental facility (a.k.a. hack and subject to change!) to overwrite all parts marked as
C<{{}}> is available:  The global variable

   $PApp::PCode::register_callback

contains a hash with strings for all marked parts of a callback.  Remember
that the function is being called when the code is eval'ed. A valid trick
to pass extra context information is to store something like C<funcname
5,6,> as the callback name.

=item xml2pcode "string"

Convert the string into pcode without interpreting it.

=item perl2pcode "perl source"

Protect the given perl sourcecode, i.e. convert it in a similar way as
C<pxml_to_pcode>, registering any callbacks it sees.

=item pcode2perl $pcode

Convert the protected xml/perl code into vanilla perl that can be
eval'ed. The result will have the same number of lines (in the same order)
as the original perl or xml source (important for error reporting).

=cut

# just quote all xml-active characters into almost-quoted-printable
sub _quote_perl($) {
   join "\012",
      map +(unpack "H*", $_),
         split /\015?\012/, (Encode::encode_utf8 $_[0]), -1
}

# be liberal in what you accept, stylesheet processing might
# gar|ble our nice line-endings
sub _unquote_perl($) {
   utf8_on
      join "\n",
         map +(pack "H*", $_),
            split /[ \011\012\015]/, $_[0], -1;
}

our $register_callback = {
   register_function => "register_callback",
   callback_preamble => "",
   argument_preamble => "",
};

sub __compile_cb {
   my ($cb, $hasargs) = @_;

   require Digest::SHA1;
   require PApp::Callback;

   # SHA1 downgrades, so we upgrade and turn off the utf8 flag temporarily.
   utf8_upgrade $cb;
   utf8_off $cb;
   my $hash = Digest::SHA1::sha1_hex($cb);
   utf8_on $cb;

   if ($hasargs) {
      $hasargs = $register_callback->{argument_preamble} ? "->($register_callback->{argument_preamble}," : "->(";
   } else {
      $hasargs = $register_callback->{argument_preamble} ? "->append($register_callback->{argument_preamble})" : "";
   }

   "+do{our \$papp_pcode_cb_$hash;BEGIN{\$papp_pcode_cb_$hash=$register_callback->{register_function} "
   . "sub{use strict 'vars';$register_callback->{callback_preamble}$cb},name=>'$hash'}\$papp_pcode_cb_$hash}$hasargs";
}


sub _register_callbacks($) {
   local $_ = $_[0];
   s/\{: ( (?:[^:]+|:[^}])* ) :\}\s*(\()?/__compile_cb "$1", $2 eq "("/gex;
   $_;
}

my ($dx, $dy, $dq);
BEGIN {
   if ($] < 5.007) {
      die "perl 5.7 is required for this part, see the sourcecode at the point of this error to find out more";
   }
   # we use some characters in the compatibility zone,
   # namely the character block 0xfce0-0xfcef
   ($dx, $dy, $dq) = (
	"\x{fce0}",   # usually means start of non-interpolated string/code
	"\x{fce1}",   # usually means start of interpolated code (formerly string, too)
	"\x{fce2}",   # usually used as a quoting character (similar to \ in strings)
   );
}

# pcode  := string tail | EMPTY
# tail   := code pcode | EMPTY
# string := ( $dx | $dy ) $dq-quotedstring
# code   := ( $dx | $dy ) hex-quotedcode

sub pxml2pcode($) {
   my $data = ":>" . shift;
   my $res = "";#d#
   my $mode;

   utf8_upgrade $data; # force utf-8-encoding

   for(;;) {
      # STRING
      $res .= $dx;
      # perl 5.8.x recursion bug: the extra [^<]* bug works around this effectively
      #        /\G([:?])>((?:[^<]+|<[^:?])*)/xgcs or last;
      $data =~ /\G([:?])>((?:[^<]+|<[^:?][^<]*)*)/xgcs or last;
      $mode = $1 eq ":" ? $dx : $dy; # for ?>
      warn "?> is not a legal pxml modifier anymore, will treat it as :>" if $1 eq "?";

      # do preprocessor commands, __""-processing and quoting
      for (my $src = $2) {
         for (;;) {
            m/\G(?:\n|\A)#\s*if[\t\ ]+([^\n]*)/gcm	and ($res .= "$dx\n" . (_quote_perl "if ($1) {") . "$2$dx"), redo;
            m/\G\n#\s*els?if[\t\ ]+([^\n]*)/gcm		and ($res .= "$dx\n" . (_quote_perl "} elsif ($1) {") . "$2$dx"), redo;
            m/\G\n#\s*else[\t\ ]*/gcm			and ($res .= "$dx\n" . (_quote_perl "} else {") . "$1$dx"), redo;
            m/\G\n#\s*endif[\t\ ]*/gcm			and ($res .= "$dx\n" . (_quote_perl "}") . "$1$dx"), redo;
            m/\G\x5f\x5f"((?:(?:[^"\\]+|\\.)*))"/gcs	and ($res .= $dy . (_quote_perl "gettext q\"$1\"") . $dx), redo; # __
            m/\G([$dx$dy$dq])/gco			and ($res .= "$dq$1"), redo;
            $mode eq $dy && m/\G([\$\@])/gcs		and ($res .= "$dx$dy$1"), redo; #d#
            m/\G(.[^_$dx$dy$dq\$\@\n]*)/gcso		and ($res .= $1), redo;
            last;
         }
      }

      # CODE
      $data =~ /\G<([:?])((?:[^:?]+|[:?][^>])*)/gcs or last;
      $res .= $1 eq ":" ? $dx : $dy;
      $res .= _quote_perl _register_callbacks $2;

   }
   $data !~ /\G(.{1,20})/gcs or croak "trailing characters in pxml string ($1)";
   #PApp::Util::sv_dump $res if $res =~ /3/;#d#
   substr $res, 1
}

sub perl2pcode($) {
   $dx . (_quote_perl _register_callbacks shift) . $dx;
}

sub xml2pcode($) {
   my $data = shift;
   $data =~ s/([$dx$dy$dq])/$dq$1/go;
   $data;
}

sub pcode2perl($) {
   my $pcode = $dx . $_[0];
   my ($mode, $src);
   my $res = "";#d#

   for (;;) {
      # STRING
      $pcode =~ /\G([$dx$dy])((?:[^$dx$dy$dq]+|$dq [$dx$dy$dq])*)/xgcso or last;
      ($mode, $src) = ($1, $2);
      $src =~ s/$dq(.)/$1/g;
      if ($src ne "") {
         #$mode = $mode eq $dx ? '' : 'qq'; # allow ?>
         $src =~ s/\\/\\\\/g; $src =~ s/'/\\'/g;
         $res .= "\$PApp::output .= '$src';";
      }

      # CODE
      $pcode =~ /\G([$dx$dy])([0-9a-f \010\012\015]*)/gcso or last;
      ($mode, $src) = ($1, $2);
      $src = _unquote_perl $src;
      if ($src !~ /^[ \t]*$/) {
         if ($mode eq $dy) {
            $src =~ s/;\s*$//; # remove a single trailing ";"
            $src = "do { $src }" if $src =~ /;/; # wrap multiple statements into do {} blocks
            $res .= "\$PApp::output .= ($src);";
         } else {
            $res .= "$src;";
         }
      }
   }
   $pcode !~ /\G(.{1,20})/gcs or die "internal error: trailing characters in pcode-string ($1)";
   $res;
}

# mostly for debugging
sub pcode2pxml($) {
   my $pcode = $dx . shift;
   my ($mode, $src);
   my $res = "";#d#
   for (;;) {
      # STRING
      $pcode =~ /\G([$dx$dy])((?:[^$dx$dy$dq]+|$dq [$dx$dy$dq])*)/xgcso or last;
      ($mode, $src) = ($1, $2);
      $src =~ s/$dq(.)/$1/g;
      $res .= $mode eq $dx ? ":>" : "?>";
      $res .= $src;

      # CODE
      $pcode =~ /\G([$dx$dy])([0-9a-f \010\012\015]*)/gcso or last;
      ($mode, $src) = ($1, $2);
      $src = _unquote_perl $src;
      $res .= $mode eq $dx ? "<:" : "<?";
      $res .= $src;
   }
   $pcode !~ /\G(.{1,20})/gcs or die "internal error: trailing characters in pcode-string ($1)";
   $res = substr $res, 2;
   #$res =~ s/:><://g; # illegal(!)#d#
   $res;
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

