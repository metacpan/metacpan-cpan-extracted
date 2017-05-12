use strict;
use warnings;

package MooseThing;
use Moose;
use namespace::clean;
with 'MooseX::Role::HTML::Grabber' => {
    name   => 'mechanize',
    method => 'content',
};

sub content {
    return q|</div><div class="alert alert-error">Empty username or password.</div>|;
}

package main;
use Test::Most;

my $m = MooseThing->new;

is ref $m->mechanize_grabber => 'HTML::Grabber', 'it is a HTML::Grabber';
is $m->mechanize_grabber->find( 'div.alert-error' )->text => 'Empty username or password.', "Correctly found element";

done_testing;
