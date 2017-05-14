package Template::Flute::Database::Rose;

use strict;
use warnings;

use Rose::DB;

use Template::Flute::Iterator::Rose;

=head1 NAME

Template::Flute::Database::Rose - Database abstraction for Template::Flute

=head1 SYNOPSIS


=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute::Database::Rose object with either a DBI handle
passed as dbh parameter or the following parameters:

=over 4

=item dbname

Database name.

=item dbuser

Database user.

=item dbpass

Database password.

=back

=cut

# Constructor
sub new {
	my ($class, @args) = @_;
	my ($self);
	
	$class = shift;
	$self = {@args};

	bless $self, $class;
	
	$self->_initialize();
	
	return $self;
}

# Initialization routine
sub _initialize {
	my ($self) = @_;
	
	my %rose_parms;
	
	if ($self->{dbh}) {
		# database handle exist already
	}
	else {
		%rose_parms = (domain => 'default',
					   type => 'default',
					   driver => $self->{dbtype},
					   database => $self->{dbname},
					   username => $self->{dbuser},
					   password => $self->{dbpass},
					  );
		
		Rose::DB->register_db(%rose_parms);
		$self->{rose} = new Rose::DB;
		$self->{dbh} = $self->{rose}->dbh();
	}
}

=head2 METHODS

=head3 build

Returns iterator from query.

=cut

# Build query and return iterator
sub build {
	my ($self, $query) = @_;
	my ($iter);

	$iter = new Template::Flute::Iterator::Rose(dbh => $self->{dbh},
											   query => $query);
	$iter->build();

	return $iter;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
