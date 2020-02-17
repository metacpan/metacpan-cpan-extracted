##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::XML - pxml sections and more

=head1 SYNOPSIS

 use PApp::XML;

=head1 DESCRIPTION

Apart from providing XML convinience functions, the PApp::XML module
manages XML templates containing pappxml directives and perl code similar
to phtml sections. Together with stylesheets (L<PApp::XSLT>) this can be
used to almost totally seperate content from layout. Image a database
containing XML documents with customized tags.  A stylesheet can then be
used to transform this XML document into html + special pappxml directives
that can be used to create links etc...

=cut

package PApp::XML;

use Convert::Scalar ':utf8';

use PApp::Util;
use PApp::Exception qw(fancydie);

use base 'Exporter';

$VERSION = 2.2;
@EXPORT_OK = qw(
      xml_quote xml_attr xml_unquote xml_tag xml_cdata
      xml_check xml_encoding xml2utf8 pod2xml
      xml_include expand_pi xml_errorparser
);

=head2 Functions for XML-Generation

=over 4

=item xml_quote $string

Quotes (and returns) the given string so that it's contents won't be
interpreted by an XML parser (quotes ', ", <, & and > to avoid ]]>). Example:

   print xml_quote q( <xx> & <[[]]> );
   => &lt;xx> &amp; &lt;[[]]&gt;

=item xml_cdata $string

Does the same thing as C<xml_quote>, but using CDATA constructs, rather
than quoting individual characters. Example:

   print xml_cdata q(hi ]]> there);
   => <![CDATA[hi ]]]]><![CDATA[> there ]]>

=item xml_unquote $string

