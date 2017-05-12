use warnings;
use strict;

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'test' => sub {
    my $self = shift;
    outs 'wowza';
};

import_templates Wifty::UI under '/here';

package Wifty::UI::Woot;
use base 'Wifty::UI';

package main;
#use Test::More tests => 19;
use Test::More 'no_plan';
use Template::Declare::Tags;
Template::Declare->init( dispatch_to => ['Wifty::UI'] );

ok +Wifty::UI->has_template('here/test'),
    'Template should be under new path';
ok +Wifty::UI->has_template('test'), 'Original template name should be visible';

ok +Wifty::UI::Woot->has_template('here/test'),
    'Moved template should be visible from subclass';
ok +Wifty::UI::Woot->has_template('test'),
    'Original template name should be visible from subclass';

ok my $out = Template::Declare->show('here/test'), 'Should get output';
is $out, 'wowza', 'Output should be correct';
