package Failover;

use Moo;
use Types::Standard qw/ Str /;

has error => ( is => 'ro', );

has class => (
    is  => 'ro',
    isa => Str
);

has 'num' => ( is => 'ro' );    # can be anything

1;