Unquotes (and returns) an XML string (by resolving it's entities and
CDATA sections). Currently, only the named predefined xml entities and
numerical character entities are resolved. Everything else is silently
ignored. Example:

   print xml_unquote q( <![CDATA[text1]]> &amp; text2&#x21; );
   => text1 & text2!

=item xml_attr $attr => $value [, $attr2 => $value2, ...]

Returns fully quoted $attr => $value pairs. Example:

   print xml_attr authors => q(Alan Cox & Linus "kubys" Torvalds);
   => authors="Alan Cox & Linus &quot;kubys&quot; Torvalds"

=item xml_tag $element_name, [$attr => $value, ...] [, $content_or_undef]

Generates a tag from the given element name, content and attribute
name => value pairs. If content is undef, an empty tag will be
generated. Example:

   print xml_tag "p", align => "center"
   => <p align="center"/>

As a very special courtesy hack for you, if you omit the content argument
entirely, only an opening tag will be generated.

=cut

sub xml_quote {
   local $_ = shift;
   s/&/&amp;/g;
   s/</&lt;/g;
   s/>/&gt;/g;
   #s/]]>/]]&gt;/g; # avoids problems when ]] and > are quoted in seperate calls
   $_;
}

sub xml_cdata {
   local $_ = shift;
   s/]]>/]]]]><![CDATA[>/g;
   "<![CDATA[$_]]>";
}
sub xml_attr {
   my $attrs;
   for (my $i = 0; $i < $#_; $i += 2) {
      local $_ = $_[$i+1];
      s/&/&amp;/g;
      s/"/&quot;/g;
      s/</&lt;/g;
      $attrs .= " $_[$i]=\"$_\"";
   }
   substr $attrs, 1;
}

sub xml_tag {
   my $element = shift;
   my $tag = "<$element";
   $tag .= " ".&xml_attr if @_ > 1;
   if (@_ & 1) {
      if (defined $_[-1]) {
         "$tag>$_[-1]</$element>";
      } else {
         "$tag/>";
      }
   } else {
      "$tag>";
   }
}

sub xml_unquote($) {
   local $_ = shift;
   s{&([^;]+);|<!\[CDATA\[(.*?)]]>}{
      if (defined $2) {
         $2;
      } elsif ("#" eq substr $1, 0, 1) {
         if ("x" eq substr $1, 1, 1) {
            chr hex substr $1, 2;
         } else {
            chr substr $1,1;
         }
      } else {
        { gt => '>', lt => '<', amp => '&', quot => '"', apos => "'" }->{$1}
      }
   }ge;
   $_;
}

=back

=head2 Functions for Analyzing XML

=over 4

=item ($msg, $line, $col, $byte) = xml_check $string [, $prolog, $epilog]

Checks wether the given document is well-formed (as opposed to
valid). This merely tries to parse the string as an xml-document. Nothing
is returned if the document is well-formed.

Otherwise it returns the error message, line (one-based), column
(zero-based) and character-position (zero-based) of the point the error
occured.

The optional argument C<$prolog> is prepended to the string, while
C<$epilog> is appended (i.e. the document is "$prolog$string$epilog"). The
cool thing is that the epilog/prolog strings are not counted in the error
position (and yes, they should be free of any errors!).

(Hint: Remember to utf8_upgrade before calling this function or make sure
that an encoding is given in the xml declaration).

=cut

sub xml_check {
   my ($string, $prolog, $epilog) = @_;

   require XML::Parser::Expat;

   my $parser = new XML::Parser::Expat;

   $prolog =~ s/\n//;
   $epilog =~ s/\n//;

   $string = "$prolog\n$string$epilog";

   eval {
      local $SIG{__DIE__};
      $parser->parsestring($string);
   };
   my $err = $@;

   $parser->release;

   return () unless $err;

   $err =~ /^\n(.*?) at line (\d+), column (\d+), byte (\d+)/
      or die "unparseable xml error message: $err";
   ($1, $2 - 1, $3, ($4 <= length $string - length $epilog ? $4 - 1 - length $prolog : (length $string) - (length $prolog) - (length $epilog) - 1));
}

=item xml_errorparser $xml, [$offset, $message]

This function takes a slightly damaged XML document or fragment and tries
to repair it. During this process it annotates many errors with error
messages in <error>-elements. It also offers the option of adding a
custom error message around the specified offste in the file.

This function currently works best with HTML or HTML-like input, and
tries very hard not to place error messages at places where they won't be
visible.

The result should be parseable by XML parsers, but be warned that not
every case will be fixed.

=cut

my %delay_error = (
   script => 1,
   style  => 1,
   head   => 1,
   input  => 1,
   select => 1,
   option => 1,
   applet => 1,
   frame  => 1,
   h1     => 0,
   h2     => 0,
   table  => 0,
   tr     => 0,
);
%delay_error = ();

sub xml_errorparser {
   require HTML::Parser;

   # fix any invalid xml-"names"
   my $xmlname = sub {
      local $_ = $_[0];
      s/([^:]*):([^:]*):/$1:$2_illegal-colon-in-name_/g;
      s/^([^\p{Letter}_:])/"illegal-xml-start-character_" . (ord $1)/e;
      s/([^\p{Letter}\p{Digit}\-_.:])/"_illegal-character-" . (ord $1) . "-in-name_"/ge;
      $_;
   };

   my ($xml, $errofs, $errmsg) = @_;

   defined $errofs or $errofs = 1e99;

   my $output = "";
   my $delayed;

   my @tag; # open elements

   my $err = sub {
      $delayed .= $_[0] if @_;
      return if exists $delay_error{$tag[-1]};
      for (my $i = @tag; --$i >= 0; ) {
         return if $delay_error{$tag[$i]};
      }
      $output .= $delayed;
      $delayed = "";
   };

   $xml =~ s%
      ([\x{0}-\x{8}\x{b}\x{c}\x{e}-\x{1f}\x{fffe}])
   %
      "illegal-character-" . (ord $1) . "-skipped";
   %gex;

   # HTML::Parser can't cope with unicode :(, unfortunately
   # this destroys position information quite severly
   utf8_upgrade $xml;
   $xml = (utf8_to PApp::Recode "iso-8859-1", \&PApp::_unicode_to_entity)->($xml);
   utf8_downgrade $xml;

   my $parser = new HTML::Parser
         api_version	=> 3,
         strict_names	=> 1,
         xml_mode	=> 1,
         unbroken_text	=> 1,
         case_sensitive	=> 1,
         ignore_elements=> [qw(script)],
         
         text_h		=> [sub {
            if ($_[1] >= $errofs) {
               $err->("<error>$errmsg, source<pre>\n"
                      . (xml_cdata substr $xml, $errofs >= 160 ? $errofs - 160 : 0, $errofs >= 160 ? 160 : $errofs)
                      . "&#xf7;"
                      . (xml_cdata substr $xml, $errofs, 160)
                      . "\n</pre></error>");
               $errofs = 1e99;
            } else {
               $delayed and $err->();
            }
            $output .= PApp::XML::xml_quote $_[0];
         }, "dtext, offset"],
         start_h	=> [sub {
            my $tag = $xmlname->($_[0]);
            push @tag, $tag;
            $output .= PApp::XML::xml_tag $tag, map +($xmlname->($_), $_[1]{$_}), keys %{$_[1]};
            $delayed and $err->();
         }, "tagname, attr"],
         end_h		=> [sub {
            my $tag = $xmlname->($_[0]);
            if ($tag[-1] eq $tag) {
               pop @tag;
               $output .= "</$tag>";
               $delayed and $err->();
            } else {
               for (my $i = @tag; --$i >= 0; ) {
                  if ($tag[$i] eq $tag) {
                     my $errmsg = "<error>ERROR: end-tag for element '$tag', which is not open, closing tag(s)";
                     while (@tag > $i) {
                        my $tag = pop @tag;
                        $output .= "</$tag>";
                        $delayed and $err->();
                        $errmsg .= " $tag";
                     }
                     $err->("$errmsg instead. </error>");
                     return;
                  }
               }
               $err->("<error>ERROR: skipping end-tag for element '$tag', which is not open. </error>");
            }
         }, "tagname"],
         end_document_h	=> [sub {
            while (@tag) {
               my $tag = pop @tag;
               $output .= "</$tag>" ;
               $delayed and $err->();
            }
         }],
         declaration_h	=> [sub {
         }],
         comment_h	=> [sub {
         }],
         process_h	=> [sub {
         }],
      ;

   $parser->parse($xml);
   $parser->eof;

   utf8_upgrade $output; # just for your convinience
}

=item xml_encoding xml-string [DEPRECATED]

Convinience function to detect the encoding used by the given xml
string. It uses a variety of heuristics (mainly as given in appendix F
of the XML specification). UCS4 and UTF-16 are ignored, mainly because
I don't want to get into the byte-swapping business (maybe write an
interface module for gconv?). The XML declaration itself is being
ignored.

