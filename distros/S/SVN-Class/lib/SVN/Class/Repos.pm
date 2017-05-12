package SVN::Class::Repos;
use strict;
use warnings;
use Carp;
use Data::Dump;
use base qw( Rose::URI SVN::Class );

our $VERSION = '0.18';

=head1 NAME

SVN::Class::Repos - represents the repository of a Subversion workspace

=head1 SYNOPSIS

 use SVN::Class;
 
 my $file = svn_file( 'path/to/file' );
 my $info = $file->info;
 my $url  = $info->url;
 print "repository URL is $url\n";
 
=head1 DESCRIPTION

SVN::Class::URL represents the source repository for a workspace.

=head1 METHODS

SVN::Class::URL inherits from Rose::URI and SVN::Class.

=cut

=head2 init

Override the base Rose::URI method to set some default values in object.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{svn} ||= 'svn';
}

1;

__END__

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

=head1 ACKNOWLEDGEMENTS

I looked at SVN::Agent before starting this project. It has
a different API, more like SVN::Client in the SVN::Core, but
I cribbed some of the ideas.

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Rose::URI, Path::Class, Class::Accessor::Fast, SVN::Agent, IPC::Cmd
