#!/usr/bin/perl

##
## Tests for Pangloss::Application::View
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More skip_all => 'not yet written!';

use Error qw( :try );

BEGIN { use_ok("Pangloss::Application::View") }

my $view = new Pangloss::Application::View();
ok( $view, 'new' ) || die "cannot proceed\n";

is( $view->add_error(1), $view, 'add_error' );
#is( $view->errors({}), $view, 'errors(set)' );
isa_ok( $view->errors, 'HASH', 'errors(get)' );

# keep this?
is( $view->current_user(2), $view, 'current_user(set)' );
is( $view->current_user, 2,        'current_user(get)' );

# lists
is( $view->users(3), $view, 'users(set)' );
is( $view->users, 3,        'users(get)' );

is( $view->categories(4), $view, 'categories(set)' );
is( $view->categories, 4,        'categories(get)' );

is( $view->concepts(5), $view, 'concepts(set)' );
is( $view->concepts, 5,        'concepts(get)' );

is( $view->terms(6), $view, 'terms(set)' );
is( $view->terms, 6,        'terms(get)' );

is( $view->languages(7), $view, 'languages(set)' );
is( $view->languages, 7,        'languages(get)' );

# business objects
is( $view->user(8), $view, 'user(set)' );
is( $view->user, 8,        'user(get)' );

is( $view->category(9), $view, 'category(set)' );
is( $view->category, 9,        'category(get)' );

is( $view->concept(10), $view, 'concept(set)' );
is( $view->concept, 10,        'concept(get)' );

is( $view->term(11), $view, 'term(set)' );
is( $view->term, 11,        'term(get)' );

is( $view->language(12), $view, 'language(set)' );
is( $view->language, 12,        'language(get)' );


#The following keys are added to the object as needed:
#
#    error    - associated error object
#    added    - true if the pangloss object was added
#    removed  - true if the pangloss object was removed
#    modified - true if the pangloss object was modified

$view->add
$view->remove
$view->modify

#get/set the appropriate hash, which may contain one or more Pangloss objects:
#
#    user
#    language
#    concept
#    category
#    term

#depending on the action performed.  This lets you chain things like this:

#    $view->add->{user}->{error}
#    $view->add->{user}->{added}

#And so on.
