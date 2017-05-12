#!/usr/bin/perl

##
## Tests for Pangloss::Application
##

use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Error qw( :try );

BEGIN { use_ok("Pangloss::Application") }

my $app = new Pangloss::Application;

isa_ok( $app, 'Pangloss::Application', 'new' );
isa_ok( $app->category_editor, 'Pangloss::Application::CategoryEditor', 'category editor' );
isa_ok( $app->concept_editor,  'Pangloss::Application::ConceptEditor',  'concept editor' );
isa_ok( $app->language_editor, 'Pangloss::Application::LanguageEditor', 'language editor' );
isa_ok( $app->term_editor,     'Pangloss::Application::TermEditor',     'term editor' );
isa_ok( $app->user_editor,     'Pangloss::Application::UserEditor',     'user editor' );
isa_ok( $app->searcher,        'Pangloss::Application::Searcher',       'searcher' );

