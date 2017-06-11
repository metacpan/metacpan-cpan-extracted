use Test::More tests => 5;
use Test::TempDir::Tiny;
use Module::Starter qw/Module::Starter::Smart/;
use File::Spec;

my $tempdir = tempdir();
my $root = File::Spec->catdir($tempdir, 'Modern-Mo');

{
    local $SIG{__WARN__} = sub {
        warn $_[0] unless $_[0] =~ /^Added to MANIFEST/;
    };

    Module::Starter->create_distro(
	author   => 'me',
        builder  => 'ExtUtils::MakeMaker',
        modules  => ['Modern::Mo'],
        email    => 'me@there.com',
        dir      => $root,
    );
}

ok(-d $root, 'Module root exists');

my $file = File::Spec->catfile($root, qw(lib Modern Mo.pm));
ok(-f $file, 'Module file exists');

push @INC, File::Spec->catdir($root, 'lib');
require_ok('Modern::Mo');

{
    local $SIG{__WARN__} = sub {
        warn $_[0] unless $_[0] =~ /^Added to MANIFEST/;
    };

    Module::Starter->create_distro(
	author   => 'me',
        builder  => 'ExtUtils::MakeMaker',
        modules  => ['Modern::Mumu'],
        email    => 'me@there.com',
        dir      => $root,
    );
}

# ok(-d $root, 'Module root exists');

my $file = File::Spec->catfile($root, qw(lib Modern Mumu.pm));
ok(-f $file, 'Additional module file exists');

# push @INC, File::Spec->catdir($root, 'lib');
require_ok('Modern::Mumu');
