use strict;
use warnings;

use Test::More;

use Template::Caribou;
use Template::Caribou::Utils;

use Template::Caribou::Tags 
    mytag => { tag => 'foo' },
    mytag => { tag => 'bar' },
;

has '+indent' => default => 0;

my $self = __PACKAGE__->new;

subtest string => sub {
    is $self->render(sub { 'hi there' }) => 'hi there';
};

subtest one_tag => sub {
    is $self->render(sub { foo { } }) => '<foo />';
    is $self->render(sub { foo { 'moin' } }) => '<foo>moin</foo>';
};

subtest two_tags => sub {
    is $self->render(sub { foo { bar { 'yay' } } }) => "<foo><bar>yay</bar></foo>";
};

done_testing;
