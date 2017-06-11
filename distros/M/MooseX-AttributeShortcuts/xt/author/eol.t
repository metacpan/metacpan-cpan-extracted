use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MooseX/AttributeShortcuts.pm',
    'lib/MooseX/AttributeShortcuts/Trait/Attribute.pm',
    'lib/MooseX/AttributeShortcuts/Trait/Attribute/HasAnonBuilder.pm',
    'lib/MooseX/AttributeShortcuts/Trait/Role/Attribute.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.t',
    't/02-parameterized.t',
    't/03-lazy.t',
    't/05-extend.t',
    't/06-role.t',
    't/builder/anon-builder-conflict-toclass.t',
    't/builder/anon-builder-conflict-torole.t',
    't/builder/anon-role-role-class.t',
    't/builder/anon.t',
    't/builder/basic.t',
    't/clearer.t',
    't/constraint.t',
    't/funcs.pm',
    't/handles/coderef-class.t',
    't/handles/coderef.t',
    't/handles/metaclass.t',
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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