=cut

sub xml_encoding($) {
   use bytes;
   no utf8;

   #      00 00 00 3C: UCS-4, big-endian machine (1234 order) 
   #      3C 00 00 00: UCS-4, little-endian machine (4321 order) 
   #      00 00 3C 00: UCS-4, unusual octet order (2143) 
   #      00 3C 00 00: UCS-4, unusual octet order (3412) 
   #      FE FF: UTF-16, big-endian 
   #      FF FE: UTF-16, little-endian 
   #     00 3C 00 3F: UTF-16, big-endian, no Byte Order Mark (and thus, strictly speaking, in error) 
   #     3C 00 3F 00: UTF-16, little-endian, no Byte Order Mark (and thus, strictly speaking, in error) 

   # 3C 3F 78 6D: UTF-8, ISO 646, ASCII, some part of ISO 8859, Shift-JIS, EUC, or any other 7-bit, 8-bit,
   # 4C 6F A7 94: EBCDIC (in some flavor; the full encoding declaration must be read to tell which

   # this is rather borken
   substr($_[0], 0, 4) eq "\x00\x00\x00\x3c" and return "ucs-4"; # BE
   substr($_[0], 0, 4) eq "\x3c\x00\x00\x00" and return "ucs-4"; # LE
   substr($_[0], 0, 2) eq "\xfe\xff" and return "utf-16"; # BE
   substr($_[0], 0, 2) eq "\xff\xfe" and return "utf-16"; # LE
   substr($_[0], 0, 4) eq "\x00\x3c\x00\x3f" and return "utf-16"; # BE
   substr($_[0], 0, 4) eq "\x3c\x00\x3f\x00" and return "utf-16"; # LE
   return utf8_valid $_[0] ? "utf-8" : "iso-8859-1";
}

=back

=head2 Functions for Modifying XML

=over 4

=item ($version, $encoding, $standalone) = xml_remove_decl $xml[, $encoding]

Remove the xml header, if any, from the given string and return
the info. If the declaration is missing, C<("1.0", $encoding ||
xml_encoding(), "yes")> is returned.

=cut

sub xml_remove_decl($;$) {
   use bytes;
   no utf8;

   if ($_[0] =~ s/^\s*<\? xml
      \s+ version \s*=\s* ["']([a-zA-Z0-9.:\-]+)["']
      (?:\s+ encoding \s*=\s* ["']([A-Za-z][A-Za-z0-9._\-]*)["'] )?
      (?:\s+ standalone \s*=\s* ["'](yes|no)["'] )?
      \s* \?>//x) {
      return ($1, $2, $3);
   } else {
      return ("1.0", $_[1] || &xml_encoding, "yes");
   }
}

=item ($version, $encoding, $standalone) = xml2utf8 xml-string[, encoding]

Tries to convert the given string into utf8 (inplace). Currently only
supports UTF-8 and ISO-8859-1, but could be extended easily to handle
everything Expat can. Uses C<xml_encoding> to autodetect the encoding
unless an explicit encoding argument is given.

It returns the xml declaration parameters (where encoding is always
utf-8). The xml declaration itself will be removed from the string.

=cut

sub xml2utf8($;$) {
   use bytes;
   no utf8;

   my ($version, $encoding, $standalone) = &xml_remove_decl;

   if ($encoding =~ /^utf-?8$/i) {
      utf8_on $_[0];
   } elsif ($encoding =~ /^iso-?8859-?1$/i) {
      utf8_off $_[0]; # just to be sure ;)
      utf8_upgrade $_[0];
   } else {
      # use expat!
      die "xml encoding '$encoding' not yet supported by PApp::XML::xml2utf8";
   }

   ($version, "utf-8", $standalone);
}

=item expand_pi $xml, { pi => coderef, pi2 => coderef... }

Takes an xml string and expands all processing instructions given in the
second argument by calling the respective coderef. The resulting string is
returned.

The (single) argument to the coderef is the (unquoted) argument.

This function uses a regex (without backtracking in the common case) and
should be fast.

For example, to execute sql commands using C<sql> processing instructions,
use something like this:

   Test xml string: <?sql select id from table where mtime = 7?>

   $expanded =
      expand_pi $xml, {
         sql => sub {
            xml_quote join "", sql_ufetch $_[0];
         },
      };

=cut

sub expand_pi {
   local @pi;
   (my $xml = $_[0]) =~ m{
      ^
         (?:
             # first skip all "normal" text (not <)
             [^<]+
           | # then skip CDATA sections
             <\[CDATA\[ (?: [^\]]+ | \][^\]] | \]\][^>] )* \]\]>
           | # now process processing instructions
             <\? (\w+) \s+ ( (?: [^?] | \?[^>] )+ )* \?\>
                (?{
                   push @pi, [$-[1] - 2, $+[2] + 2, $1, $2] if exists $_[1]{$1};
                })
           | # else must be a tag
             <[^?]
         )*
      $
   }gx;

   for (reverse @pi) {
      my ($a, $b, $name, $content) = @$_;
      substr $xml, $a, $b - $a, $_[1]{$name}->(xml_unquote $content);
   }

   $xml;
}

