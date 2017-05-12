use Test::More tests => 2;
use Template::Context;

use_ok('Template::Plugin::CSS::LESSp');

isa_ok(
    Template::Plugin::CSS::LESSp->new( Template::Context->new ),
    'Template::Plugin::CSS::LESSp'
);
