use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.039

use Test::More  tests => 20 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Net/OBEX.pm',
    'Net/OBEX/FTP.pm',
    'Net/OBEX/Packet/Headers.pm',
    'Net/OBEX/Packet/Headers/Base.pm',
    'Net/OBEX/Packet/Headers/Byte1.pm',
    'Net/OBEX/Packet/Headers/Byte4.pm',
    'Net/OBEX/Packet/Headers/ByteSeq.pm',
    'Net/OBEX/Packet/Headers/Unicode.pm',
    'Net/OBEX/Packet/Request.pm',
    'Net/OBEX/Packet/Request/Abort.pm',
    'Net/OBEX/Packet/Request/Base.pm',
    'Net/OBEX/Packet/Request/Connect.pm',
    'Net/OBEX/Packet/Request/Disconnect.pm',
    'Net/OBEX/Packet/Request/Get.pm',
    'Net/OBEX/Packet/Request/Put.pm',
    'Net/OBEX/Packet/Request/SetPath.pm',
    'Net/OBEX/Response.pm',
    'Net/OBEX/Response/Connect.pm',
    'Net/OBEX/Response/Generic.pm',
    'XML/OBEXFTP/FolderListing.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


