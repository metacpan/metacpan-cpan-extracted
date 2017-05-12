=head1 NAME

PApp::XSLT::Sablotron - wrapper for an XSLT implementation

=head1 SYNOPSIS

 use XML::Sablotron;
 # to be written

=head1 DESCRIPTION

The PApp::XSLT::Sablotron module is a wrapper around
XML::Sablotron. Unless you specifically need Sablotron you should see
L<PApp::XSLT>.

=over 4

=cut

package PApp::XSLT::Sablotron;

$VERSION = 0.12;

no bytes;

use XML::Sablotron;

use Convert::Scalar ();

use PApp::Exception;

use base PApp::XSLT;

our $sablo;
our $curobj;

=item new PApp::XSLT::Sablotron parameter => value...

Creates a new PApp::XSLT::Sablotron object with the specified
behaviour. All parameters are optional. See C<PApp::XSLT::new>.

=cut

sub new($;%) {
   my $class = shift;
   my $self = $class->SUPER::new(@_);
   my %args = @_;

   unless ($sablo) { # a singleton object
      local $curobj = $self;
      my $proxyobj = bless [], PApp::XSLT::Sablotron::Handler::;
      $sablo = XML::Sablotron->new;
      $sablo->RegHandler(0, $proxyobj);
      $sablo->RegHandler(1, $proxyobj);
   }

   $self;
}

for my $method (qw(SHGetAll MHError SHOpen)) {
   *{"PApp::XSLT::Sablotron::Handler::$method"} = sub {
      shift;
      $curobj->$method(@_);
   };
}

# for speed, these two methods get shortcutted
sub PApp::XSLT::Sablotron::Handler::MHLog {}
sub PApp::XSLT::Sablotron::Handler::MHMakeCode { $_[4] }

#sub MHLog($$$$;@) {
#   my ($self, $processor, $code, $level, @fields) = @_;
#   warn "PApp::XSLT<$code,$level> @fields\n";
#}
#
#sub MHMakeCode {
#   my ($self, $processor, $severity, $facility, $code) = @_;
#   warn "MHMake @_\n";#d#
#   $code;
#}

sub MHError($$$$;@) {
   my ($self, $processor, $code, $level, @fields) = @_;
   unless ($curerr) {
      my $msgtype = "error";
      my $uri;
      my $line;
      my $msg = "unknown error";
      my @other;
      for (@fields) {
         if (my ($k, $v) = split /:/, $_, 2) {
            if ($k eq "msgtype") {
               $msgtype = $v;
            } elsif ($k eq "URI") {
               $uri = $v;
            } elsif ($k eq "msg") {
               $msg = $v;
            } elsif ($k eq "line") {
               $line = $v;
            } elsif ($k eq "module") {
               # always Sablotron
            } elsif ($k !~ /^(?:code)$/) {
               push @other, "$k=$v";
            }
         }
      }
      $self->error($uri,
         "$msgtype: ".
         ($uri ? $uri : "").
         ($line ? " line $line" : "").
         ": $msg".
         (@other ? " (@other)" : ""),
      );
   }
}

sub SHOpen {
   my ($self, $processor, $scheme, $rest) = @_;
   $self->error($processor, 1, 3,
         "msgtype:error",
         "code:1",
         "module:PApp::XSLT",
         "URI:$scheme:$rest",
         "msg:SHOpen unsupported",
   );
   undef;
}

sub SHGet {
   return "]]>\"'<<&&"; # certainly cause a parse error ;->
}

sub SHPut { }
sub SHClose { }

sub SHGetAll($$$$) {
   my ($self, $processor, $scheme, $rest) = @_;
   my $dok = $self->getdoc($scheme, $rest);
   return $dok if defined $dok;
   return "]]>\"'<<&&"; # certainly cause a parse error ;->
}

sub _apply($$;@) {
   local $curobj = shift;
   my $source = shift;
   $sablo->ClearError;
   my $ss = ref $curobj->{ss} ? $curobj->{ss}->() : $curobj->{ss};
   Convert::Scalar::utf8_off($ss);
   $sablo->RunProcessor(
                        "arg:/template",
                        "arg:/data",
                        "arg:/result",
                        \@_,
                        [
                           template => $ss,
                           data => $source,
                        ],
                       );
   $source = $sablo->GetResultArg("result");
   $sablo->FreeResultArgs;
   $source; # yes, perl, it's already unicode
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

