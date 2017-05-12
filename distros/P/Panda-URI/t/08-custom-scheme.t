use strict;
use warnings;
use Test::More;
use Panda::URI qw/uri :const/;

package MyScheme;
use parent 'Panda::URI';
use strict;

sub hello { return $_[0]->scheme . '-' . $_[0]->host }

package main;

Panda::URI::register_scheme("myscheme", "MyScheme");

my $uri = uri('myscheme://mysite.com/a/b/c');
is(ref($uri), 'MyScheme');
is($uri, 'myscheme://mysite.com/a/b/c');

done_testing();
