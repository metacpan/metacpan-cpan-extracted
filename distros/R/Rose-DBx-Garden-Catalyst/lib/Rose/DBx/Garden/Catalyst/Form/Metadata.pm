package Rose::DBx::Garden::Catalyst::Form::Metadata;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Rose::HTMLx::Form::Related::RDBO::Metadata );

our $VERSION = '0.180';

use Rose::Object::MakeMethods::Generic (
    'scalar --get_set_init' => [ 'yui_datatable_methods', ], );

=head1 NAME

Rose::DBx::Garden::Catalyst::Form::Metadata - RHTMLO Form class metadata

=head1 DESCRIPTION

Rose::DBx::Garden::Catalyst::Form::Metadata interrogates and caches interrelationships
between Form classes and the RDBO classes they represent.

You typically access an instance of this class via the metadata() method in
your Form class.

=head1 METHODS

=cut

=head2 init_controller_prefix

The default is 'RDGC'.

=cut

sub init_controller_prefix {'RDGC'}

=head2 init_field_uris

Should return a hashref of field names to a value that will be passed
to Catalyst's uri_for() method. Used primarily for per-column
click behaviour in a YUI DataTable.

=cut

=head2 init_field_methods

Alias for yui_datatable_methods() for backwards compat.

=cut

sub init_field_methods {
    my $self = shift;
    return $self->yui_datatable_methods(@_);
}

=head2 init_yui_datatable_methods

Acts like init_field_methods() does in Rose::HTMLx::Form::Related::Metadata.

=cut

sub init_yui_datatable_methods {
    my $self = shift;
    return $self->form->field_names;
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
