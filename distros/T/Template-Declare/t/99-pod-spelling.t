#!/usr/bin/env perl -w

use strict;
use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
plan skip_all => "Coverage tests only run for authors" unless (-d 'inc/.author');

add_stopwords(<DATA>);

local $ENV{LC_ALL} = 'C';
set_spell_cmd('aspell list -l en');

all_pod_files_spelling_ok();

__DATA__
API
CMS
Mixin
Mixins
PHP
Postprocessing
RDF
XUL
inline
invocant
mixin
mixins
mixin's
namespace
postprocessor
Zhang
namespaces
postprocessing
ATTR
OO
TAGNAME
TAGSET
TEMPLATENAME
WRAPPERNAME
LLC
attr
PARAMS
XHTML
Mozilla's
rdf
frob
init
lookup
nanotubes
postprocess
streamy
webpage
