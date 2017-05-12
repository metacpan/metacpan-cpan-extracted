use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.039

use Test::More  tests => 23 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'POE/Component/IRC/Plugin/AntiSpamMailTo.pm',
    'POE/Component/IRC/Plugin/BrowserSupport.pm',
    'POE/Component/IRC/Plugin/CSS/Minifier.pm',
    'POE/Component/IRC/Plugin/CSS/PropertyInfo.pm',
    'POE/Component/IRC/Plugin/CSS/PropertyInfo/Data.pm',
    'POE/Component/IRC/Plugin/CSS/SelectorTools.pm',
    'POE/Component/IRC/Plugin/ColorNamer.pm',
    'POE/Component/IRC/Plugin/Google/PageRank.pm',
    'POE/Component/IRC/Plugin/HTML/AttributeInfo.pm',
    'POE/Component/IRC/Plugin/HTML/AttributeInfo/Data.pm',
    'POE/Component/IRC/Plugin/HTML/HTML/ElementInfo.pm',
    'POE/Component/IRC/Plugin/JavaScript/Minifier.pm',
    'POE/Component/IRC/Plugin/Syntax/Highlight/CSS.pm',
    'POE/Component/IRC/Plugin/Syntax/Highlight/HTML.pm',
    'POE/Component/IRC/Plugin/Validator/CSS.pm',
    'POE/Component/IRC/Plugin/Validator/HTML.pm',
    'POE/Component/IRC/Plugin/WWW/Alexa/TrafficRank.pm',
    'POE/Component/IRC/Plugin/WWW/Cache/Google.pm',
    'POE/Component/IRC/Plugin/WWW/DoctypeGrabber.pm',
    'POE/Component/IRC/Plugin/WWW/GetPageTitle.pm',
    'POE/Component/IRC/Plugin/WWW/HTMLTagAttributeCounter.pm',
    'POE/Component/IRC/Plugin/WWW/Lipsum.pm',
    'POE/Component/IRC/PluginBundle/WebDevelopment.pm'
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


