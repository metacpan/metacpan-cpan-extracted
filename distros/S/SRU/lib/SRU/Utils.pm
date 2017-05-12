package SRU::Utils;
{
  $SRU::Utils::VERSION = '1.01';
}
#ABSTRACT: Utility functions for SRU

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( error );


sub error {
    if ( $_[0] ) { $SRU::Error = $_[0]; };
    return;
}

1;

__END__

=pod

=head1 NAME

SRU::Utils - Utility functions for SRU

=head1 SYNOPSIS

    use SRU::Utils qw( error );
    return error( "error!" );

=head1 DESCRIPTION

This is a set of utility functions for the SRU objects.

=head1 METHODS

=head2 error( $message )

Sets the C<$SRU::Error> message.

=cut
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ed Summers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
