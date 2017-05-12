use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

#== TESTS ===========================================================================

use TM;

#use Class::Trait;
#Class::Trait->initialize();

require_ok( 'TM::Serializable::Dumper' );

can_ok 'TM::Serializable::Dumper', 'apply';
can_ok 'TM::Serializable',         'apply';
can_ok 'TM::Synchronizable',       'apply';
can_ok 'TM::ResourceAble',         'apply';

Class::Trait->apply ('TM', qw(TM::Serializable::Dumper TM::Serializable TM::Synchronizable TM::ResourceAble));

{ # structural tests
    my $tm = new TM (baseuri => 'tm:');
    ok ($tm->isa('TM'),                 'correct class');

    ok ($tm->does ('TM::Serializable::Dumper'), 'trait: Dumper');
    ok ($tm->can ('sync_in'),             'trait: can in');
    ok ($tm->can ('sync_out'),            'trait: can out');
}

# create tmp file
my $tmp;
use IO::File;
use POSIX qw(tmpnam);
do { $tmp = tmpnam().".dump" ;  } until IO::File->new ($tmp, O_RDWR|O_CREAT|O_EXCL);

##warn "\n# short sleep, no worries";
sleep 1;
##warn "tmp is $tmp";

END { unlink <$tmp*>  || die "cannot unlink '$tmp' file, but I am finished anyway"; }

{
    my $tm = new TM (baseuri => 'tm:');
    $tm->url ('file:'.$tmp);
    $tm->internalize ('ramsti');                           # add a dummy topic
    $tm->sync_out;

    $tm->internalize ('rumsti');                           # add a dummy topic
    ok ($tm->mids ('rumsti'), 'added topic');              # make sure it's there

    utime time+1, time+1, $tmp;                            # fake that the file has changed
    
    $tm->sync_in;                                          # load the map again
#    warn Dumper $tm;
    ok (!$tm->mids ('rumsti'), 'added topic overwritten'); # make sure it's no longer there
    ok ( $tm->mids ('ramsti'), 'added topic written');     # make sure it's still there
}

__END__
