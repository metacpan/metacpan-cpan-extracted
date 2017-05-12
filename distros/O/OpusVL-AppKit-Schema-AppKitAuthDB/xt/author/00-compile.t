use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.053

use Test::More;

plan tests => 25;

my @module_files = (
    'OpusVL/AppKit/RolesFor/Auth.pm',
    'OpusVL/AppKit/RolesFor/Schema/AppKitAuthDB.pm',
    'OpusVL/AppKit/RolesFor/Schema/AppKitAuthDB/Result/Aclrule.pm',
    'OpusVL/AppKit/RolesFor/Schema/AppKitAuthDB/Result/Parameter.pm',
    'OpusVL/AppKit/RolesFor/Schema/AppKitAuthDB/Result/Role.pm',
    'OpusVL/AppKit/RolesFor/Schema/AppKitAuthDB/Result/User.pm',
    'OpusVL/AppKit/RolesFor/Schema/DataInitialisation.pm',
    'OpusVL/AppKit/RolesFor/Schema/LDAPAuth.pm',
    'OpusVL/AppKit/RolesFor/UserSetupResultSet.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/Aclfeature.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/AclfeatureRole.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/Aclrule.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/AclruleRole.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/Parameter.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/ParameterDefault.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/Role.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/RoleAdmin.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/RoleAllowed.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/User.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/UsersData.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/UsersParameter.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/Result/UsersRole.pm',
    'OpusVL/AppKit/Schema/AppKitAuthDB/ResultSet/Aclfeature.pm'
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
        and not eval { blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


