package MockMI;
# Mock the bits of M::I we care about;
use Moose;

extends 'Moose::Object', 'Module::Install::ProvidesClass';
use FindBin qw/$Bin/;

has is_admin => (
  is => 'ro',
  default => 1
);

has dir => (
  reader => '_get_dir',
  default => "$Bin/data"
);

has no_index => (
  reader => '_get_no_index',
  required => 1,
);

has _provides => (
  is => 'rw',
  default => sub { {} }
);

sub provides {
	my $self     = shift;
	$self->_provides( { %{$self->_provides}, @_ });
}


1;
