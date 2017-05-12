use strict;
use warnings; # stupid CPANTS!
package Path::Resolver;
{
  $Path::Resolver::VERSION = '3.100454';
}
# ABSTRACT: go from "file" names to things


1;

__END__

=pod

=head1 NAME

Path::Resolver - go from "file" names to things

=head1 VERSION

version 3.100454

=head1 DESCRIPTION

Path::Resolver is a set of libraries for resolving virtual file paths into
entities that may be found at those paths.  Here's a trivial example:

  use Path::Resolver::Resolver::FileSystem;

  # Create a resolver that looks at the filesystem, starting in /etc
  my $fs = Path::Resolver::Resolver::FileSystem->new({ root => '/etc' });

  my $file = $fs->entity_at('/postfix/main.cf');

Assuming it exists, this will return an object representing the file
F</etc/postfix/main.cf>.  Using the code above, C<$file> would be a
C<Path::Resolver::SimpleEntity> object, which has a C<content> method.  We
could print the contents of the file to screen like this:

  print $file->content;

=head1 WHAT'S THE POINT?

Path::Resolver lets you use a simple, familiar notation for accessing all kinds
of hierarchical data.  It's also distributed with resolvers that act as
multiplexers for other resolvers.  Since all resolvers share one mechanism for
addressing content, they can easily be mixed and matched.  Since resolvers know
what kind of object they'll return, and can be fitted with translators, it's
easy to ensure that all your multiplexed resolvers will resolve names to the
same kind of object.

For example, we could overlay two search paths like this:

  my $resolver = Path::Resolver::Resolver::Mux::Ordered->new({
    resolvers => [
      Path::Resolver::Resolver::FileSystem->new({ root => './config' }),
      Path::Resolver::Resolver::Archive::Tar->new({ archive => 'config.tgz' }),
    ],
  });

  $resolver->entity_at('/foo/bar.txt');

This will return an entity representing F<./config/foo/bar.txt> if it exists.
If it doesn't, it will look for F<foo/bar.txt> in the contents of the archive.
If that's found, an entity will be returned.  Finally, if neither is found, it
will return false.

Alternately, you could multiplex based on path:

  my $resolver = Path::Resolver::Resolver::Mux::Prefix->new({
    config   => Path::Resolver::Resolver::FileSystem->new({
      root => '/etc/my-app',
    }),

    template => Path::Resolver::Resolver::Mux::Ordered->new({
      Path::Resolver::Resolver::DistDir->new({ module => 'MyApp' }),
      Path::Resolver::Resolver::DataSection->new({ module => 'My::Framework' }),
    }),
  });

The path F</config/main.cf> would be looked for on disk as
F</etc/my-app/main.cf>.  The path F</template/main.html> would be looked for
first as F<main.html> in the sharedir for MyApp and failing that in the DATA
section of My::Framework.

=head1 WHERE DO I GO NEXT?

If you want to read about how to write a resolver, look at
L<Path::Resolver::Role::Resolver|Path::Resolver::Role::Resolver>.

If you want to read about the interfaces to the existing resolvers look at
their documentation:

=over

=item * L<Path::Resolver::Resolver::AnyDist>

=item * L<Path::Resolver::Resolver::Archive::Tar>

=item * L<Path::Resolver::Resolver::DataSection>

=item * L<Path::Resolver::Resolver::DistDir>

=item * L<Path::Resolver::Resolver::FileSystem>

=item * L<Path::Resolver::Resolver::Hash>

=item * L<Path::Resolver::Resolver::Mux::Ordered>

=item * L<Path::Resolver::Resolver::Mux::Prefix>

=back

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
