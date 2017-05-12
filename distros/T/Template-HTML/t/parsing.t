# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Mangle.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('Template::HTML') };

#########################

my $template = eval { Template::HTML->new(); };

is( ref $template, 'Template::HTML', 'Create new Template::HTML object' );

BAIL_OUT "Couldn't create Template::HTML instance" unless ref $template eq 'Template::HTML';

my $vars = { test => "< Test & stuff >" };

my %tests = (
    'test'                           => '&lt; Test &amp; stuff &gt;',
    'test.remove(">")'               => '&lt; Test &amp; stuff ',
    'test | upper'                   => '&lt; TEST &amp; STUFF &gt;',
    'test | truncate(12)'            => '&lt; Test &amp; ...',
    'test | html'                    => '&amp;lt; Test &amp;amp; stuff &amp;gt;',
    'test | none'                    => $vars->{test},
    'test | none | upper'            => uc $vars->{test},
    'test | upper | none'            => uc $vars->{test},
    'test == "hello" ? "yes" : "no"' => 'no',
    'test | replace("&","and")'      => '&lt; Test and stuff &gt;',
);

while ( my ($in, $expected) = each %tests ) {
    my $out = '';
    $in = "[% $in %]";
    my $success = $template->process(\$in, $vars, \$out);
    unless ( $success ) {
        diag('Template Toolkit error: ' . $template->error);
    }
    is($out, $expected, $in);
}

