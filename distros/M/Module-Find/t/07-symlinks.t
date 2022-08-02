use strict;
use warnings;

use Test::More tests => 14;

use Module::Find qw(ignoresymlinks followsymlinks findsubmod findallmod);

use lib qw(./t/test);

my $dirName = "ModuleFindTest";
my $linkName = "./t/test/ModuleFindTestSymLink";

SKIP: {
    my $r = eval { symlink($dirName, $linkName) };
    skip "Symlinks not supported on this system", 14 if $@;
    skip "Unable to create symlink", 14 if $r == 0;

    # Ensure link was created and is actually a symlink
    ok(-l $linkName);

    my @l;

    # Default behaviour: follow symlinks -----------------------
    @l = findsubmod ModuleFindTestSymLink;    
    ok($#l == 0);
    ok($l[0] eq 'ModuleFindTestSymLink::SubMod');
    
    @l = findallmod ModuleFindTestSymLink;    
    ok($#l == 1);
    ok($l[0] eq 'ModuleFindTestSymLink::SubMod');
    ok($l[1] eq 'ModuleFindTestSymLink::SubMod::SubSubMod');


    # Switch off following symlinks ---------------------------
    ignoresymlinks();
    @l = findsubmod ModuleFindTestSymLink;    
    ok($#l == -1);
    
    @l = findallmod ModuleFindTestSymLink;    
    ok($#l == -1);


    # Re-enable it --------------------------------------------
    followsymlinks();
    @l = findsubmod ModuleFindTestSymLink;    
    ok($#l == 0);
    ok($l[0] eq 'ModuleFindTestSymLink::SubMod');
    
    @l = findallmod ModuleFindTestSymLink;    
    ok($#l == 1);
    ok($l[0] eq 'ModuleFindTestSymLink::SubMod');
    ok($l[1] eq 'ModuleFindTestSymLink::SubMod::SubSubMod');

    
    # Clean up
    unlink $linkName;
    ok(!-e $linkName);
}



