use warnings;
use strict;

# Reveals a problem T-D once had with matching aliases in two differen files:
#
# alias Foo under /foo
# alias Admin::Foo under /admin/foo
#
# where each alias had a "list" or something other matching thing. The template
# resolver could match /foo/list when looking for /admin/foo/list.

##############################################################################
package Foo;
use base qw/ Template::Declare /;
use Template::Declare::Tags;

template 'list' => sub {
    my $self = shift;
    div { outs( 'This is aliased from ' . $self ) };
};

##############################################################################
package Admin::Foo;
use base qw/ Template::Declare /;
use Template::Declare::Tags;

template 'list' => sub {
    my $self = shift;
    div { outs( 'This is aliased from ' . $self ) };
};

##############################################################################
package App;
use base qw/ Template::Declare /;
use Template::Declare::Tags;

alias Foo under '/foo';
alias Admin::Foo under '/admin/foo';

##############################################################################
package main;
use Template::Declare::Tags;
Template::Declare->init( dispatch_to => [ 'App' ] );

use Test::More tests => 6;

ok(Template::Declare->has_template('foo/list'), 'has a foo/list');
ok(Template::Declare->has_template('admin/foo/list'), 'has an admin/foo/list');

{
    my $output = show('foo/list');
    like($output, qr/\bThis is aliased\b/);
    like($output, qr/\bfrom Foo\b/);
}

{
    my $output = show('admin/foo/list');
    like($output, qr/\bThis is aliased\b/);
    like($output, qr/\bfrom Admin::Foo\b/);
}