=item xml_include $document, $base [, $uri_handler($uri, $base) ]

Expand any xinclude:include elements in the given C<$document> by handing
the href attribute and the current base URI to the C<$uri_handler> with
this URI (-object).  The C<$uri_handler> should fetch the document and
return it (or C<undef> on error).

Example (see http://www.w3.org/TR/xinclude/ for the definition of
xinclude):

   <document xmlns:xinclude="http://www.w3.org/2001/XInclude">
      <xinclude:include href="http://some.host/otherdoc.xml"/>
      <xinclude:include href="/etc/passwd" parse="text"/>
   </document>

The result of running xml_include on this document will have the first
include element replaced by the document element (and it's contents) of
C<http://some.host/otherdoc.xml> and the second include element replaced
by a (correctly quoted) copy of your C</etc/passwd> file.

Another common example is embedding stylesheet fragments into larger
stylesheets. Using xinclude for these cases is faster than xsl's
include/import machanism since xinclude expansion can be done after file
loading while, while xsl's include mechanism is evaluated on every parse.

   <include xmlns="http://www.w3.org/2001/XInclude"
            href="style/xtable.xsl"
            parse="verbatim"/>

At the moment this function always returns utf-8 documents, regardless of
the input encoding used (included text is inserted as is, any converson
must be done in the uri handler).

This function does not conform to C<http://www.w3.org/TR/xmlbase/>.

In addition to C<parse="xml"> and C<parse="text">, this function also
supports C<parse="verbatim"> (insert text verbatim, i.e. like xslt's
C<disable-output-escaping="yes">) and C<parse="pxml"> (parse xml file
as pxml). The types C<xml-fragment> and C<pxml-fragment> are also under
consideration.

=cut

my $xmlns_xinclude1999 = "http://www.w3.org/1999/XML/xinclude";
my $xmlns_xinclude2001 = "http://www.w3.org/2001/XInclude";

sub xml_include {
   require XML::Parser::Expat;

   my $base = $_[1];
   my $get = $_[2] || \&PApp::Util::load_file;
   my $nested = $_[3];
   my $ignore = $nested;
   my ($self, $xinclude1999, $xinclude2001, $doc, $prefix, @context);

   my $qualify = sub {
      $prefix{$self->namespace($_[0])}.$_[0];
   };

   $self = new XML::Parser::Expat Namespaces => 1;
   $self->setHandlers(
      Start => sub {
         $ignore = 0;
         if ($self->eq_name ($_[1], $xinclude1999)
             || $self->eq_name ($_[1], $xinclude2001)) {
            my (undef, undef, %attr) = @_;
            my $parse = $attr{parse} || "xml";
            my $href = $attr{href};
            #$href->fragment eq "" or die "xml_include: fragment identifiers not supported";
            my $file = $get->($href, $base);
            defined $file or die "$href: unable to fetch document\n";
            if (defined $file) {
               if ($parse eq "pxml") {
                  require PApp::PCode;
                  $file = PApp::PCode::pxml2pcode ($file);
                  $file = xml_include ($file, $href, $get, $nested + 1);
                  $file = PApp::PCode::pcode2pxml ($file);
               } elsif ($parse eq "xml") {
                  $file = xml_include ($file, $href, $get, $nested + 1);
               } elsif ($parse eq "text") {
                  $file = $self->xml_escape ($file);
               } elsif ($parse eq "verbatim") {
                  #
               } else {
                  $self->xpcroak("parse method $parse not supported by this implementation");
               }
            }
            defined $file or die "$href: unable to fetch document";
            $doc .= $file;
         } elsif ($nested) {
            # must use the slow way... resolve entities &c.
            push @context, {};
            my $xmlns;
            for ($self->new_ns_prefixes) {
               $context[-1]{$_} = delete $prefix{$_};
               my $uri = $self->expand_ns_prefix ($_);
               # the values of $_ before and after this
               # comment do not need to be the same
               if ($_ eq "#default") {
                  $prefix{$uri} = "";
                  $xmlns .= " xmlns='$uri'";
               } else {
                  $prefix{$uri} = $_ . ":";
                  $xmlns .= " xmlns:$_='$uri'";
               }
            }
            my $tag = $qualify->($_[1]);
            $context[-1]{"\0"} = $tag;
            $doc .= "<".$qualify->($_[1]).$xmlns;
            for (my $i = 2; $i < @_; $i += 2) {
               $doc .= " ".
                       $qualify->($_[$i]).
                       "='".
                       $self->xml_escape($_[$i+1], "'").
                       "'";
            }
            $doc .= ">";
         } else {
            $doc .= $self->recognized_string;
         }
      },
      End => sub {
         unless ($self->eq_name($_[1], $xinclude)) {
            if ($nested) {
               my $ctx = pop @context;
               $doc .= "</".(delete $ctx->{"\0"}).">";
               
               while (my($k, $v) = each %$doc) {
                  $prefix{$k} = $v;
               }
            } else {
               $doc .= $self->recognized_string;
            }
         }
         $ignore = 1 if $nested && !$self->depth;
      },
      XMLDecl => sub {
         unless ($ignore) {
            $doc .= "<?xml version='$_[1]'";
            # encoding is utf-8
            $doc .= "standalone='$_[3]'" if $_[3];
            $doc .= "?>";
         }
      },
      Proc => sub {
         $doc .= "<?$_[1] $_[2]?>";
      },
      Comment => sub {
         $doc .= "<!--$_[1]-->";
      },
      Default => sub {
         $doc .= $_[1] unless $ignore;
      },
   );
   $xinclude1999 = $self->generate_ns_name("include", $xmlns_xinclude1999);
   $xinclude2001 = $self->generate_ns_name("include", $xmlns_xinclude2001);
   eval {
      local $SIG{__DIE__};
      $self->parse($_[0]);
   };
   $@ and fancydie "xml_include expansion failed", $@,
                   info => [source => PApp::Util::format_source $_[0]];
   { local $@; $self->release }
   $doc;
}

=item pod2xml $pod

Converts a POD string (which can be either a fragment or a whole document)

=cut

{
   package PApp::XML::Pod2xml;

   sub stag { (PApp::XML::xml_tag @_) }
   sub title_tag {
      my ($name, $title, $cont, @a) = @_;
      stag $name, @a,
        (stag 'title' => $title) 
        . (stag 'content' => $cont)
   }

   sub view_item  { 
      my $t = $_[1]->title->present ($_[0]);
      my $bullet;
      if ($t =~ s/^\s*\*\s+//) {
         $bullet = "*";
      } elsif ($t =~ s/^\s*(\d+\.)\s+//) {
         $bullet = $1;
      }
      title_tag item  => $t
                      => $_[1]->content->present ($_[0]),
                      $bullet ? (bullet => $bullet) : ()
   }

   sub view_begin {
      $_[1]->format eq "xmlpod"
         ? $_[1]->content->present ($_[0])
         : stag for => format => $_[1]->format, $_[1]->content->present ($_[0])
   }

   sub view_for {
      $_[1]->format eq "xmlpod"
         ? $_[1]->text
         : stag for => $_[1]->text;
   }

   sub view_pod   { stag pod => xmlns => "http://www.nethype.de/xmlns/xmlpod" => $_[1]->content->present ($_[0]) }

   sub view_head1 { title_tag head1 => $_[1]->title->present ($_[0]) => $_[1]->content->present ($_[0]) }
   sub view_head2 { title_tag head2 => $_[1]->title->present ($_[0]) => $_[1]->content->present ($_[0]) }
   sub view_head3 { title_tag head3 => $_[1]->title->present ($_[0]) => $_[1]->content->present ($_[0]) }
   sub view_head4 { title_tag head4 => $_[1]->title->present ($_[0]) => $_[1]->content->present ($_[0]) }

   sub view_over       { stag over  => indent => $_[1]->indent, $_[1]->content->present ($_[0]) }
   sub view_begin      { stag begin => format => $_[1]->format, $_[1]->content->present ($_[0]) }

   sub view_verbatim   { stag verbatim => PApp::XML::xml_cdata $_[1] }
   sub view_textblock  { stag para     => $_[1] }
   
   sub view_seq_code   { stag code => $_[1] } 
   sub view_seq_bold   { stag bold => $_[1] }
   sub view_seq_italic { stag italic => $_[1] }
   sub view_seq_link   { stag link  => $_[1] }
   sub view_seq_index  { stag index => $_[1] }
   sub view_seq_file   { stag file => $_[1] }
   sub view_seq_zero   { "" } 
   sub view_seq_space  { PApp::XML::xml_quote $_[1] }
   sub view_seq_text   { PApp::XML::xml_quote $_[1] }
   sub view_seq_entity { PApp::XML::xml_quote $_[1] } 
}

sub pod2xml($) {
   my ($pod) = @_;

   return "" if not $pod;

   require Pod::POM;

   my $parser = Pod::POM->new 
      or die "Couldn't create POM object";
   my $pom = $parser->parse_text ("=pod\n\n".$pod)
      or die $parser->error ();

   $pom->present (PApp::XML::Pod2xml::);
}

=back

=head2 The PApp::XML Factory Class

=over 4

=item new PApp::XML parameter => value...

Creates a new PApp::XML template object with the specified behaviour. It
can be used as an object factory to create new C<PApp::XML::Template>
objects.

 special        a hashref containing special => coderef pairs. If a
                special is encountered, the given coderef will be compiled
                in instead (i.e. it will be called each time the fragment
                is print'ed). The coderef will be called with a reference
                to the attribute hash, the element's contents (as a
                string) and the PApp::XML::Template object used to print
                the string.

                If a reference to a coderef is given (e.g. C<\sub {}>),
                the coderef will be called during parsing and the
                resulting string will be added to the compiled subroutine.
                The arguments are the same, except that the contents are
                not given as string but as a magic token that must be
                inserted into the return value.

                The return value is expected to be in "phtml"
                (L<PApp::Parser>) format, the magic "contents" token must
                not occur in code sections.
                
 html           html output mode enable flag

At the moment there is one predefined special named C<slink>, that maps
almost directly into a call to slink (a leading underscore in an attribute
name gets changed into a minus (C<->) to allow for one-shot arguments),
e.g:

 <papp:special _special="slink" module="kill" name="Bill" _doit="1">
    Do it to Bill!
 </papp:special>

might get changed to (note that C<module> is treated specially):

 slink "Do it to Bill!", "kill", -doit => 1, name => "Bill";

In a XSLT stylesheet one could define:

  <xsl:template match="link">
     <papp:special _special="slink">
        <xsl:for-each select="@*">
           <xsl:copy/>
        </xsl:for-each>
        <xsl:apply-templates/>
     </papp:special>
  </xsl:template>

Which defines a C<link> element that can be used like this:

  <link module="kill" name="bill" _doit="1">Kill Bill!</link>

=cut

sub new($;%) {
   require PApp;

   my $class = shift,
   my %args = @_;
   my $self = bless {}, $class;

   $self->{attr} = delete $args{attr} || {};
   $self->{html} = delete $args{html} || {};
   $self->{special} = {
      slink => sub {
         my ($attr, $content) = @_;
         my %attr = %$attr;
         my $sublink = delete $attr{sublink};
         my @args = delete $attr{module};
         while (my ($k, $v) = each %attr) {
            $k =~ s/^_/-/;
            push @args, $k, $v;
         }
         PApp::echo ($sublink eq "yes")
            ? PApp::sublink ([PApp::current_locals ()], $content, @args)
            : PApp::slink ($content, @args);
      },
      %{delete $args{special} || {}},
   };

   $self;
}

=item $pappxml->dom2template($dom, {special}, key => value...)

Compile the given DOM into a C<PApp::XML::Template> object and returns
it. An additional set of specials only used to parse this dom can be
passed as a hashref (this argument is optional). Additional key => value
pairs will be added to the template's attribute hash. The template will be
evaluated in the caller's package (e.g. to get access to __ and similar
functions).

