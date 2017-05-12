package SVN::Class::File;
use strict;
use warnings;
use base qw( Path::Class::File::Stat SVN::Class );
use SVN::Class::Dir;

our $VERSION = '0.18';

# override Path::Class stuff to use SVN::Class instead
sub new {
    my $self = Path::Class::Entity::new(shift);
    my $file = pop();
    my @dirs = @_;

    my ( $volume, $dirs, $base ) = $self->_spec->splitpath($file);

    if ( length $dirs ) {
        push @dirs, $self->_spec->catpath( $volume, $dirs, '' );
    }

    $self->{dir} = @dirs ? SVN::Class::Dir->new(@dirs) : undef;
    $self->{file} = $base;
    $self->{svn} ||= 'svn';

    return $self;
}

sub dir {
    my $self = shift;
    return $self->{dir} if defined $self->{dir};
    return SVN::Class::Dir->new( $self->_spec->curdir );
}

1;

__END__

=head1 NAME

SVN::Class::File - represents a file in a Subversion workspace

=head1 SYNOPSIS

 # see SVN::Class;

=head1 DESCRIPTION

This class subclasses Path::Class::File::Stat and SVN::Class.
A SVN::Class::File object behaves like a Path::Class::File::Stat object,
but with the extra Subversion functionality of SVN::Class.

=head1 METHODS

There are no new methods implemented in this class.

The following methods are overridden to return SVN::Class-derived objects instead
of Path::Class-derived objects.

=over

=item new

=item dir

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

SVN::Class, Path::Class::File::Stat
