package SVN::Class::Info;
use strict;
use warnings;
use base qw( Rose::Object );
use Rose::Object::MakeMethods::Generic (
    scalar => [
        qw( path name wc_root _url root rev
            node schedule author last_rev date
            updated checksum uuid rel_url
            )
    ]
);
use Carp;
use Data::Dump;
use SVN::Class::Repos;

our $VERSION = '0.18';

=head1 NAME

SVN::Class::Info - Subversion workspace info

=head1 SYNOPSIS

 use SVN::Class;
 
 my $file = svn_file( 'path/to/file' );
 my $info = $file->info;
 printf "repository URL = %s\n", $info->url;
 
=head1 DESCRIPTION

SVN::Class::Info represents the output of the C<svn info> command.

=head1 METHODS

SVN::Class::Info B<does not> inherit from SVN::Class, but only
Class::Accessor::Fast.

=cut

=head2 new( $dir->stdout )

Creates new SVN::Class::Info instance. The lone argument should
be an array ref of output from a call to the SVN::Class object's
info() method.

You normally do not need to use this method directly. See the SVN::Class
info() method.

=cut

sub new {
    my $class = shift;
    my $buf   = shift;
    if ( !$buf or !ref($buf) or ref($buf) ne 'ARRAY' ) {
        croak "need array ref of 'svn info' output";
    }
    return $class->SUPER::new( _make_hash(@$buf) );
}

=head2 dump

Returns dump() of the object, just like SVN::Class->dump().

=cut

sub dump {
    return Data::Dump::dump(@_);
}

my %fieldmap = (
    Path                     => 'path',
    Name                     => 'name',
    URL                      => '_url',
    'Working Copy Root Path' => 'wc_root',
    'Relative URL'           => 'rel_url',
    'Repository Root'        => 'root',
    'Repository UUID'        => 'uuid',
    'Revision'               => 'rev',
    'Node Kind'              => 'node',
    'Schedule'               => 'schedule',
    'Last Changed Author'    => 'author',
    'Last Changed Rev'       => 'last_rev',
    'Last Changed Date'      => 'date',
    'Text Last Updated'      => 'updated',
    'Checksum'               => 'checksum'
);

sub _make_hash {
    my %hash;
    for (@_) {
        my ( $field, $value ) = (m/^([^:]+):\ (.+)$/);
        if ( !exists $fieldmap{$field} ) {
            croak "unknown field name in svn info: $field";
        }
        $hash{ $fieldmap{$field} } = $value;
    }
    return %hash;
}

=head2 url

Get the URL value. Returns a SVN::Class::Repos object.

=cut

sub url {
    my $self = shift;
    return SVN::Class::Repos->new( $self->_url );
}

=head2 path 

=head2 wc_root

Working Copy Root Path

=head2 name 

=head2 root 

=head2 rev

=head2 node 

=head2 schedule 

=head2 author 

=head2 last_rev 

=head2 date

=head2 updated 

=head2 checksum 

=head2 uuid

Get/set the info params. These are really only useful as accessors (getters).

=head2 rel_url

=cut

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

Path::Class, Class::Accessor::Fast, SVN::Agent, IPC::Cmd
