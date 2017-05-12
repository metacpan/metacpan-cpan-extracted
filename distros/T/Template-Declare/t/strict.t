use warnings;
use strict;

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template oops => sub {
    with( id => 'foo', id => 'foo' ), html {
    };
};

package main;

use Test::More tests => 11;
use Test::Warn;

##############################################################################
Template::Declare->init(dispatch_to => ['Wifty::UI']);
pass 'Init with no strict setting';

warning_like { Template::Declare->show('nonesuch' ) }
    qr/The template 'nonesuch' could not be found [(]it might be private[)]/,
    'Should get warning for nonexistent template';

warning_like { Template::Declare->show('oops' ) }
    qr/HTML appears to contain illegal duplicate element id: foo/,
    'Should get warning for duplicate "id" attribute';

##############################################################################
Template::Declare->init(dispatch_to => ['Wifty::UI'], strict => 0);
pass 'Init with strict off';

warning_like { Template::Declare->show('nonesuch' ) }
    qr/The template 'nonesuch' could not be found [(]it might be private[)]/,
    'Should still get warning for nonexistent template';

warning_like { Template::Declare->show('oops' ) }
    qr/HTML appears to contain illegal duplicate element id: foo/,
    'Should still get warning for duplicate "id" attribute';

##############################################################################
Template::Declare->init(dispatch_to => ['Wifty::UI'], strict => 1);
pass 'Init with strict on';

undef $@;
eval { Template::Declare->show('nonesuch' ) };
ok my $err = $@, 'Should get exception for missing template';
like $err,
    qr/The template 'nonesuch' could not be found [(]it might be private[)]/,
    '... and it should be about nonexistent template';

undef $@;
eval { Template::Declare->show('oops' ) };
ok $err = $@, 'Should get exception for duplicate "id"';
like $err,
    qr/HTML appears to contain illegal duplicate element id: foo/,
    '... and it should be about the duplicate "id" attribute';
