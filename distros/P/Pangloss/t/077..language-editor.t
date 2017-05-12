#!/usr/bin/perl

##
## Tests for Pangloss::Application::LanguageEditor
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Pixie;
use Error qw( :try );

use TestApp;
use CollectionTests;

use Pangloss::Language qw(dir_LTR dir_RTL);
use Pangloss::Language::Error;
BEGIN { use_ok("Pangloss::Application::LanguageEditor") }

my $app  = new TestApp()->store( new Pixie()->connect('memory') );
my $ed   = new Pangloss::Application::LanguageEditor()->parent( $app );
my $lang = new Pangloss::Language()
  ->iso_code( 'test' )
  ->name( 'test language' )
  ->direction( dir_LTR )
  ->creator( 'test user' )
  ->date( 1 );

## try adding a language
CollectionTests->test_add( $ed, $lang );
CollectionTests->test_add_existing( $ed, $lang );


## try listing languages
CollectionTests->test_list( $ed );


## try getting a language
CollectionTests->test_get( $ed, $lang );
CollectionTests->test_get_non_existent( $ed, $lang );


## try modifying some details
my $new_lang = $lang->clone
  ->iso_code( 'test2' )
  ->name( 'lang renamed' )
  ->direction( dir_LTR );

my $view = CollectionTests->test_modify( $ed, $lang, $new_lang );

if ($view) {
    is( $view->{language}->iso_code, 'test2',    'iso code changed' );
    is( $view->{language}->name, 'lang renamed', 'name changed' );
    is( $view->{language}->direction, dir_LTR,   'direction changed' );
}


## try removing a language
CollectionTests->test_remove( $ed, $new_lang );
CollectionTests->test_remove_non_existent( $ed, $new_lang );

