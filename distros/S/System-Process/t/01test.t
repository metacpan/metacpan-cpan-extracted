use strict;
use warnings;

use Test::More tests => 17;

use File::Temp qw/ tempfile /;
use Data::Dumper;

use constant CLASS_NAME => 'System::Process::Unit';

if ($^O =~ m/MSWin32/is) {
    BAIL_OUT "Not implemented for windows yet.";
}

my $pi;
my $pid = $$;
my $hup;
my $croak;


$SIG{HUP} = sub { $hup = 1; };


BEGIN { use_ok( "System::Process" ) }

diag( "System Process $System::Process::VERSION" );


my ( $fh, $filename ) = tempfile( 'tempfileXXXXXX', TMPDIR => 1, UNLINK => 1 );


#
# Empty pidfile must be opened with no croak and with empty result
#
$pi = pidinfo file => $filename;

is( $pi, undef, 'empty result for empty file' );

#
# Non digital pid must croak
#
$croak = undef;
eval {
    $pi = pidinfo(pid=>'abcd');
    1;
} or do {
    $croak = 1;
};

ok $croak, 'pid with non-digits sequence';

#
# Too big pid must croak
#
$croak = undef;
eval {
    $pi = pidinfo(pid=> 100500 ** 4);
    1;
} or do {
    $croak = 1;
};

ok $croak, 'too big pid';

#
# We want croak for empty params
#
$croak = undef;

eval {
    $pi = pidinfo();
    1;
} or do {
    $croak = 1;
};

ok $croak, 'no croak for empty params';


#
# We want croak for multiple params
#
$croak = undef;

eval {
    $pi = pidinfo( pid => '123', file => $filename );
    1;
} or do {
    $croak = 1;
};

ok $croak, 'no croak for multiple params';


#
# We want croak for no digit pids
#
$croak = undef;

eval {
    $pi = pidinfo( pid => 'is not pid' );
    1;
} or do {
    $croak = 1;
};

ok $croak, 'no croak for wrong params';


#
# Whether is it possible to create by file
#
print $fh $pid;
close $fh;

$pi = pidinfo file => $filename;

isa_ok( $pi, CLASS_NAME );
is( $pi->pid(), $pid, 'check pid' );


#
# Whether is it possible to create by pid
#
$pi = pidinfo pid => $pid;

isa_ok( $pi, CLASS_NAME );
is( $pi->pid(), $pid, 'check pid' );


#
# Check the parsing
#
$pi = pidinfo pid => $pid;

my $output = << 'END';
    cpu user command
    12345 testing some command line
END

$pi->parse_n_generate( split /\n/, $output );

is $pi->cpu, 12345, 'check first cloumn';
is $pi->user, 'testing', 'check second cloumn';
is $pi->command, 'some command line', 'check last (command line) cloumn';


#
# Check is this possible to send signal to myself
#
$pi = pidinfo pid => $pid;

ok $pi->cankill, 'can not send signal to me';

$pi->refresh();

ok($pi, "refresh is ok");


#
# Check whether signals work
#
$pi = pidinfo pid => $pid;
undef $hup;

$pi->kill( 1 );
sleep 1;

ok $hup, 'hup signal is not acepted';


done_testing();

