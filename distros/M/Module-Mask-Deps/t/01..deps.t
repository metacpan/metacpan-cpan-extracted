use strict;
use warnings;

use Cwd qw( cwd );
use File::Spec::Functions qw( catdir rel2abs );
use IPC::Open3;

use Test::More tests => 19;

use lib catdir qw( t lib );

BEGIN {
    use_ok('Module::Mask::Deps');
}

our @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

{
    local %INC = %INC;
    eval { require Foo };
    ok(!$@, 'relative lib not affected by mask') or diag $@;
}

# Turn off masking now
unimport Module::Mask::Deps;

{
    local %INC = %INC;
    eval { require Foo };
    ok(!$@, 'no Module::Mask::Deps') or diag $@;
}

{
    local $Module::Mask::Deps::Mask;

    eval { unimport Module::Mask::Deps };
    ok(!$@, "unimport with no object lives") or diag $@;
}

# Put abs path to local t/lib into @INC at run time
my $test_lib = rel2abs(catdir qw( t lib ));
unshift @INC, $test_lib;

{
    local %INC = %INC;
    import Module::Mask::Deps;

    eval { require Foo };
    ok(!$@, 'absolute form of relative path still ignored by mask') or diag $@;
}

my $root = cwd();
my ($dist_dir, @deps, %dep_lookup);

$dist_dir = catdir qw( t data Test-Dist1 );
chdir $dist_dir or die "Can't change to $dist_dir";

{
    local @INC = (catdir('lib'), @INC);
    local %INC = %INC;
    local $Module::Mask::Deps::Mask;

    eval { import Module::Mask::Deps };
    ok !$@, 'Masked deps for Test-Dist1' or diag $@;
}

@deps = Module::Mask::Deps->get_deps();
ok(@deps, "Got deps from $dist_dir");

%dep_lookup = map { $_ => 1 } @deps;

ok($dep_lookup{'Foo'}, 'picked up known dependency')
    or diag "Deps: ", map "$_\n", sort @deps;

# English has been core since perl 5
ok($dep_lookup{'English'}, 'picked up known core module');

{
    # simulate -I lib 
    local @INC = (catdir('lib'), @INC);

    # don't remember what we load
    local %INC = %INC;
    local $Module::Mask::Deps::Mask;

    # we should allow relative paths to be loaded
    eval { require 'test.pl'};
    ok(!$@, 'test.pl loaded OK') or diag $@;

    eval { import Module::Mask::Deps };
    ok(!$@, 'import Module::Mask::Deps on a valid distribution works');

    eval { require Test::Dist1 };
    ok(!$@, 'valid distribution loads OK') or diag $@;

    # Module::Mask should be installed and masked
    # this will need to be changed if Module::Mask ever becomes core!
    delete $INC{'Module/Mask.pm'};
    eval { require Module::Mask };
    ok($@, 'Module::Mask is masked');
}

$dist_dir = catdir qw( t data Test-Dist2 );
$dist_dir = rel2abs($dist_dir, $root);

chdir $dist_dir or die "Can't change to $dist_dir";

@deps = Module::Mask::Deps->get_deps();

ok(@deps, "Got deps from $dist_dir");

%dep_lookup = map { $_ => 1 } @deps;
ok($dep_lookup{'Foo'}, "picked up known dependency");

# English has been core since perl 5
ok($dep_lookup{'English'}, 'picked up known core module');

{
    local @INC = (catdir('lib'), @INC);
    local %INC = %INC;
    local $Module::Mask::Deps::Mask;

    eval { import Module::Mask::Deps };
    ok(!$@, 'import Module::Mask::Deps on a valid distribution works');

    eval { require Test::Dist2 };
    ok(!$@, 'valid distribution loads OK') or diag $@;
}

ok(!@warnings, 'no warnings generated') or diag join("\n", @warnings);

__END__

vim: ft=perl ts=8 sts=4 sw=4 sr et
