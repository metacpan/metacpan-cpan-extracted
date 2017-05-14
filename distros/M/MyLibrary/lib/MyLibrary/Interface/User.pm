package MyLibrary::Interface::User;

use MyLibrary::DB;
use base qw(MyLibrary::Interface);

=head1 NAME

MyLibrary::Interface::User

=head1 SYNOPSIS

	use MyLibrary::Interface::User;

=head1 DESCRIPTION

Modular user interface components for MyLibrary.

=head1 EXPORT

Few methods will be exported.

=head1 METHODS

Most of the methods employed here are class methods. However, class objects are created with 
embedded attributes.

=head1 new_account_interface(\%attr)

=cut

use strict;

sub new_account_interface {
	my ($class, %opts) = @_;
	my $self = {};
	$self->{type} = 'new_account';
	if (%opts) {
		foreach my $key (sort keys %opts) {
			$self->{$key} = $opts{$key};
		}
	}
	return bless $self, $class;
} # end sub new_account 

=head1 login_interface(\%attr)

=cut
sub login_interface {
	my $dbh = MyLibrary::DB->dbh();
	my $q = qq(SELECT * FROM interface where name='login');
	my $interface = $dbh->selectrow_hashref($q);
        my $class = shift;
        my $self = {
		username => '1',
		password => '1',
		html => $interface->{'html'},
		@_
	};
	return bless $self, $class;
} # end sub login

1;
