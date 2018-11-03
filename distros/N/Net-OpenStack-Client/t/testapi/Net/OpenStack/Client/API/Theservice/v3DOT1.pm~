package Net::OpenStack::API::Theservice::v3DOT1;

use strict;
use warnings;

use Readonly;

use version;
our $VERSION = version->new("v3.1");


Readonly our $API_DATA => {
    humanreadable => {
        method => 'POST',
        endpoint => '/some/{user}/super',
        templates => [qw(user)],
        options => {
            'int' => {'type' => 'long','path' => ['something','int'], required => 1},
            'boolean' => {'path' => ['something','boolean'],'type' => 'boolean'},
            'name' => {'type' => 'string','path' => ['something','name']},
        },
        result => '/woo',
    },

    simple => {
        method => 'GET',
        endpoint => '/simple',
        result => 'Special',
    },
};

1;
