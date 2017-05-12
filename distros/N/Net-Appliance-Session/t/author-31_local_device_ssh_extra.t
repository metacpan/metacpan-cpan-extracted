#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


BEGIN {
  if ($ENV{NOT_AT_HOME}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests can only be run by the author when at home');
  }
}

use strict; use warnings FATAL => 'all';
use Test::More 0.88;
#use Data::Dumper;

BEGIN { use_ok( 'Net::Appliance::Session') }

my $s = new_ok( 'Net::Appliance::Session' => [{
    transport => "SSH",
    ($^O eq 'MSWin32' ?
        (app => "$ENV{HOMEPATH}\\Desktop\\plink.exe") : () ),
    host => '172.16.20.55',
    personality => "ios",
    connect_options => {
        shkc => 0,
        opts => [
            '-o', 'CheckHostIP=no',
        ],
    },
}]);

my @lines = ();
ok( $s->connect({
    username => 'Cisco',
    password => ($ENV{IOS_PASS} || 'letmein'),
}), 'connected' );

# reported bug about using pipe command
ok( $s->cmd('show ver | i PCA'), 'ran show ver - pipe for PCA' );
@lines = $s->last_response;
#print STDERR Dumper \@lines;
#print STDERR $s->last_response;
cmp_ok( (scalar @lines), '==', 2, 'two lines of ver' );
unlike( scalar $s->cmd('show ver | i Processor'), qr/^\|/, 'no pipe at start of output' );

# bug about stitching together of output
ok( $s->cmd('show ver'), 'ran show ver' );
@lines = $s->last_response;
#print STDERR Dumper \@lines;
#print STDERR $s->last_response;
cmp_ok( (scalar @lines), '==', 47, '47 lines of ver' );

# reported bug about control characters affecting number of lines
ok( $s->begin_privileged, 'move to privileged mode' );
ok( eval{$s->cmd('terminal width 512');1}, 'set terminal width' );
ok( $s->cmd('verify /md5 flash:c1140-k9w7-mx.124-25d.JA/c1140-k9w7-mx.124-25d.JA 5c45e360eb702702f29c5120ef4200fd'), 'ran verify md5' );
@lines = $s->last_response;
#print STDERR Dumper \@lines;
#print STDERR $s->last_response;
cmp_ok( (scalar @lines), '==', 2, 'two lines of verify' );

#ok( eval{$s->close;1}, 'disconnected' );
eval{$s->close};
done_testing;
