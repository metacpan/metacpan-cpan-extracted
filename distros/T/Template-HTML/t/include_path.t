# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Mangle.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('Template::HTML') };

#########################

my $template = eval {
    Template::HTML->new(
        INCLUDE_PATH => 't/',
    );
};

is( ref $template, 'Template::HTML', 'Create new Template::HTML object' );

BAIL_OUT "Couldn't create Template::HTML instance" unless ref $template eq 'Template::HTML';

is ( $template->process('include_path.tt2'), 1, 'process template from include path' );

$template = eval {
    Template::HTML->new({
        INCLUDE_PATH => 't/',
    });
};

is( ref $template, 'Template::HTML', 'Create new Template::HTML object' );

BAIL_OUT "Couldn't create Template::HTML instance" unless ref $template eq 'Template::HTML';

is ( $template->process('include_path.tt2'), 1, 'process template from include path' );
