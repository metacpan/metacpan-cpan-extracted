package SWISH::Prog::Native::InvIndex;
use strict;
use warnings;
use Carp;
use base qw( SWISH::Prog::InvIndex );
__PACKAGE__->mk_accessors(qw( file ));

our $VERSION = '0.75';

=head1 NAME

SWISH::Prog::Native::InvIndex - the native Swish-e index format

=head1 SYNOPSIS

 # see SWISH::Prog::InvIndex

=head1 DESCRIPTION

The Native InvIndex represents the index.swish-e files.

=head1 METHODS

=cut

=head2 init

Sets file() to default index file name C<index.swish-e> unless
it is already set. If already set, confirms that file() is a child
of path().

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !$self->file ) {
        $self->file( $self->path->file('index.swish-e') );
    }
    else {

        # TODO check that ->file is child of ->path

    }

}

=head2 file

Returns a Path::Class::File object representing the main index file.

=head2 open

Creates path() if not already existent.

Since the native swish-e behaviour is to always create a temp index
and then rename it on close(), the clobber() attribute is effectively
ignored (always true).

=cut

sub open {
    my $self = shift;

    if ( -f $self->path ) {
        croak $self->path . " is not a directory.";
    }

    if ( !-d $self->path ) {

        #carp "mkpath $self->{path}";
        $self->path->mkpath($self->verbose);
    }

    1;
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
