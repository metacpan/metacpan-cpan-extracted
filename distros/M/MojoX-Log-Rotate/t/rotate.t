use strict;
use warnings;
use Test::More;
use Test::Differences;
use Test::MockTime 0.17 qw( :all );
use File::Slurp qw(slurp);
use MojoX::Log::Rotate;

sub suffix {
    my ($y, $m, $d, $h, $mi, $s) =  (localtime shift)[5, 4, 3, 2, 1, 0];
    sprintf("_%04d%02d%02d_%02d%02d%02d", $y+1900, $m+1, $d, $h, $mi, $s);
}

sub mock_sleep {
    set_fixed_time( time + shift );
}

set_fixed_time('01/01/2022 12:00:00', '%m/%d/%Y %H:%M:%S');
 
unlink 'test.log' if -f 'test.log';
my $start = time;
my $logger = MojoX::Log::Rotate->new(frequency => 2, path => 'test.log');
$logger->short(1);

is ref $logger, 'MojoX::Log::Rotate', 'constructor';
ok $logger->isa('Mojo::Log'), 'inheritance';
is $logger->path, 'test.log', 'path attribute';

my @rotations;
$logger->on(rotate => sub {
    my ($e, $r) = @_;
    push @rotations, [time(), $r];
});

$logger->info('first message');
ok -f $logger->path, 'log file exist';
mock_sleep(1);
$logger->info('second message');
mock_sleep(2);
$logger->info('third message');
mock_sleep(3);
$logger->info('fourth message');

$logger->handle->close; #let's unlink file

my @expected = (
                    [ $start + 3, { 
                        how => { rotated_file => 'test'.suffix($start+3).'.log' }, 
                        when => { last_rotate => $start } 
                    } ],
                    [ $start + 6, { 
                        how => { rotated_file => 'test'.suffix($start+6).'.log' }, 
                        when => { last_rotate => $start+3 } 
                    } ]
                );
eq_or_diff \@rotations, \@expected, 'rotations';

eq_or_diff [slurp($rotations[0][1]{how}{rotated_file})],
           [ 
            $logger->_short(info => 'first message'), 
            $logger->_short(info => 'second message'), 
           ],
           'first rotated log content';

eq_or_diff [slurp($rotations[1][1]{how}{rotated_file})],
           [ 
            $logger->_short(info => 'third message'),
           ],
           'second rotated log content';

eq_or_diff [slurp('test.log')],
           [ 
            $logger->_short(info => 'fourth message'),
           ],
           'remaining log content';

done_testing;

#cleanup temp log files
unlink $_ for grep { /^test(_\d{8}_\d{6})?\.log$/ } <test*.log>;