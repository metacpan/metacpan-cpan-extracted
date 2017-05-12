package MyApp::Pages::Foo;
use strict;
use base qw(MyApp::Pages);

__PACKAGE__->tmpl_dirname('foo');

sub dispatch_bar {}

1;
