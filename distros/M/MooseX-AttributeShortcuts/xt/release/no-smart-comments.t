#!/usr/bin/env perl
#
# This file is part of MooseX-AttributeShortcuts
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More 0.88;

eval "use Test::NoSmartComments";
plan skip_all => 'Test::NoSmartComments required for checking comment IQ'
    if $@;

no_smart_comments_in("lib/MooseX/AttributeShortcuts.pm");
no_smart_comments_in("lib/MooseX/AttributeShortcuts/Trait/Attribute.pm");
no_smart_comments_in("lib/MooseX/AttributeShortcuts/Trait/Attribute/HasAnonBuilder.pm");
no_smart_comments_in("lib/MooseX/AttributeShortcuts/Trait/Role/Attribute.pm");
no_smart_comments_in("t/00-compile.t");
no_smart_comments_in("t/00-report-prereqs.t");
no_smart_comments_in("t/02-parameterized.t");
no_smart_comments_in("t/03-lazy.t");
no_smart_comments_in("t/05-extend.t");
no_smart_comments_in("t/06-role.t");
no_smart_comments_in("t/builder/anon-builder-conflict-toclass.t");
no_smart_comments_in("t/builder/anon-builder-conflict-torole.t");
no_smart_comments_in("t/builder/anon-role-role-class.t");
no_smart_comments_in("t/builder/anon.t");
no_smart_comments_in("t/builder/basic.t");
no_smart_comments_in("t/clearer.t");
no_smart_comments_in("t/constraint.t");
no_smart_comments_in("t/funcs.pm");
no_smart_comments_in("t/handles/coderef-class.t");
no_smart_comments_in("t/handles/coderef.t");
no_smart_comments_in("t/handles/metaclass.t");
no_smart_comments_in("t/inline_subtyping/basic.t");
no_smart_comments_in("t/inline_subtyping/coercion.t");
no_smart_comments_in("t/inline_subtyping/with_coercion.t");
no_smart_comments_in("t/is/rwp.t");
no_smart_comments_in("t/isa/mooish.t");
no_smart_comments_in("t/isa_instance_of.t");
no_smart_comments_in("t/metaclasses.t");
no_smart_comments_in("t/old/01-basic.t");
no_smart_comments_in("t/old/04-clearer-and-predicate.t");
no_smart_comments_in("t/old/07-trigger.t");
no_smart_comments_in("t/predicate.t");
no_smart_comments_in("t/trigger.t");

done_testing();
