use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

use Time::HiRes qw ( time );

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

#== TESTS ===========================================================================

use TM;

require_ok( 'TM::ResourceAble' );

can_ok 'TM::ResourceAble', 'apply';

Class::Trait->apply ('TM' => 'TM::ResourceAble');

{ # structural tests
    my $tm = new TM (baseuri => 'tm:');
    ok ($tm->isa('TM'),                 'correct class');
    is ($tm->baseuri, 'tm:',            'baseuri ok');

    ok ($tm->does ('TM::ResourceAble'), 'trait: ResourceAble');
    ok ($tm->can ('url'),               'trait: can url');
}

{
    my $tm = new TM (baseuri => 'tm:');

    is ($tm->url ('http://whatever'), $tm->url, 'url setter');

    my $t = time;
    $tm->url ('io:stdin');
    ok ($t <= $tm->mtime,     'io:stdin time');

    $tm->url ('io:stdout');
    is ($tm->mtime, 0,        'io:stdout time');

    $t = time;
    warn "# time on that platform gives: ".$t;  # get strange errors from Solaris?
    $tm->url ('inline:xxx');
    warn "# mtime gives: ". $tm->mtime;
    ok ($t >= $tm->mtime,             'inline: time');  # must be created
    ok ($tm->{created} == $tm->mtime, 'inline: time');
}

__END__

{
    my $tm = new TM (url => 'io:stdin');
    is ($tm->url, 'io:stdin', 'url survives constructor');
}

# TODO file mtime, http mtime


__END__

#-- setup ------------------------------------------

package Testus;

use TM::Resource;
use base qw(TM::Resource);

our $in  = 0;
our $out = 0;

sub _sync_in {
#    warn "innnn";
    $in++;
}

sub _sync_out {
#    warn "outtttt";
    $out++;
}

sub last_mod {
#    warn "lasttttttttt";
    return time();
}
1;


{
    my $tm = new Testus (url => 'xxx:');

    $tm->sync_in;
    sleep 2;
    $tm->sync_out;

    Test::More::is ($Testus::in,  1, 'synced in once');
    Test::More::is ($Testus::out, 0, 'synced out never');
    $tm->consolidate; # do something, whatever
    $tm->sync_out;
    Test::More::is ($Testus::out, 1, 'synced out now');
}

__END__


