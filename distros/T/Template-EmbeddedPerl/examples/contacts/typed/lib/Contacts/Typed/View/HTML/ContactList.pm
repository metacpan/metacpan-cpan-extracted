package Contacts::Typed::View::HTML::ContactList;

use strict;
use warnings;
use Moo;

has title => (is => 'ro', required => 1);
has contacts => (is => 'ro', required => 1);
has prebuilt_badge => (is => 'ro', required => 1);

1;
