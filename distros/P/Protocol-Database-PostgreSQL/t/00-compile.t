use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 29 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Protocol/Database/PostgreSQL.pm',
    'Protocol/Database/PostgreSQL/Backend.pm',
    'Protocol/Database/PostgreSQL/Backend/AuthenticationRequest.pm',
    'Protocol/Database/PostgreSQL/Backend/BackendKeyData.pm',
    'Protocol/Database/PostgreSQL/Backend/BindComplete.pm',
    'Protocol/Database/PostgreSQL/Backend/CloseComplete.pm',
    'Protocol/Database/PostgreSQL/Backend/CommandComplete.pm',
    'Protocol/Database/PostgreSQL/Backend/CopyBothResponse.pm',
    'Protocol/Database/PostgreSQL/Backend/CopyData.pm',
    'Protocol/Database/PostgreSQL/Backend/CopyDone.pm',
    'Protocol/Database/PostgreSQL/Backend/CopyInResponse.pm',
    'Protocol/Database/PostgreSQL/Backend/CopyOutResponse.pm',
    'Protocol/Database/PostgreSQL/Backend/DataRow.pm',
    'Protocol/Database/PostgreSQL/Backend/EmptyQueryResponse.pm',
    'Protocol/Database/PostgreSQL/Backend/ErrorResponse.pm',
    'Protocol/Database/PostgreSQL/Backend/FunctionCallResponse.pm',
    'Protocol/Database/PostgreSQL/Backend/NoData.pm',
    'Protocol/Database/PostgreSQL/Backend/NoticeResponse.pm',
    'Protocol/Database/PostgreSQL/Backend/NotificationResponse.pm',
    'Protocol/Database/PostgreSQL/Backend/ParameterDescription.pm',
    'Protocol/Database/PostgreSQL/Backend/ParameterStatus.pm',
    'Protocol/Database/PostgreSQL/Backend/ParseComplete.pm',
    'Protocol/Database/PostgreSQL/Backend/PortalSuspended.pm',
    'Protocol/Database/PostgreSQL/Backend/ReadyForQuery.pm',
    'Protocol/Database/PostgreSQL/Backend/RowDescription.pm',
    'Protocol/Database/PostgreSQL/Client.pm',
    'Protocol/Database/PostgreSQL/Constants.pm',
    'Protocol/Database/PostgreSQL/Error.pm',
    'Protocol/Database/PostgreSQL/Message.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


