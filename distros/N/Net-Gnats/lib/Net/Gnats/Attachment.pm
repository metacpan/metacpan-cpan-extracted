package Net::Gnats::Attachment;
use utf8;
use strictures;
use 5.10.00;
use MIME::Base64;

BEGIN {
  $Net::Gnats::Attachment::VERSION = '0.22';
}
use vars qw($VERSION);

sub new {
  my ($class, %options) = @_;
  my $self = bless \%options, $class;
  return $self;
}

sub encode {

}

sub decode {
  my ($self) = @_;

  # Split the envelope from the body.
  my ($envelope, $body) = split(/\n\n/, $self->{payload}, 2);
  return undef unless ($envelope && $body);

  my $ex_envelope = qr{\sContent-Type:\s(.*)\n
                       \sContent-Transfer-Encoding:\s(.*)\n
                       \sContent-Disposition:\s(.*)\n}x;

  ($self->{content_type},
   $self->{content_transfer_encoding},
   $self->{content_disposition}) = $envelope =~ $ex_envelope;

  if ( $self->{content_transfer_encoding} eq 'base64') {
    $self->{data} = decode_base64($body);
  }
  else {
    $self->{data} = $body;
  }

  return 1;
}


1;
