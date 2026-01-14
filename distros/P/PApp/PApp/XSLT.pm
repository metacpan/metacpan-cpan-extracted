##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::XSLT - wrapper for an XSLT implementation

=head1 SYNOPSIS

 use PApp::XSLT; # try to find any implementation, OR

 use PApp::XSLT::Sablotron; # choose sablotron
 use PApp::XSLT::LibXSLT;   # or choose libxslt
 use PApp::XSLT;            # before loading PApp::XSLT

=head1 DESCRIPTION

The PApp::XSLT module is more or less a wrapper around an unnamed XSLT
implementation (currently XML::Sablotron or XML::LibXSLT, chosen at
runtime, should be moderately easy to add XML::Transformiix or XML::XSLT).

=over 4

=cut

package PApp::XSLT;

$VERSION = 2.4;

no bytes;

use Convert::Scalar ();

use PApp::Exception;

our $sablo;
our $curobj;
our $curerr;

=item new PApp::XSLT parameter => value...

Creates a new PApp::XSLT object with the specified behaviour. All
parameters are optional.

 stylesheet     see the C<stylesheet> method.
 get_<scheme>   see the C<scheme_handler> method.

=cut

sub new($;%) {
   my $class = shift;

   if ($class eq PApp::XSLT) {
      # give Sablotron higher priority. Yes.
      if (eval { require PApp::XSLT::Sablotron; 1 }) {
         return new PApp::XSLT::Sablotron @_;
      } elsif (eval { require PApp::XSLT::LibXSLT; 1 }) {
         return new PApp::XSLT::LibXSLT @_;
      } else {
         die "PApp::XSLT could neither find PApp::XSLT::Sablotron nor PApp::XSLT::LibXSLT";
      }
   } else {
      # called by subclass
      my %args = @_;
      my $self = bless {}, $class;

      while (my ($k, $v) = each %args) {
         $self->scheme_handler($1, $v) if $k =~ /^get_(.*)$/;
      }

      $self->stylesheet($args{stylesheet}) if defined $args{stylesheet};

      return $self;
   }
}

=item $old = $xslt->stylesheet([stylesheet-uri])

Set the stylesheet to use for later transformation requests by specifying
a uri. The only supported scheme is currently C<data:,verbatim xml
stylesheet text> (the comma is not a typoe, see rfc2397 on why this is
the most compatible form to the real data: scheme ;).

If the stylesheet is a code reference (or any reference), it is executed
for each invocation and should return the actual stylesheet to use.

It always returns the current stylesheet.

=cut

sub stylesheet($;$) {
   my $self = shift;
   my $ss = shift;
   if (ref $ss) {
      $self->{ss} = $ss;
   } elsif (defined $ss) {
      my ($scheme, $rest) = split /:/, $ss, 2;
      $self->{ss} = $self->getdoc($scheme, $rest);
   }
   $self->{ss};
}

=item $old = $xslt->scheme_handler($scheme[, $handler])

Set a handler for the given uri scheme.  The handler will be called with
the xslt object, the scheme name and the rest of the uri and is expected
to return the whole document, e.g.

   $xslt->set_handler("http", sub {
      my ($self, $scheme, $uri) = @_;
      return "<dokument>text to be returned</dokument>";
   });

might be called with (<obj>, "http", "www.plan9.de/").  Hint: this
function can easily be abused to feed data into a stylesheet dynamically.

Not all implementations support this method.

When the $handler argument is C<undef>, the current handler will be
deleted. If it is missing, nothing happens (only the old handler is
returned).

=cut

sub scheme_handler($$;$) {
   my $self = shift;
   my $scheme = shift;
   my $old = $self->{get}{$scheme};
   if (@_) {
      delete $self->{get}{$scheme};
      $_[0] and $self->{get}{$scheme} = shift;
   }
   $old;
}

sub error($$$) {
   my ($self, $uri, $msg) = @_;
   unless ($self->{curerr}) {
      $self->{curerr} = [$uri, $msg];
   }
}

sub getdoc($$) {
   my ($self, $scheme, $rest) = @_;
   if ($self->{get}{$scheme}) {
      my $dok = eval { $self->{get}{$scheme}($self, $scheme, $rest) };
      if ($@) {
         $self->error("$scheme:$rest",
                      "error: $scheme:$rest: scheme handler evaluation error '$@'");
      } else {
         return $dok;
      }
   } elsif ($scheme eq "data") {
      return substr $rest, 1;
   } else {
      $self->error("$scheme:$rest",
                   "error: $scheme:$rest: unsupported uri scheme");
   }
   ();
}

=item $xslt->apply(document-uri[, param => value...])

Apply the document (specified by the given document-uri) and return it as
a string. Optional arguments set the named global stylesheet parameters.

=cut

sub apply($$;@) {
   my $self = shift;
   my ($scheme, $rest) = split /:/, shift, 2;
   $self->apply_string($self->getdoc($scheme, $rest), @_);
}

=item $xslt->apply_string(xml-doc[, param => value...])

The same as calling the C<apply>-method with the uri C<data:,xml-doc>,
i.e. this method applies the stylesheet to the string.

=cut

sub apply_string($$;@) {
   my $self = shift;
   my $source = shift;
   delete $self->{curerr};
   my $result = $self->_apply($source, @_);
   if ($self->{curerr}) {
      require PApp::Util;
      my $ss = ref $self->{ss} ? $self->{ss}->() : $self->{ss};
      fancydie "error during stylesheet processing", $self->{curerr}[1],
               $self->{curerr}[0] ne "arg:/template" ? (info => ["arg:/data"     => PApp::Util::format_source($source)], info => ["arg:/template" => PApp::Util::format_source($ss    )]) : (),
               $self->{curerr}[0] ne "arg:/data"     ? (info => ["arg:/template" => PApp::Util::format_source($ss    )], info => [ "arg:/data"     => PApp::Util::format_source($source)]) : (),
              ;
   }
   Convert::Scalar::utf8_on($result);
}

# this method must be overwritten
sub _apply($$;@) {
   die "PApp::XSLT default semantics for _apply_string not available";
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

