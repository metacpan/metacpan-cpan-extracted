# This does not need to be indexed by PAUSE
package
    RPC::ExtDirect::Test::Data::Poll;

use strict;
use warnings;

# This aref contains definitions/data for Poll tests
my $tests = [{
    name => 'Two events',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
        password => 'Usual, please',
    },
    
    input => {
        method => 'POST',
        url => '/events',
        cgi_url => '/poll1',
        
        content => undef,
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 109,
        comparator => 'cmp_json',
        content => 
            q|[{"data":["foo"],|.
            q|  "name":"foo_event",|.
            q|  "type":"event"},|.
            q| {"data":{"foo":"bar"},|.
            q|  "name":"bar_event",|.
            q|  "type":"event"}]|,
    },
}, {
    name => 'One event',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
        password => 'Ein kaffe bitte',
    },
    
    input => {
        method => 'POST',
        url => '/events',
        cgi_url => '/poll2',
        
        content => undef,
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 65,
        comparator => 'cmp_json',
        content =>
            q|{"data":"Uno cappuccino, presto!",|.
            q| "name":"coffee",|.
            q| "type":"event"}|,
    },
}, {
    name => 'Failed method',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
        password => 'Whiskey, straight away!',
    },
    
    input => {
        method => 'POST',
        url => '/events',
        cgi_url => '/poll3',
        
        content => undef,
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 44,
        comparator => 'cmp_json',
        content => q|{"data":"","name":"__NONE__","type":"event"}|,
    },
}, {
    name => 'No events at all',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
        password => "Sorry sir, but that's not on the menu?",
    },
    
    input => {
        method => 'POST',
        url => '/events',
        cgi_url => '/poll4',
        
        input => undef,
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 44,
        comparator => 'cmp_json',
        content => q|{"data":"","name":"__NONE__","type":"event"}|,
    },
}, {
    name => 'Invalid Event provider output',
    
    config => {
        api_path => '/api',
        router_path => '/router',
        poll_path => '/events',
        debug => 1,
        password => "Hey man! There's a roach in my soup!",
    },
    
    input => {
        method => 'POST',
        url => '/events',
        cgi_url => '/poll5',
        
        input => undef,
    },
    
    output => {
        status => 200,
        content_type => qr|^application/json\b|,
        content_length => 44,
        comparator => 'cmp_json',
        content => q|{"data":"","name":"__NONE__","type":"event"}|,
    },
}];

sub get_tests { return $tests };

1;
