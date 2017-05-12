use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 35;

my @module_files = (
    'Excel/Template/Plus/TTAutoFilter.pm',
    'HTML/FormFu/Validator/OpusVL/AppKit/CurrentPasswordValidator.pm',
    'OpusVL/AppKit.pm',
    'OpusVL/AppKit/Action/AppKitForm.pm',
    'OpusVL/AppKit/Builder.pm',
    'OpusVL/AppKit/Controller/AppKit.pm',
    'OpusVL/AppKit/Controller/AppKit/Admin.pm',
    'OpusVL/AppKit/Controller/AppKit/Admin/Access.pm',
    'OpusVL/AppKit/Controller/AppKit/Admin/Users.pm',
    'OpusVL/AppKit/Controller/AppKit/User.pm',
    'OpusVL/AppKit/Controller/Root.pm',
    'OpusVL/AppKit/Controller/Search.pm',
    'OpusVL/AppKit/Form/Login.pm',
    'OpusVL/AppKit/FormFu/Constraint/AppKitPassword.pm',
    'OpusVL/AppKit/FormFu/Constraint/AppKitUsername.pm',
    'OpusVL/AppKit/LDAPAuth.pm',
    'OpusVL/AppKit/Model/AppKitAuthDB.pm',
    'OpusVL/AppKit/Plugin/AppKit.pm',
    'OpusVL/AppKit/Plugin/AppKit/FeatureList.pm',
    'OpusVL/AppKit/Plugin/AppKit/Node.pm',
    'OpusVL/AppKit/Plugin/AppKitControllerSorter.pm',
    'OpusVL/AppKit/RolesFor/Controller/GUI.pm',
    'OpusVL/AppKit/RolesFor/Model/LDAPAuth.pm',
    'OpusVL/AppKit/RolesFor/Plugin.pm',
    'OpusVL/AppKit/TraitFor/Controller/Login/NewSessionIdOnLogin.pm',
    'OpusVL/AppKit/TraitFor/Controller/Login/SetHomePageFlag.pm',
    'OpusVL/AppKit/View/AppKitTT.pm',
    'OpusVL/AppKit/View/Download.pm',
    'OpusVL/AppKit/View/DownloadFile.pm',
    'OpusVL/AppKit/View/Email.pm',
    'OpusVL/AppKit/View/Excel.pm',
    'OpusVL/AppKit/View/JSON.pm',
    'OpusVL/AppKit/View/PDF/Reuse.pm',
    'OpusVL/AppKit/View/SimpleXML.pm'
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

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


