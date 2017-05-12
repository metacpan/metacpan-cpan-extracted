package Rose::HTMLx::Form::Related::RDBO;
use strict;
use warnings;
use base qw( Rose::HTMLx::Form::Related );
use Rose::DB::Object::Manager;
use Rose::HTMLx::Form::Related::RDBO::Metadata;
use Carp;

our $VERSION = '0.24';

=head1 NAME

Rose::HTMLx::Form::Related::RDBO - RDBO with RHTMLO

=head1 SYNOPSIS

 package MyRDBO::Class::Form;
 use strict;
 use base qw( Rose::HTMLx::Form::Related::RDBO );
 
 sub init_object_class { 'MyRDBO::Class' }
 
 1;

=head1 DESCRIPTION

Use Rose::HTML::Objects forms with Rose::DB::Object.

=head1 METHODS

=cut

=head2 init_metadata_class

Returns 'Rose::HTMLx::Form::Related::RDBO::Metadata'.

=cut

sub init_metadata_class {
    return 'Rose::HTMLx::Form::Related::RDBO::Metadata';
}

=head2 get_objects( object_class => I<class> )

Overrides base method to use Rose::DB::Object::Manager
to fetch objects of I<class>.

=cut

sub get_objects {
    my $self = shift;
    return scalar Rose::DB::Object::Manager->get_objects(@_);
}

=head2 get_objects_count( object_class => I<class> )

Overrides base method to use Rose::DB::Object::Manager
to fetch object count for I<class>.

=cut

sub get_objects_count {
    my $self = shift;
    return Rose::DB::Object::Manager->get_objects_count(@_);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-htmlx-form-related at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-HTMLx-Form-Related>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::HTMLx::Form::Related

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-HTMLx-Form-Related>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-HTMLx-Form-Related>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTMLx-Form-Related>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-HTMLx-Form-Related>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
