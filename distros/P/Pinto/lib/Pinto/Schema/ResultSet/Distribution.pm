# ABSTRACT: Common queries for Distributions

use utf8;

package Pinto::Schema::ResultSet::Distribution;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

#------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------------

sub with_packages {
    my ( $self, $where ) = @_;

    return $self->search( $where || {}, { prefetch => 'packages' } );
}

#------------------------------------------------------------------------------

sub find_by_author_archive {
    my ( $self, $author, $archive ) = @_;

    my $where = { author => $author, archive => $archive };
    my $attrs = { key => 'author_archive_unique' };

    return $self->find( $where, $attrs );
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Schema::ResultSet::Distribution - Common queries for Distributions

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
