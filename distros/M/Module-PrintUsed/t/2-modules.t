use Test;

BEGIN { plan tests => 3 };

use Module::PrintUsed;

my @modules = Module::PrintUsed::ModulesList();
ok(1);

my ($w, $s) = 0;

# must find at least warnings and strict

foreach (@modules) {
    die "No name given" unless $_->{name}; # must be given
    die "No path given" unless $_->{path}; # must be given
    die "No version given" unless defined $_->{version}; # should at least be an empty string

    $w = 1 if $_->{name} eq 'warnings';
    $s = 1 if $_->{name} eq 'strict';
}

ok($w);
ok($s);


