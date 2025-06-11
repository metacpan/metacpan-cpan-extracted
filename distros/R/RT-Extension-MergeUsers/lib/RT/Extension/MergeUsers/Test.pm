use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/home/brad/BPS/work/rts/rt6-plugin-testing-rt5/local/lib /home/brad/BPS/work/rts/rt6-plugin-testing-rt5/lib);

package RT::Extension::MergeUsers::Test;

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
        unshift @{ $args{'requires'} }, 'RT::Extension::MergeUsers';
    } else {
        $args{'testing'} = 'RT::Extension::MergeUsers';
    }

    $class->SUPER::import( %args );
    $class->export_to_level(1);

    require RT::Extension::MergeUsers;
}

1;

