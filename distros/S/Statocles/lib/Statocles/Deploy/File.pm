package Statocles::Deploy::File;
our $VERSION = '0.087';
# ABSTRACT: Deploy a site to a folder on the filesystem

use Statocles::Base 'Class';
with 'Statocles::Deploy';

#pod =attr path
#pod
#pod The path to deploy to.
#pod
#pod =cut

has path => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
    default => sub { Path::Tiny->new( '.' ) },
);

#pod =method deploy
#pod
#pod     my @paths = $deploy->deploy( $from_store, %options );
#pod
#pod Deploy the site, copying from the given L<from_store|Statocles::Store>.
#pod Returns the paths that were deployed.
#pod
#pod Possible options are:
#pod
#pod =over 4
#pod
#pod =item clean
#pod
#pod Remove all the current contents of the deploy directory before copying the
#pod new content.
#pod
#pod =back
#pod
#pod =cut

sub deploy {
    my ( $self, $from_store, %options ) = @_;

    die sprintf 'Deploy directory "%s" does not exist (did you forget to make it?)',
        $self->path
            if !$self->path->is_dir;

    if ( $options{ clean } ) {
        $_->remove_tree for $self->path->children;
    }

    $self->site->log->info( "Copying files from build dir to deploy dir" );
    my @files;
    my $iter = $from_store->find_files( include_documents => 1 );
    while ( my $path = $iter->() ) {
        # Git versions before 1.7.4.1 require a relative path to 'git add'
        push @files, $path->relative( "/" )->stringify;
        $from_store->path->child( $path )->copy( $self->path->child( $path )->touchpath );
    }

    return @files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Deploy::File - Deploy a site to a folder on the filesystem

=head1 VERSION

version 0.087

=head1 DESCRIPTION

This class allows a site to be deployed to a folder on the filesystem.

This class consumes L<Statocles::Deploy|Statocles::Deploy>.

=head1 ATTRIBUTES

=head2 path

The path to deploy to.

=head1 METHODS

=head2 deploy

    my @paths = $deploy->deploy( $from_store, %options );

Deploy the site, copying from the given L<from_store|Statocles::Store>.
Returns the paths that were deployed.

Possible options are:

=over 4

=item clean

Remove all the current contents of the deploy directory before copying the
new content.

=back

=head1 SEE ALSO

=over 4

=item L<Statocles::Deploy>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
