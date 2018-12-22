use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 15 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Net/Async/Trello.pm',
    'Net/Async/Trello/Board.pm',
    'Net/Async/Trello/Card.pm',
    'Net/Async/Trello/CardAction.pm',
    'Net/Async/Trello/Common.pm',
    'Net/Async/Trello/Generated/Board.pm',
    'Net/Async/Trello/Generated/Card.pm',
    'Net/Async/Trello/Generated/CardAction.pm',
    'Net/Async/Trello/Generated/List.pm',
    'Net/Async/Trello/Generated/Member.pm',
    'Net/Async/Trello/Generated/Organisation.pm',
    'Net/Async/Trello/List.pm',
    'Net/Async/Trello/Member.pm',
    'Net/Async/Trello/Organisation.pm',
    'Net/Async/Trello/WS.pm'
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