On error, nothing is returned. Use the C<error> method to get more
information about the problem.

In addition to the syntax accepted by C<PApp::PCode::pxml2pcode>, this
function evaluates certain XML Elements (please note that I consider the
"papp" namespace to be reserved):

 papp:special _special="special-name" attributes...
   
   Evaluate the special with the name given by the attribute C<_special>
   after evaluating its content. The special will receive two arguments:
   a hashref with all additional attributes and a string representing an
   already evaluated code fragment.
 
 papp:unquote

   Expands ("unquotes") some (but not all) entities, namely lt, gt, amp,
   quot, apos. This can be easily used within a stylesheet to create
   verbatim html or perl sections, e.g.

   <papp:unquote><![CDATA[
      <: echo "hallo" :>
   ]]></papp:unquote>

   A XSLT stylesheet that converts <phtml> sections just like in papp files
   might look like this:

   <xsl:template match="phtml">
      <papp:unquote>
         <xsl:apply-templates/>
      </papp:unquote>
   </xsl:template>

=begin comment

 attr           a hashref with attribute => value pairs. These attributes can
                later be quieried and set using the C<attr> method.

=end comment

=cut
                
sub dom2template($$;%) {
   my $self = shift;
   my $dom = shift;
   my $temp = bless {
      attr => {@_},
   }, PApp::XML::Template::;
   my $package = (caller)[0];

   $temp->{code} = $temp->_dom2sub($dom, $self, $package);

   delete $temp->{attr}{special};

   if ($temp->{code}) {
      $temp;
   } else {
      # error
      ();
   }
}

