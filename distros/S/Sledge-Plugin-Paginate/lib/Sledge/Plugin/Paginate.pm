package Sledge::Plugin::Paginate;

use warnings;
use strict;

our $VERSION = '0.01';

use Data::Page;
our $REQUEST_PARAM = 'page';

sub import {
    my $self = shift;
    my $pkg  = caller;

    no strict 'refs';
    *{"$pkg\::paginate"} = sub {
        my ($self , %args) = @_;

        my $pager = Data::Page->new(
            scalar(@{$args{data}}),
            $args{paging_num},
            $self->r->param($REQUEST_PARAM) || 0,
        );

        $self->tmpl->param(
            $args{page_name} => [ $pager->splice($args{data}) ],
            pager            => $pager,
        );
    };
}


=head1 NAME

Sledge::Plugin::Paginate - data paginate plugin for Sledge

=head1 VERSION

This documentation refers to Sledge::Plugin::Paginate version 0.01

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::Paginate;

    sub dispatch_index {
        my $self = shift;

        my @users = $self->user;

        $self->paginate(
            paging_num => $self->config->paging_num,
            page_name  => 'user',
            data       => \@users,
        );
    }

=head1 METHODS

=head2 paginate

This paginate plugin can easily execute paging. 

=head1 AUTHOR

Atsushi Kobayashi, C<< <nekokak at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sledge-plugin-paginate at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sledge-Plugin-Paginate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sledge::Plugin::Paginate

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sledge-Plugin-Paginate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sledge-Plugin-Paginate>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sledge-Plugin-Paginate>

=item * Search CPAN

L<http://search.cpan.org/dist/Sledge-Plugin-Paginate>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Atsushi Kobayashi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Sledge::Plugin::Paginate
