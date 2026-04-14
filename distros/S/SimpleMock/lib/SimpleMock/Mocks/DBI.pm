package SimpleMock::Mocks::DBI;
use strict;
use warnings;

no warnings 'redefine';

our $VERSION = '0.03';
            
my $orig_connect = \&DBI::connect;
     
# force DBI connect to use dbd:SimpleMock
*DBI::connect = sub {
    my ($class, undef, undef, undef, $attr) = @_;
    return $orig_connect->($class, 'dbi:SimpleMock:', undef, undef, $attr);
};

1;

=head1 NAME

SimpleMock::Mocks::DBI - Mock DBI module for testing

=head1 DESCRIPTION

This module mocks the connect method of the DBI module to force it to use a
dbi:SimpleMock database connection.

=cut
