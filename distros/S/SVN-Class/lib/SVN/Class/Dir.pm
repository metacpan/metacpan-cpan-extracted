package SVN::Class::Dir;
use strict;
use warnings;
use base qw( Path::Class::Dir SVN::Class );
use SVN::Class::File;

our $VERSION = '0.18';

# override some Path::Class stuff to return SVN::Class objects instead
sub file {
    local $Path::Class::Foreign = $_[0]->{file_spec_class}
        if $_[0]->{file_spec_class};
    return SVN::Class::File->new(@_);
}

sub new {
    my $self  = Path::Class::Entity::new(shift);
    my $s     = $self->_spec;

    my $first = (
          @_ == 0 ? $s->curdir
        : $_[0] eq '' ? ( shift, $s->rootdir )
        : shift()
    );

    ( $self->{volume}, my $dirs )
        = $s->splitpath( $s->canonpath($first) || '', 1 );
    $self->{dirs} = [ $s->splitdir( $s->catdir( $dirs, @_ ) ) ];
    $self->{svn} ||= 'svn';
    return $self;
}

1;

__END__

=head1 NAME

SVN::Class::Dir - represents a directory in a Subversion workspace

=head1 SYNOPSIS

 # see SVN::Class;

=head1 DESCRIPTION

This class subclasses Path::Class::Dir and SVN::Class.
A SVN::Class::Dir object behaves like a Path::Class::Dir object,
but with the extra Subversion functionality of SVN::Class.

=head1 METHODS

There are no new methods implemented in this class.

The following methods are overridden to return SVN::Class-derived objects 
instead of Path::Class-derived objects.

=over

=item new

=item file

=back

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-svn-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVN-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVN-Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/SVN-Class>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

SVN::Class, Path::Class::Dir
