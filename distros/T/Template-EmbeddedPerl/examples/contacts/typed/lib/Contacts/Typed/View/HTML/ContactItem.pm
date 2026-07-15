package Contacts::Typed::View::HTML::ContactItem;

use strict;
use warnings;
use Moo;

has contact => (is => 'ro', required => 1);
has root => (is => 'ro', required => 1);
has parent => (is => 'ro', required => 1);

sub template { 'contacts/item' }

1;
