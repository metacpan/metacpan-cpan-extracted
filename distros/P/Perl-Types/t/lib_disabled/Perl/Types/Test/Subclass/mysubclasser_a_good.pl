#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: 'Doody Preschool' >>>
# <<< EXECUTE_SUCCESS: 'calvin,susie' >>>
# <<< EXECUTE_SUCCESS: 'Howdy Preschool; ABCDEFG' >>>
# <<< EXECUTE_SUCCESS: 'Busy Beaver; orange yellow red' >>>
# <<< EXECUTE_SUCCESS: 'Busy Beaver; castle' >>>
# <<< EXECUTE_SUCCESS: 'alvin,simon,theodore' >>>
# <<< EXECUTE_SUCCESS: 'Busy Beaver' >>>
# <<< EXECUTE_SUCCESS: 'chip,dale' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use Perl::Types::Test::Subclass::MySubclasserA_Good;

# [[[ SUBROUTINES ]]]
sub tardies {
    { my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Good $RETURN_TYPE };
    my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Good $retval
        = [ Perl::Types::Test::Subclass::MySubclasserA_Good->new(), Perl::Types::Test::Subclass::MySubclasserA_Good->new() ];
    $retval->[0]->{preschool} = 'Howdy Preschool';
    $retval->[1]->{preschool} = 'Doody Preschool';
    return $retval;
}

sub earlies {
    { my hashref::Perl::Types::Test::Subclass::MySubclasserA_Good $RETURN_TYPE };
    my hashref::Perl::Types::Test::Subclass::MySubclasserA_Good $retval
        = { 'susie' => Perl::Types::Test::Subclass::MySubclasserA_Good->new(), 'calvin' => Perl::Types::Test::Subclass::MySubclasserA_Good->new() };
    return $retval;
}
# [[[ OPERATIONS ]]]
my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Good $some_kids = tardies();
print $some_kids->[1]->{preschool} . "\n";

my hashref::Perl::Types::Test::Subclass::MySubclasserA_Good $more_kids = earlies();
my string $more_kids_keys = ( join q{,}, ( sort keys %{$more_kids} ) );
print $more_kids_keys . "\n";

my Perl::Types::Test::Subclass::MySubclasserA_Good $new_kid = $some_kids->[0]->building_blocks();
print $some_kids->[0]->{preschool} . "\n";

my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Good $friends = $new_kid->finger_paints();
print $new_kid->{preschool} . "\n";

my hashref::Perl::Types::Test::Subclass::MySubclasserA_Good $classmates = $friends->[1]->sand_box();
print $friends->[1]->{preschool} . "\n";
my string $classmates_keys = ( join q{,}, ( sort keys %{$classmates} ) );
print $classmates_keys . "\n";

my arrayref::Perl::Types::Test::Subclass::MySubclasserA_Good $others = swings();
print $others->[0]->{preschool} . "\n";

my hashref::Perl::Types::Test::Subclass::MySubclasserA_Good $peers = tinker_toys();
my string $peers_keys = ( join q{,}, ( sort keys %{$peers} ) );
print $peers_keys . "\n";
