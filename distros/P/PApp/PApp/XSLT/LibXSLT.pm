=head1 NAME

PApp::XSLT::LibXSLT - wrapper for an XSLT implementation

=head1 SYNOPSIS

 use PApp::XSLT::LibXSLT;
 # to be written

=head1 DESCRIPTION

The PApp::XSLT::LibXSLT module is a wrapper around XML::LibXSLT. Unless
you specifically need XML::LibXSLT you should see L<PApp::XSLT>.

=over 4

=cut

package PApp::XSLT::LibXSLT;

$VERSION = 0.12;

no bytes;

use XML::LibXML;
use XML::LibXSLT;

use Convert::Scalar ();

use PApp::Exception;

use base PApp::XSLT;

=item new PApp::XSLT::LibXSLT parameter => value...

Creates a new PApp::XSLT::LibXSLT object with the specified
behaviour. All parameters are optional. See C<PApp::XSLT::new>.

=cut

our $parser;
our $xslt;

sub new($;%) {
   my $class = shift;
   my $self = $class->SUPER::new(@_);
   my %args = @_;

   $parser ||= new XML::LibXML;
   $xslt   ||= new XML::LibXSLT;

   $self;
}

sub _apply($$;@) {
   my $self = shift;
   my $ss = $self->{_ss};

   eval {
      if (!$ss and ref $self->{ss} ne XML::LibXSLT::Stylesheet) {
         if (ref $self->{ss}) {
            # parse it each time :(
            $ss = $xslt->parse_stylesheet(
                     $parser->parse_string(
                        $self->{ss}->()
                     )
                  );
         } else {
            # parse it once :)
            $self->{_ss} = 
            $ss = $xslt->parse_stylesheet(
                     $parser->parse_string(
                        $self->{ss}
                     )
                  );
         }
      }
   };
   if ($@) {
      $self->error("arg:/template", $@);
      return ();
   }

   my $result = eval {
      $ss->output_string($ss->transform(@_));
   };
   if ($@) {
      $self->error("arg:/data", $@);
      return ();
   } else {
      return $result;
   }
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

