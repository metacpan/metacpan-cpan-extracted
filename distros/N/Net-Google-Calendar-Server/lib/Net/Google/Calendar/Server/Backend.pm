package Net::Google::Calendar::Backend;

use strict;

=head1 NAME

Net::Google::Calendar::Backend - store and retrieve entries. Should be subclassed.

=cut

sub new {
    my $class = shift;
    my %opts  = @_;

    return bless \%opts, $class;
}

1;
