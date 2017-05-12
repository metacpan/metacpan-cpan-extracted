#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Deep;
use Test::NoWarnings;
use Module::ExtractUse;

my @tests=
  (
#1
    ['require_module("Some::Module");', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['Module::Runtime::require_module("Some::Module");', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['use_module("Some::Module");', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['Module::Runtime::use_module("Some::Module");', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['use_module("Some::Module", 1.23);', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['Module::Runtime::use_module("Some::Module", 1.23);', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['use_package_optimistically("Some::Module");', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['Module::Runtime::use_package_optimistically("Some::Module");', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['use_package_optimistically("Some::Module", 1.23);', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['Module::Runtime::use_package_optimistically("Some::Module", 1.23);', [qw(Some::Module)], undef, [qw(Some::Module)]],
    ['$foo->require_module("Some::Module");', undef, undef, undef ],
    ['$foo->use_module("Some::Module");', undef, undef, undef ],
    ['$foo->use_package_optimistically("Some::Module");', undef, undef, undef ],
    ['Other::Namespace::require_module("Some::Module");', undef, undef, undef ],
    ['use_module("Some::Module", "NotAVersion");', undef, undef, undef ],
    ['use_module("Some::Module", v1.23, "OtherArg");', undef, undef, undef ],
    ['use_module($Some::Variable);', undef, undef, undef ],
);


plan tests => (scalar @tests)*3+1;


foreach my $t (@tests) {
    my ($code, @expected)=@$t;
    my $p=Module::ExtractUse->new;
my $used = $p->extract_use(\$code);
    my @used = (
        $p->extract_use(\$code)->arrayref || undef,
        $p->extract_use(\$code)->arrayref_in_eval || undef,
        $p->extract_use(\$code)->arrayref_out_of_eval || undef,
    );

    for(my $i = 0; $i < @used; ++$i) {
        if (ref($expected[$i]) eq 'ARRAY') {
            cmp_bag($used[$i]||[],$expected[$i],$i.": ".$code);
        } elsif (!defined $expected[$i]) {
            is(undef,$used[$i],$i.": ".$code);
        } else {
            is($used[$i],$expected[$i],$i.": ".$code);
        }
    }
}
