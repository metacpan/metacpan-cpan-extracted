package Net::Host64;

use strict;
use warnings;
use XSLoader;

our $VERSION = '0.001';

XSLoader::load( 'Net::Host64', $VERSION );

1;

__END__

=head1 NAME

Net::Host64 - Interface to libehnet64 "Easy Host-Network 64" library
