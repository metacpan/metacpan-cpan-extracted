use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

#== TESTS ===========================================================================

use TM;

require_ok( 'TM::Synchronizable::Null' );

can_ok 'TM::Synchronizable::Null', 'apply';

Class::Trait->apply ('TM' => qw(TM::Synchronizable::Null));

{ # structural tests
    my $tm = new TM (baseuri => 'tm:');
    ok ($tm->isa('TM'),                 'correct class');

    ok ($tm->does ('TM::Synchronizable::Null'), 'trait: Null');
    ok ($tm->can ('sync_in'),             'trait: can in');
    ok ($tm->can ('sync_out'),            'trait: can out');
}

{
    my $tm = new TM (url => 'io:stdin');
    $tm->sync_in;
    $tm->sync_out;
    is ($tm->{_ins},  1,     'once in');
    is ($tm->{_outs}, undef, 'never out');

    $tm->url ('io:stdout');
    $tm->sync_in;
    $tm->sync_out;
    is ($tm->{_ins},  2,     'once in');
    is ($tm->{_outs}, undef, 'not out');

    $tm->consolidate; # do something, whatever
    $tm->sync_out;
    is ($tm->{_ins},  2,     'once in');
    is ($tm->{_outs}, 1,     'finally out');

}

__END__