=item $err = $pappxml->error

Return information about an error as an C<PApp::Exception> object
(L<PApp::Exception>).

=cut

sub error {
   my $self = shift;
   $self->{error};
}

package PApp::XML::Template;

use PApp::PCode ();

our $_res;

sub __dom2sub($) {   
   my $node = $_[0]->getFirstChild;

   while ($node) {
      my $type = $node->getNodeType;

      if ($type == &XML::DOM::TEXT_NODE || $type == &XML::DOM::CDATA_SECTION_NODE) {
         $_res .= $node->toString;
      } elsif ($type == &XML::DOM::ELEMENT_NODE) {
         my $name = $node->getTagName;
         my %attr;
         {
            my $attrs = $node->getAttributes;
            for (my $n = $attrs->getLength; $n--; ) {
               my $attr = $attrs->item($n);
               $attr{$attr->getName} = $attr->getValue;
            }
         }
         if (substr($name, 0, 5) eq "papp:") {
            if ($name eq "papp:special") {
               my $name = delete $attr{_special};
               my $sub = $_self->{attr}{special}{$name} || $_factory->{special}{$name};

               if (defined $sub) {
                  my $idx = @$_local;
                  if (ref $sub eq "REF") {
                     push @$_local, $_self->_dom2sub($node, $_factory, $_package);
                     $_res .= $$sub->(
                           \%attr,
                           '<:$_dom2sub_local['.($idx).']():>',
                           $_self,
                     );
                  } else {
                     push @$_local, $sub;
                     push @$_local, \%attr;
                     push @$_local, $_self->_dom2sub($node, $_factory, $_package);
                     $_res .= '<:
                        $_dom2sub_local['.($idx).'](
                              $_dom2sub_local['.($idx+1).'],
                              PApp::capture { $_dom2sub_local['.($idx+2).']() },
                              $_dom2sub_self,
                        )
                     :>';
                  }
               } else {
                  $_res .= "&lt;&lt;&lt; undefined special '$name' containing '";
                  __dom2sub($node);
                  $_res .= "' &gt;&gt;&gt;";
               }
            } elsif ($name eq "papp:unquote") {
               my $res = do {
                  local $_res = "";
                  __dom2sub($node);
                  $_res;
               };
               $_res .= PApp::XML::xml_unquote $res;
            } else {
               $_res .= "&lt;&lt;&lt; undefined papp element '$name' containing '";
               __dom2sub($node);
               $_res .= "' &gt;&gt;&gt;";
            }
         } else {
            $_res .= "<$name";
            while (my ($k, $v) = each %attr) {
               # we prefer single quotes, since __ and N_ do not
               $v =~ s/'/&apos;/g;
               $_res .= " $k='$v'";
            }
            my $content = do {
               local $_res = "";
               __dom2sub($node);
               $_res;
            };
            if ($content ne "") {
               $_res .= ">$content</$name>";
            } elsif ($_factory->{html}) {
               if ($name =~ /^br|p|hr|img|meta|base|link$/i) {
                  $_res .= ">";
               } else {
                  $_res .= "></$name>";
               }
            } else {
               $_res .= "/>";
            }
         }
      }
      $node = $node->getNextSibling;
   }
}

