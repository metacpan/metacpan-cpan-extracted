package MyObject;
# For testing purposes -- Object with 'id' attribute.

@ISA = qw(RT::Client::REST::Object);

sub id {
    my $self = shift;
    if (@_) {
        $self->{_id} = shift;
    }
    return $self->{_id};
}

sub rt_type { 'myobject' }

sub _attributes {{
    id => {},
}}

package main;

use strict;
use warnings;

use Test::More tests => 38;
use Test::Exception;

use constant METHODS => (
    'new', 'to_form', 'from_form', '_generate_methods', 'store', 'retrieve',
    'param', 'rt', 'cf', 'search', 'count', 'use_single_rt',
    'use_autostore', 'use_autoget', 'use_autosync', 'be_transparent',
    'autostore', 'autosync', 'autoget',
);

BEGIN {
    use_ok('RT::Client::REST::Object');
}

my $obj;

lives_ok {
    $obj = RT::Client::REST::Object->new;
} 'Object can get successfully created';

for my $method (METHODS) {
    can_ok($obj, $method);
}

use RT::Client::REST;
my $rt = RT::Client::REST->new;

for my $method (qw(retrieve)) {
    my $obj = MyObject->new;    # local copy;

    throws_ok {
        $obj->$method;
    } 'RT::Client::REST::Object::RequiredAttributeUnsetException',
        "won't go on without 'rt' set";

    lives_ok {
        $obj->rt($rt)
    } "Successfully set 'rt'";

    throws_ok {
        $obj->$method;
    } 'RT::Client::REST::Object::RequiredAttributeUnsetException',
        "won't go on without 'id' set";

    lives_ok {
        $obj->id(1);
    } "Successfully set 'id' to 1";

    throws_ok {
        $obj->$method;
    } 'RT::Client::REST::RequiredAttributeUnsetException',
        "rt object is not correctly initialized";
}

for my $method (qw(store count search)) {
    my $obj = MyObject->new;    # local copy;

    throws_ok {
        $obj->$method;
    } 'RT::Client::REST::Object::RequiredAttributeUnsetException',
        "won't go on without 'rt' set";

    lives_ok {
        $obj->rt($rt)
    } "Successfully set 'rt'";

    lives_ok {
        $obj->id(1);
    } "Successfully set 'id' to 1";

    throws_ok {
        $obj->$method;
    } 'RT::Client::REST::RequiredAttributeUnsetException',
        "rt object is not correctly initialized";
}

# vim:ft=perl:
