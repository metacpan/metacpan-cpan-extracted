package Net::Gnats::Command::FTYPINFO;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::FTYPINFO::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_FTYPE_PROPERTY);

=head1 NAME

Net::Gnats::Command::FTYPINFO

=head1 DESCRIPTION

Provides field-type-related information. Currently, only the
property separators for MultiEnum fields is supported. When
separators is specified, the possible return codes are:

=head1 PROTOCOL

 FTYPINFO [field] [property]

=head1 RESPONSES

350 (CODE_INFORMATION)

A proper MultiEnum field was specified and the returned text is the
string of separators specified for the field in the dbconfig file
(see Field datatypes) quoted in ''s.

435 (CODE_INVALID_FTYPE_PROPERTY)

The separators property is not defined for this field, i.e. the
specified field is not of type MultiEnum.

Currently, specifying a different property than separators results
in return code 435 as above.

=cut


my $c = 'FTYPINFO';

sub new {
  my ( $class, %options ) = @_;
  my $self = bless \%options, $class;
  $self->{property} = 'separators' if not defined $self->{property};
  return $self;
}

sub as_string {
  my $self = shift;
  return undef if not defined $self->{field};
  return undef if not defined $self->{property};
  return $c . ' ' . $self->{field} . ' ' . $self->{property};
}

sub is_ok {
  my $self = shift;
  return 0 if not defined $self->response;
  return 1 if $self->response->code eq CODE_INFORMATION;
  return 0;
}

1;
