package Net::Gnats::Command::FVLD;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::FVLD::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_TEXT_READY CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::FVLD

=head1 DESCRIPTION

Returns one or more regular expressions or strings that describe the
valid types of data that can be placed in field. Exactly what is
returned is dependent on the type of data that can be stored in the
field. For most fields a regular expression is returned; for
enumerated fields, the returned values are the list of legal strings
that can be held in the field.

=head1 PROTOCOL

 FVLD [field]

=head1 RESPONSES

The possible responses are:

301 (CODE_TEXT_READY)

The normal response, which is followed by the list of regexps or
strings.

410 (CODE_INVALID_FIELD_NAME)

The specified field does not exist.

=cut

my $c = 'FVLD';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my $self =  shift;
  return undef if not defined $self->{field};
  return $c . ' ' . $self->{field};
}

sub is_ok {
  my $self = shift;
  return 0 if not defined $self->response;
  return 1 if $self->response->code == CODE_TEXT_READY;
  return 0;
}

1;
