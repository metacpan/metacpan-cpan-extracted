use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/AttributeShortcuts.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.t',
    't/02-parameterized.t',
    't/03-lazy.t',
    't/05-extend.t',
    't/06-role.t',
    't/builder/anon.t',
    't/builder/basic.t',
    't/clearer.t',
    't/constraint.t',
    't/funcs.pm',
    't/handles-coderef.t',
    't/handles-metaclass.t',
    't/inline_subtyping/basic.t',
    't/inline_subtyping/coercion.t',
    't/inline_subtyping/with_coercion.t',
    't/is/rwp.t',
    't/isa/mooish.t',
    't/isa_instance_of.t',
    't/metaclasses.t',
    't/old/01-basic.t',
    't/old/04-clearer-and-predicate.t',
    't/old/07-trigger.t',
    't/predicate.t',
    't/trigger.t'
);

notabs_ok($_) foreach @files;
done_testing;
