package Rose::DBx::Garden::Catalyst::Object;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Rose::DB::Object );
use base qw( Rose::DB::Object::Helpers );
use base qw( Rose::DBx::Object::MoreHelpers );
use MRO::Compat;
use mro 'c3';

our $VERSION = '0.180';

=head1 NAME

Rose::DBx::Garden::Catalyst::Object - base RDBO class

=head1 DESCRIPTION

Rose::DBx::Garden::Catalyst::Object is a subclass of Rose::DB::Object
for using with YUI, RHTMLO and CatalystX::CRUD.

RDGC::Object inherits from both RDBO and RDBO::Helpers, plus adding
some convenience methods of its own.

=head1 METHODS

See Rose::DBx::Object::MoreHelpers.

=cut

=head2 schema_class_prefix

Returns garden_prefix() value. schema_class_prefix() is used
by Rose::HTMLx::Form::Related while garden_prefix() is what
Rose::DBx::Garden sets. See the documentation for
L<Rose::HTMLx::Form::Related::Metadata/discover_relationships> for
details on how garden_prefix must be set to correctly determine
Catalyst Controller names when using related HTML forms.

=cut

sub schema_class_prefix {
    shift->garden_prefix;
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