sub _dom2sub($$$$) {
   local $_self = shift;
   local $_dom = shift;
   local $_factory = shift;
   local $_package =  shift;

   my @_dom2sub_local;
   local $_local = \@_dom2sub_local;

   local $_res = "";
   __dom2sub($_dom);

   my $_dom2sub_self = $_self;
   my $_dom2sub_str = <<EOC;
package $_package;
sub {
#line 1 \"anonymous PApp::XML::Template\"
${\(PApp::PCode::pcode2perl(PApp::PCode::pxml2pcode($_res)))}
}
EOC
   my $self = $_self;
   my $sub = eval $_dom2sub_str;

   if ($@) {
      $_factory->{error} = new PApp::Exception error => $@, info => $_dom2sub_str;
      return;
   } else {
      delete $_factory->{error};
      return $sub;
   }
}

=item $template->localvar([content]) [WIZARDRY]

Create a local variable that can be used inside specials and return a
string representation of it (i.e. a magic token that represents the lvalue
of the variable when compiled). Can only be called during compilation.

=cut

sub localvar($$;$) {
   my ($self, $val) = @_;
   my $idx = @$_local;
   push @$_local, $val;
   '$_dom2sub_local['.($idx).']';
}

=item $template->gen_surl(<surl-arguments>) [WIZARDY]

Returns a string representing a perl statement returning the surl.

=cut

sub gen_surl($;@) {
   my $self = shift;
   my $var = $self->localvar(\@_);
   "surl(\@{$var})";
}

=item $template->gen_slink(<surl-arguments>) [WIZARDY]

Returns a string representing a perl statement returning the slink.

=cut

sub gen_slink($;@) {
   my $self = shift;
   my $content = $self->localvar(shift);
   my $surl = $self->gen_surl($content);
   "slink($content, $surl)";
}

=item $template->attr(key, [newvalue])

Return the attribute value for the given key. If C<newvalue> is given, replaces
the attribute and returns the previous value.

=cut

sub attr($$;$) {
   my $self = shift;
   my $key = shift;
   my $val = $self->{attr}{$key};
   $self->{attr}{$key} = shift if @_;
   $val;
}

=item $template->print

Print (and execute any required specials). You can capture the output
using the C<PApp::capture> function.

=cut

sub print($) {
   shift->{code}();
}

1;

=back

=head1 Wizard Example

In this section I'll try to sketch out a "wizard example" that shows how
C<PApp::XML> could be used in the real world.

Consider an application that fetches most or all content (even layout)
from a database and uses a stylesheet to map xml content to html, which
allows for almost total seperation of layout and content. It would have an
init section loading a XSLT stylesheet and defining a content factory:

   use XML::XSLT; # ugly module, but it works great!
   use PApp::XML;

   # create the parser
   my $xsl = "$PApp::Config{LIBDIR}/stylesheet.xsl";
   $xslt_parser = XML::XSLT->new($xsl, "FILE");

   # create a content factory
   $tt_content_factory = new PApp::XML
      html => 1, # we want html output
      special => {
         include => sub {
            my ($attr, $content) = @_;
            get_content($attr->{name})->print;
         },
      };

   # create a cache (XSLT is quite slow)
   use Tie::Cache;
   tie %content_cache, Tie::Cache::, { MaxCount => 30, WriteSync => 0};

