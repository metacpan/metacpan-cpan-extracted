package Net::Gnats::Command::ADMV;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::ADMV::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_INVALID_FIELD_NAME CODE_NO_ADM_ENTRY CODE_INFORMATION);

=head1 NAME

Net::Gnats::Command::ADMV

=head1 DESCRIPTION

Returns an entry from an administrative data file associated with
field. key is used to look up the entry in the data file. If
subfield is specified, only the value of that subfield is returned;
otherwise, all of the fields in the adm data file are returned,
separated by colons :.

=head1 RESPONSES

The responses are:

410 (CODE_INVALID_FIELD_NAME) The specified field does not exist.

221 (CODE_NO_ADM_ENTRY) An adm entry matching the key was not found,
     or the field does not have an adm file associated with it.

350 (CODE_INFORMATION) The normal response; the supplied text is the
    requested field(s).

=head1 EXAMPLES

 my $entry = Net::Gnats::Command::ADMV->new( field => myfield, key => mykey )->as_string;

=cut

my $c = 'ADMV';

sub new {
  my ( $class, %options ) = @_;
  return bless {}, $class if not %options;
  my $self = bless \%options, $class;
  return $self;
}

sub field_name { return shift->{field_name}; }

sub key { return shift->{key}; }

sub as_string {
  my $self = shift;
  return $c . ' ' . $self->field_name . ' ' . $self->key;
}

1;
