package Contacts::Typed::View::HTML::Badge;

use strict;
use warnings;
use Moo;

has label => (is => 'ro', required => 1);

sub template { 'contacts/badge' }

1;
