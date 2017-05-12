use strict;
use warnings;
use lib 't/lib';

use TestHelper qw{$XFER_LOG};
use Test::More tests => 16;

BEGIN { use_ok('NcFTPd::Log::Parse::Xfer'); }

eval { NcFTPd::Log::Parse::Xfer->new('.') };
ok($@, 'should fail with a directory');

my $parser = NcFTPd::Log::Parse::Xfer->new($XFER_LOG);
my @entries = slurp_log($parser);

is(@entries, 7, 'should be 7 log entries');

# chmod
is_deeply($entries[0], {
    time       => '2010-01-11 15:42:17',
    process    => '#u5',
    operation   => 'C',
    pathname   => '/home/sshaw/cti/web/trunk/public/js/large-sprite.gif',
    mode       => '644',
    reserved1  => '',
    reserved2  => '',
    user       => 'cti-www',
    email      => '',
    host       => '24.216.233.19',
    session_id => 'S0u3WAAFv94A'
});

# delete
is_deeply($entries[1], {
    time       => '2010-01-11 12:47:44',
    process    => '#u2',
    operation  => 'D',
    pathname   => '/home/sshaw/.cshrc',
    reserved1  => '',
    reserved2  => '',
    reserved3  => '',
    user       => 'opc',
    email      => '',
    host       => '16.14.22.99',
    session_id => 'S0uObwACwXoA'
});

# mkdir
is_deeply($entries[2], {
    time       => '2010-01-11 13:37:20',
    process    => '#u4',
    operation  => 'M',
    pathname   => '/Users/BobABooey/Documents/2001/January/Second/Cal',
    reserved1  => '',
    reserved2  => '',
    reserved3  => '',
    user       => 'suemi',
    email      => '',
    host       => '186.14.2.22',
    session_id => 'S0uZ6AAEv9kA'
});

is_deeply($entries[3], {
    time       => '2010-01-11 14:35:00',
    process    => '#u4',
    operation  => 'N',
    source     => '/Users/ftp/docs/HP 2011 20100114.xml',
    reserved1  => 'to',
    destination=> '/Users/ftp/docs/HP PART II 2011 20100114.xml',
    reserved2  => '',
    user       => 'ftp',
    email      => 'sshaw@lucas.cis.temple.edu',
    host       => 'localhost',
    session_id => 'S0unlAAEwGoA'
});

# retrieve
is_deeply($entries[4], {
    time       => '2011-02-06 10:16:08',
    process    => '#u4',
    operation  => 'R',
    pathname   => '/home/sshaw/ruby-1.8.7-p302/misc/ruby-mode.el',
    size       => 41,
    duration   => 0.007,
    rate       => 5.856,
    user       => 'sshaw',
    email      => '',
    host       => '168.161.192.16',
    suffix     => '',
    status     => 'OK',
    type       => 'I',
    notes      => 'Po',
    start_of_transfer => 1294215368,
    session_id => 'TSQoxwAEEbkA',
    starting_size => 41,
    starting_offset => 0
});

# store
is_deeply($entries[5], {
    time      => '2010-01-05 00:00:59',
    process => '#u3',
    operation => 'S',
    pathname => '/a/file,with,commas.txt',
    size      => 25,
    duration  => 0.006,
    rate      => 4.389,
    user      => 'sshaw',
    email     => '',    
    host      => '1.2.3.4',
    suffix    => '',
    status    => 'OK',
    type      => 'I',
    notes     => 'PoSf',    
    start_of_transfer => 1294214460,
    session_id	      => 'TSQlOwADIaAA',
    starting_size     => 25,
    starting_offset   => 0
});

# listing
is_deeply($entries[6], {
    time       => '2011-01-05 00:15:55',
    process    => '#u4',
    operation  => 'T',
    pathname   => '/home/adelitas/20100101',
    status     => 'OK',
    ### 
    pattern    => '',
    recursion  => '',
    user       => '2M@nYL0G-z',
    email      => '',
    host       => 'my.odd--host.local',
    session_id => 'TSQouwAEEbgA'
});


$parser = NcFTPd::Log::Parse::Xfer->new($XFER_LOG, 
					expand => 1,
					filter => sub { 
					  $_->{operation} eq 'rename' || $_->{operation} eq 'delete'; 
					});
@entries = slurp_log($parser);
is(@entries, 2, 'filter should return 2 log entries');
is($entries[0]->{operation}, 'delete');
is($entries[1]->{operation}, 'rename');

$parser = NcFTPd::Log::Parse::Xfer->new($XFER_LOG, 
					filter => sub { 
					  $_->{operation} eq 'N' || $_->{operation} eq 'D'; 
					});
@entries = slurp_log($parser);
is(@entries, 2, 'filter should return 2 log entries');
is($entries[0]->{operation}, 'D');
is($entries[1]->{operation}, 'N');

