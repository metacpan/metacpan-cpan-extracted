package Fully::Qualified;
use strict;
use warnings;

use vars qw( $VERSION @EXPORT_OK );
$VERSION=0.001;

use base 'Exporter';
@EXPORT_OK = qw( &ex_sub2 );

=head1 NAME

Fully::Qualified - Test for Pod::Coverage

=head1 SYNOPSIS

none

=head1 DESCRIPTION

This package is to see that L<Pod::Coverage> sees fully qualified subnames as documented. (Not all the world is OO)

=over 4

=item C<Fully::Qualified::api_sub1 ( noargs )>

Okay, it is API; but not exported

=cut

sub api_sub1 { "in api_sub1" }

=item Fully::Qualified::ex_sub2

This sub can be exported.

=cut

sub ex_sub2 { "in ex_sub2" }

=back

=cut

1;
