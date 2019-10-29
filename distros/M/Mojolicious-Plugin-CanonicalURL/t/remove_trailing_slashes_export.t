use Mojo::Base -strict;
use Test::More;
use Mojo::Path;

use Mojolicious::Plugin::CanonicalURL 'remove_trailing_slashes';

is remove_trailing_slashes('/remove_trailing_slashes///'), '/remove_trailing_slashes', 'three trailing slashes removed';
is remove_trailing_slashes('/remove_trailing_slashes//'), '/remove_trailing_slashes', 'two trailing slashes removed';
is remove_trailing_slashes('/remove_trailing_slashes/'), '/remove_trailing_slashes', 'one trailing slashe removed';
is remove_trailing_slashes('/remove_trailing_slashes'), '/remove_trailing_slashes', 'no trailing slashes returns original value';

is remove_trailing_slashes(Mojo::Path->new('/remove_trailing_slashes///')), '/remove_trailing_slashes', 'remove_trailing_slashes accepts objects that overload ""';

done_testing;
