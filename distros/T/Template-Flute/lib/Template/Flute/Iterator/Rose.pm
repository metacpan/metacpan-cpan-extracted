package Template::Flute::Iterator::Rose;

use strict;
use warnings;

use Rose::DB::Object::QueryBuilder qw(build_select);

=head1 NAME

Template::Flute::Iterator::Rose - Iterator class for Template::Flute

=cut

=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute::Iterator::Rose object with the following parameters:

=over 4

=item dbh

L<DBI> database handle.

=back

=cut

# Constructor
sub new {
	my ($class, @args) = @_;
	my ($self);
	
	$class = shift;
	$self = {@args};
	bless $self, $class;
}

=head1 METHODS

=head2 build

Builds database query. See L<Rose::DB::Object::QueryBuilder> for
instructions.

=cut

# Build method
sub build {
	my ($self) = @_;
	my ($dbref, $sql, $bind);

	$dbref = $self->{query};
	$dbref->{dbh} = $self->{dbh};
	$dbref->{query_is_sql} = 1;

	# prepare database query
	($sql, $bind) = build_select(%$dbref);

	$self->{sql} = $sql;
	$self->{bind} = $bind;
	
	return 1;
}

=head3 run

Executes database query.

=cut

sub run {
	my ($self) = @_;
	my ($sth);
	
	$sth = $self->{dbh}->prepare($self->{sql});
	$sth->execute(@{$self->{bind}});
	$self->{results}->{sth} = $sth;

	$self->{results}->{rows} = $sth->rows();
	return 1;
}

=head3 next

Returns next record in result set from database query or
undef if result set is exhausted.

=cut
	
sub next {
	my ($self) = @_;
	my ($record);

	unless ($self->{results}) {
		$self->run();
	}

	if (exists $self->{results}->{sth}) {
		unless ($record = $self->{results}->{sth}->fetchrow_hashref()) {
			# pending records depleted
			delete $self->{results}->{sth};
			$self->{results}->{valid} = 0;
		}
	}

	return $record;
};

=head3 count

Returns count of records in result set from database query.

=cut

sub count {
	my ($self) = @_;

	unless ($self->{results}) {
		$self->run();
	}

	return $self->{results}->{rows};
};

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
