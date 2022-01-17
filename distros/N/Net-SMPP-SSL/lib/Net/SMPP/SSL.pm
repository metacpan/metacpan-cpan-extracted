package Net::SMPP::SSL;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use IO::Socket::SSL;
use Net::SMPP;
 
our @ISA = ( 'IO::Socket::SSL',
             grep { $_ ne 'IO::Socket::INET' } @Net::SMPP::ISA );
 
sub isa {
  my $self = shift;
  return 1 if $_[0] eq 'Net::SMPP';
  return $self->SUPER::isa(@_);
}
 
no strict 'refs';
foreach ( keys %Net::SMPP:: ) {
    next unless (ref(\$Net::SMPP::{$_}) eq "GLOB" && defined(*{$Net::SMPP::{$_}}{CODE}))
              || ref(\$Net::SMPP::{$_}) eq "REF";
    *{$_} = \&{"Net::SMPP::$_"};
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::SMPP::SSL - SSL support for Net::SMPP

=head1 SYNOPSIS

    use Net::SMPP::SSL;
 
    my $ssmpp = Net::SMPP::SSL->new_connect( 'example.com', port => 3550 ); 

=head1 DESCRIPTION

Net::SMPP::SSL implements the same API as Net::SMPP, but uses IO::Socket::SSL for its network operations. 

For interface documentation, please see Net::SMPP.

The implementation is based the approach used for Net::SMTP::SSL, thanks to the authors.

=head1 SEE ALSO
Net::SMPP, IO::Socket::SSL, perl.

=head1 LICENSE

Copyright (C) Stefan Stuehrmann.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Stefan Stuehrmann <stefan.stuehrmann@emnify.com>

=cut

