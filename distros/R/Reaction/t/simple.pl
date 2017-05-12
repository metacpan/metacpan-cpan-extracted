use strict;
use warnings;

use lib 'lib';
use ComponentUI;

my $ctx = bless({ stash => {} }, 'ComponentUI');

my $view = ComponentUI->view('TT');

print $view->render($ctx, 'textfield', { self => { label => 'Label', message => 'Status message.' }, blocks => {} });
