use strict;
use warnings;
use lib 't/lib';

use TestHelper qw{$MISC_LOG};
use Test::More tests => 9;

BEGIN { use_ok('NcFTPd::Log::Parse::Misc'); }

eval { NcFTPd::Log::Parse::Misc->new('.') };
ok($@, 'should fail with a directory');

my $parser = NcFTPd::Log::Parse::Misc->new($MISC_LOG);
my @entries = slurp_log($parser);

is(@entries, 6, 'should be 6 log entries');
is_deeply($entries[0], {
    time    => '2011-01-13 00:01:58',
    process => '(main)',
    message => 'NcFTPd 2.8.3/615 Sep 04 2006 for linux-x86.'
});
		       
is_deeply($entries[1], {
    time    => '2011-01-13 00:01:58',
    process => '(main)',
    message => '/etc/ftpusers: No such file or directory.'
});

is_deeply($entries[2], {
    time    => '2011-01-13 00:03:04',
    process => '#u1',
    message => 'Password wrong for user sshaw from localhost.'	
});

is_deeply($entries[3], {
    time    => '2011-01-13 00:03:32',
    process => '(main)',
    message => 'Caught signal 2 (Interrupt), exiting.'
});

is_deeply($entries[4], {
    time    => '2011-01-13 00:03:32',
    process => '#u3',
    message => 'Caught signal 15 (Terminated), exiting.'
});

is_deeply($entries[5], {
    time    => '2011-01-13 00:03:34',
    process => '(main)',
    message => 'Exiting.'
});

