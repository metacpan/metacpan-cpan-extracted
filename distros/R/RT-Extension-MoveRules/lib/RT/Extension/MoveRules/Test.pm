use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt3/local/lib /opt/rt3/lib);

package RT::Extension::MoveRules::Test;

our @ISA;
BEGIN {
    local $@;
    eval { require RT::Test; 1 } or do {
        require Test::More;
        Test::More::BAIL_OUT(
            "requires 3.8 to run tests. Error:\n$@\n"
            ."You may need to set PERL5LIB=/path/to/rt/lib"
        );
    };
    push @ISA, 'RT::Test';
}

sub import {
    my $class = shift;
    my %args  = @_;

    $args{'requires'} ||= [];
    if ( $args{'testing'} ) {
        unshift @{ $args{'requires'} }, 'RT::Extension::MoveRules';
    } else {
        $args{'testing'} = 'RT::Extension::MoveRules';
    }
    unshift @{ $args{'requires'} }, 'RT::Extension::ColumnMap';
    unshift @{ $args{'requires'} }, 'RT::Condition::Complex';

    $class->SUPER::import( %args );
    $class->export_to_level(1);

    require RT::Extension::MoveRules;
}

1;