Here we define an C<include> special that inserts another document
inplace. How does C<get_content> (see the definition of C<include>) look
like?

   <macro name="get_content" args="$name $special"><phtml><![CDATA[<:
      my $cache = $content_cache{"$lang\0$name"};
      unless ($cache) {
         $cache = $content_cache{"$lang\0$name"} = [
            undef,
            0,
         ];
      }
      if ($cache->[1] < time) {
         $cache->[0] = fetch_content $name, $special;
         $cache->[1] = time + 10;
      }
      $cache->[0];
   :>]]></phtml></macro>

C<get_content> is nothing more but a wrapper around C<fetch_content>. It's
sole purpose is to cache documents since parsing and transforming a xml
file is quite slow (please note that I include the current language when
caching documents since, of course, the documents get translated). In
non-speed-critical applications you could just substitute C<fetch_content>
for C<get_content>:

   <macro name="fetch_content" args="$name $special"><phtml><![CDATA[<:
      sql_fetch \my($id, $_name, $ctime, $body),
                "select id, name, unix_timestamp(ctime), body from content where name = ?",
                $name;
      unless ($id) {
         ($id, $_name, $ctime, $body) =
            (undef, undef, undef, "");
      }

      parse_content (gettext$body, {
         special => $special,
         id      => $id,
         name    => $name,
         ctime   => $ctime,
         lang    => $lang,
      });
   :>]]></phtml></macro>

C<fetch_content> actually fetches the content string from the database. In
this example, a content object has a name (which is used to reference it)
a timestamp and a body, which is the actual document. After fetching the
content object it uses C<parse_content> to transform the xml snippet into
a perl sub that can be efficiently executed:

   <macro name="parse_content" args="$body $attr"><phtml><![CDATA[<:
      my $content = eval {
         $xslt_parser->transform_document(
             '<?xml version="1.0" encoding="iso-8859-1" standalone="no"?'.'>'.
             "<ttt_fragment>".
             $body.
             "</ttt_fragment>",
             "STRING"
         );
         my $dom = $xslt_parser->result_tree;
         $tt_content_factory->dom2template($dom, %$attr);
      };
      if ($@) {
         my $line = $@ =~ /mismatched tag at line (\d+), column \d+, byte \d+/ ? $1 : -1;
         # create a fancy error message
      }
      $content || parse_content("");
   :>]]></phtml></macro>

As you can see, it uses XSLT's C<transform_document>, which does the
string -> DOM translation for us, and also transforms the XML code through
the stylesheet. After that it uses C<dom2template> to compile the document
into perl code and returns it.

An example stylesheet would look like this:

   <xsl:template match="ttt_fragment">
      <xsl:apply-templates/>
   </xsl:template>

   <xsl:template match="p|em|h1|h2|br|tt|hr|small">
      <xsl:copy>
         <xsl:apply-templates/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="include">
      <papp:special _special="include" name="{@name}"/>
   </xsl:template>

   # add the earlier XSLT examples here.

This stylesheet would transform the following XML snippet:

   <p>Look at
      <link module="product" productid="7">our rubber-wobber-cake</link>
      before it is <em>sold out</em>!
      <include name="product_description_7"/>
   </p>

Which would be turned into something like this:

   <p>Look at
      <papp:special _special="slink" module="product" productid="7">
         our rubber-wobber-cake
      </apppxml:special>
      before it is <em>sold out</em>!
      <papp:special _special="include" name="product_description_7"/>
   </p>

Now go back and try to understand the above code! But wait! Consider that you
had a content editor installed as the module C<content_editor>, as I happen to have. Now
lets introduce the C<editable_content> macro:

   <macro name="editable_content" args="$name %special"><phtml><![CDATA[<:

      my $content;

      :>
   #if access_p "admin"
      <table border=1><tr><td>
      <:
         sql_fetch \my($id), "select id from content where name = ?", $name;
         if ($id) {
            :><?sublink [current_locals], __"[Edit the content object \"$name\"]", "content_editor_edit", contentid => $id:><:
         } else {
            :><?sublink [current_locals], __"[Create the content object \"$name\"]", "content_editor_edit", contentname => $name:><:
         }

         $content = get_content($name,\%special);
         $content->print;
      :>
      </table>
   #else
      <:
         $content = get_content($name,\%special);
         $content->print;
      :>
   #endif
      <:

      return $content;
   :>]]></phtml></macro>

What does this do? Easy: If you are logged in as admin (i.e. have the
"admin" access right), it displays a link that lets you edit the object
directly. As normal user it just displays the content as-is. It could be
used like this:

   <perl><![CDATA[
      header;
      my $content = editable_content("homepage");
      footer last_changed => $content->ctime;
   ]]></perl>

Disregarding C<header> and C<footer>, this would create a page fully
dynamically out of a database, together with last-modified information,
which could be edited on the web. Obviously this approach could be
extended to any complexity.

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

