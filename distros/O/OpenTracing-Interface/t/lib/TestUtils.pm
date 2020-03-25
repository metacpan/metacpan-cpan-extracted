package TestUtils;

=head1 DESCRIPTION

This module provides two convenient subroutines for Types test

=cut

use strict;
use warnings;

use Exporter 'import'; # gives you Exporter's import() method directly
our @EXPORT_OK= qw/is_Type/;



sub is_Type {
    my $class_name = shift;
    my $thing = shift;
    my ( $package ) = caller;
    
    my $is_type = $package . '::is_' . $class_name;
    
    no strict qw/refs/;
    
    
    &$is_type( $thing )
}



1;