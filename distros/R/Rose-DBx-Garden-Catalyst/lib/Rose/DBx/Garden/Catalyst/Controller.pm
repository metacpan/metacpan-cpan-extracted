package Rose::DBx::Garden::Catalyst::Controller;
use strict;
use warnings;
use base qw(
    CatalystX::CRUD::YUI::Controller
    CatalystX::CRUD::Controller::RHTMLO
);
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';

our $VERSION = '0.180';

=head1 NAME

Rose::DBx::Garden::Catalyst::Controller - base Controller class

=head1 DESCRIPTION

Rose::DBx::Garden::Catalyst::Controller is a subclass of CatalystX::CRUD::Controller::RHTMLO
with some additional/overridden methods for working with YUI and JSON.

=head1 METHODS

=cut

=head2 autocomplete_columns

Should return arrayref of fields to search when
the autocomplete() URI method is requested.

The default is all the unique keys
in model_name() that are made up of a single column.

=cut

sub _get_autocomplete_columns {
    my ( $self, $c ) = @_;
    my $model = $c->model( $self->model_name )->name;
    my @ukeys = $model->meta->unique_keys_column_names;
    my @cols;
    return [] unless @ukeys;
    for my $k (@ukeys) {
        if ( scalar(@$k) == 1
            && $model->meta->column( $k->[0] )->type =~ m/char/ )
        {
            push( @cols, $k->[0] );
        }
    }
    $self->autocomplete_columns( \@cols );
    return $self->autocomplete_columns;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-dbx-garden-catalyst at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-DBx-Garden-Catalyst>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::DBx::Garden::Catalyst

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-DBx-Garden-Catalyst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-DBx-Garden-Catalyst>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-Garden-Catalyst>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-DBx-Garden-Catalyst>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
