use Mojo::Base -strict;
use Test::More;
use Mojo::File 'path';

use lib path(__FILE__)->sibling('lib')->to_string;
use Mojolicious::Plugin::CanonicalURL::Tester;

Mojolicious::Plugin::CanonicalURL::Tester->new->canonicalize_before_render(0)->test;

done_testing;
