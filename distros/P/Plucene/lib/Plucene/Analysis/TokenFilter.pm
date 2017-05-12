package Plucene::Analysis::TokenFilter;

=head1 NAME 

Plucene::Analysis::TokenFilter - base class for token filters

=head1 DESCRIPTION

This is an abstract base class for token filters.

A TokenFilter is a TokenStream whose input is another token stream.

=head1 METHODS

=cut

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw[ input ]);

=head2 next

This must be defined in a subclass

=cut

sub next { die "next must be defined in a subclass" }

=head2 close

Does nothing.

=cut

sub close { }

1;
