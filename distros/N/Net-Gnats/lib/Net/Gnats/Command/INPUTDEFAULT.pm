package Net::Gnats::Command::INPUTDEFAULT;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::INPUTDEFAULT::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::INPUTDEFAULT

=head1 DESCRIPTION

Like the FDSC and FTYP commands, multiple field names may be listed
with the command, and a response line will be returned for each one
in the order that the fields appear on the command line.

=head1 PROTOCOL

 INPUTDEFAULT [fields...]

=head1 RESPONSES

Returns the suggested default value for a field when a PR is
initially created. The possible responses are either 410
(CODE_INVALID_FIELD_NAME), meaning that the specified field is
invalid or nonexistent, or 350 (CODE_INFORMATION) which contains the
default value for the field.

=cut

my $c = 'INPUTDEFAULT';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  $self->{requests_multi} = 0;
  return $self if not defined $self->{fields};

  if (ref $self->{fields} eq 'ARRAY') {
    $self->{requests_multi} = 1 if scalar @{ $self->{fields} } > 1;
  }
  else {
    $self->{fields} = [ $self->{fields} ];
  }
  return $self;
}

sub as_string {
  my ($self) = @_;
  return undef if not defined $self->{fields};
  return $c . ' ' . join ( ' ', @{$self->{fields}} );
}

# this command can take multiple fields, each getting their own response.
# so, we check that 'everything' is okay by looking at the parent response.
sub is_ok {
  my $self = shift;
  return 0 if not defined $self->response;
  if ( $self->{requests_multi} == 0 and
       $self->response->code == CODE_INFORMATION) {
    return 1;
  }
  return 1 if $self->response->code == CODE_INFORMATION;
  return 0;
}

1;
