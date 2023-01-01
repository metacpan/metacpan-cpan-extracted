use strict;
use warnings; # stupid CPANTS!
package Path::Resolver 3.100455;
# ABSTRACT: go from "file" names to things

#pod =head1 DESCRIPTION
#pod
#pod Path::Resolver is a set of libraries for resolving virtual file paths into
#pod entities that may be found at those paths.  Here's a trivial example:
#pod
#pod   use Path::Resolver::Resolver::FileSystem;
#pod
#pod   # Create a resolver that looks at the filesystem, starting in /etc
#pod   my $fs = Path::Resolver::Resolver::FileSystem->new({ root => '/etc' });
#pod
#pod   my $file = $fs->entity_at('/postfix/main.cf');
#pod
#pod Assuming it exists, this will return an object representing the file
#pod F</etc/postfix/main.cf>.  Using the code above, C<$file> would be a
#pod C<Path::Resolver::SimpleEntity> object, which has a C<content> method.  We
#pod could print the contents of the file to screen like this:
#pod
#pod   print $file->content;
#pod
#pod =head1 WHAT'S THE POINT?
#pod
#pod Path::Resolver lets you use a simple, familiar notation for accessing all kinds
#pod of hierarchical data.  It's also distributed with resolvers that act as
#pod multiplexers for other resolvers.  Since all resolvers share one mechanism for
#pod addressing content, they can easily be mixed and matched.  Since resolvers know
#pod what kind of object they'll return, and can be fitted with translators, it's
#pod easy to ensure that all your multiplexed resolvers will resolve names to the
#pod same kind of object.
#pod
#pod For example, we could overlay two search paths like this:
#pod
#pod   my $resolver = Path::Resolver::Resolver::Mux::Ordered->new({
#pod     resolvers => [
#pod       Path::Resolver::Resolver::FileSystem->new({ root => './config' }),
#pod       Path::Resolver::Resolver::Archive::Tar->new({ archive => 'config.tgz' }),
#pod     ],
#pod   });
#pod
#pod   $resolver->entity_at('/foo/bar.txt');
#pod
#pod This will return an entity representing F<./config/foo/bar.txt> if it exists.
#pod If it doesn't, it will look for F<foo/bar.txt> in the contents of the archive.
#pod If that's found, an entity will be returned.  Finally, if neither is found, it
#pod will return false.
#pod
#pod Alternately, you could multiplex based on path:
#pod
#pod   my $resolver = Path::Resolver::Resolver::Mux::Prefix->new({
#pod     config   => Path::Resolver::Resolver::FileSystem->new({
#pod       root => '/etc/my-app',
#pod     }),
#pod
#pod     template => Path::Resolver::Resolver::Mux::Ordered->new({
#pod       Path::Resolver::Resolver::DistDir->new({ module => 'MyApp' }),
#pod       Path::Resolver::Resolver::DataSection->new({ module => 'My::Framework' }),
#pod     }),
#pod   });
#pod
#pod The path F</config/main.cf> would be looked for on disk as
#pod F</etc/my-app/main.cf>.  The path F</template/main.html> would be looked for
#pod first as F<main.html> in the sharedir for MyApp and failing that in the DATA
#pod section of My::Framework.
#pod
#pod =head1 WHERE DO I GO NEXT?
#pod
#pod If you want to read about how to write a resolver, look at
#pod L<Path::Resolver::Role::Resolver|Path::Resolver::Role::Resolver>.
#pod
#pod If you want to read about the interfaces to the existing resolvers look at
#pod their documentation:
#pod
#pod =over
#pod
#pod =item * L<Path::Resolver::Resolver::AnyDist>
#pod
#pod =item * L<Path::Resolver::Resolver::Archive::Tar>
#pod
#pod =item * L<Path::Resolver::Resolver::DataSection>
#pod
#pod =item * L<Path::Resolver::Resolver::DistDir>
#pod
#pod =item * L<Path::Resolver::Resolver::FileSystem>
#pod
#pod =item * L<Path::Resolver::Resolver::Hash>
#pod
#pod =item * L<Path::Resolver::Resolver::Mux::Ordered>
#pod
#pod =item * L<Path::Resolver::Resolver::Mux::Prefix>
#pod
#pod =back
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver - go from "file" names to things

=head1 VERSION

version 3.100455

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Florian Ragwitz Ricardo Signes

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
