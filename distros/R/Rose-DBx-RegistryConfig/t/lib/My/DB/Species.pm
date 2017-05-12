package My::DB::Species;
use base qw( My::DB );

use strict;
use warnings;

sub get_species_list {
    my ($self) = @_;

    my $dbh = $self->dbh();
    my $sth = $dbh->prepare_cached( q{
        SELECT name, common_name
        FROM species
    } );
    $sth->execute();

    my @species;
    while( my $s = $sth->fetchrow_hashref() ) {
        push @species, $s;
    }
    return \@species;
}

#-------
1;

__END__

=for Purpose
    This module exists as a demonstration and test of subclassing a "local"
    Rose::DBx::RegistryConfig subclass, as might be done to create a model
    class for a particular table.

=cut

