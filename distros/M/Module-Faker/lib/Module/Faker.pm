package Module::Faker 0.024;
# ABSTRACT: build fake dists for testing CPAN tools

use 5.008;
use Moose 0.33;

use Module::Faker::Dist;

use File::Next ();

#pod =head1 SYNOPSIS
#pod
#pod   Module::Faker->make_fakes({
#pod     source => './dir-of-specs', # ...or a single file
#pod     dest   => './will-contain-tarballs',
#pod   });
#pod
#pod =head2 DESCRIPTION
#pod
#pod Module::Faker is a tool for building fake CPAN modules and, perhaps more
#pod importantly, fake CPAN distributions.  These are useful for running tools that
#pod operate against CPAN distributions without having to use real CPAN
#pod distributions.  This is much more useful when testing an entire CPAN instance,
#pod rather than a single distribution, for which see L<CPAN::Faker|CPAN::Faker>.
#pod
#pod =method make_fakes
#pod
#pod   Module::Faker->make_fakes(\%arg);
#pod
#pod This method creates a new Module::Faker and builds archives in its destination
#pod directory for every dist-describing file in its source directory.  See the
#pod L</new> method below.
#pod
#pod =method new
#pod
#pod   my $faker = Module::Faker->new(\%arg);
#pod
#pod This create the new Module::Faker.  All arguments may be accessed later by
#pod methods of the same name.  Valid arguments are:
#pod
#pod   source - the directory in which to find source files
#pod   dest   - the directory in which to construct dist archives
#pod
#pod   dist_class - the class used to fake dists; default: Module::Faker::Dist
#pod
#pod The source files are essentially a subset of CPAN::Meta files with some
#pod optional extra features.  All you really require are the name and
#pod abstract.  Other bits like requirements can be specified and will be passed
#pod through.  Out of the box the module will create the main module file based
#pod on the module name and a single test file.  You can either use the provides
#pod section of the CPAN::META file or to specify their contents use the
#pod X_Module_Faker append section.
#pod
#pod The X_Module_Faker also allows you to alter the cpan_author from the
#pod default 'LOCAL <LOCAL@cpan.local>' which overrides whatever is in the
#pod usual CPAN::Meta file.
#pod
#pod Here is an example yaml specification from the tests,
#pod
#pod     name: Append
#pod     abstract: nothing to see here
#pod     provides:
#pod       Provides::Inner:
#pod         file: lib/Provides/Inner.pm
#pod         version: 0.001
#pod       Provides::Inner::Util:
#pod         file: lib/Provides/Inner.pm
#pod     X_Module_Faker:
#pod       cpan_author: SOMEONE
#pod       append:
#pod         - file: lib/Provides/Inner.pm
#pod           content: "\n=head1 NAME\n\nAppend - here I am"
#pod         - file: t/foo.t
#pod           content: |
#pod             use Test::More;
#pod         - file: t/foo.t
#pod           content: "ok(1);"
#pod
#pod If you need to sort the packages within a file you
#pod can use an X_Module_Faker:order parameter on the
#pod provides class.
#pod
#pod     provides:
#pod       Provides::Inner::Sorted::Charlie:
#pod         file: lib/Provides/Inner/Sorted.pm
#pod         version: 0.008
#pod         X_Module_Faker:
#pod           order: 2
#pod       Provides::Inner::Sorted::Alfa:
#pod         file: lib/Provides/Inner/Sorted.pm
#pod         version: 0.001
#pod         X_Module_Faker:
#pod           order: 1
#pod
#pod The supported keys from CPAN::Meta are,
#pod
#pod =over
#pod
#pod =item *  abstract
#pod
#pod =item *  license
#pod
#pod =item *  name
#pod
#pod =item *  release_status
#pod
#pod =item *  version
#pod
#pod =item *  provides
#pod
#pod =item *  prereqs
#pod
#pod =item *  x_authority
#pod
#pod =back
#pod
#pod =cut

has source => (is => 'ro', required => 1);
has dest   => (is => 'ro', required => 1);
has author_prefix => (is => 'ro', default => 0);

has dist_class => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
  default  => sub { 'Module::Faker::Dist' },
);

sub BUILD {
  my ($self) = @_;

  for (qw(source dest)) {
    my $dir = $self->$_;
    Carp::croak "$_ directory does not exist"     unless -e $dir;
    Carp::croak "$_ directory is not readable"    unless -r $dir;
  }

  Carp::croak "$_ directory is not writeable" unless -w $self->dest;
}

sub make_fakes {
  my ($class, $arg) = @_;

  my $self = ref $class ? $class : $class->new($arg);

  my $iter = File::Next::files($self->source);

  while (my $file = $iter->()) {
    my $dist = $self->dist_class->from_file($file);
    $dist->make_archive({
      dir => $self->dest,
      author_prefix => $self->author_prefix,
    });
  }
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Faker - build fake dists for testing CPAN tools

=head1 VERSION

version 0.024

=head1 SYNOPSIS

  Module::Faker->make_fakes({
    source => './dir-of-specs', # ...or a single file
    dest   => './will-contain-tarballs',
  });

=head2 DESCRIPTION

Module::Faker is a tool for building fake CPAN modules and, perhaps more
importantly, fake CPAN distributions.  These are useful for running tools that
operate against CPAN distributions without having to use real CPAN
distributions.  This is much more useful when testing an entire CPAN instance,
rather than a single distribution, for which see L<CPAN::Faker|CPAN::Faker>.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 make_fakes

  Module::Faker->make_fakes(\%arg);

This method creates a new Module::Faker and builds archives in its destination
directory for every dist-describing file in its source directory.  See the
L</new> method below.

=head2 new

  my $faker = Module::Faker->new(\%arg);

This create the new Module::Faker.  All arguments may be accessed later by
methods of the same name.  Valid arguments are:

  source - the directory in which to find source files
  dest   - the directory in which to construct dist archives

  dist_class - the class used to fake dists; default: Module::Faker::Dist

The source files are essentially a subset of CPAN::Meta files with some
optional extra features.  All you really require are the name and
abstract.  Other bits like requirements can be specified and will be passed
through.  Out of the box the module will create the main module file based
on the module name and a single test file.  You can either use the provides
section of the CPAN::META file or to specify their contents use the
X_Module_Faker append section.

The X_Module_Faker also allows you to alter the cpan_author from the
default 'LOCAL <LOCAL@cpan.local>' which overrides whatever is in the
usual CPAN::Meta file.

Here is an example yaml specification from the tests,

    name: Append
    abstract: nothing to see here
    provides:
      Provides::Inner:
        file: lib/Provides/Inner.pm
        version: 0.001
      Provides::Inner::Util:
        file: lib/Provides/Inner.pm
    X_Module_Faker:
      cpan_author: SOMEONE
      append:
        - file: lib/Provides/Inner.pm
          content: "\n=head1 NAME\n\nAppend - here I am"
        - file: t/foo.t
          content: |
            use Test::More;
        - file: t/foo.t
          content: "ok(1);"

If you need to sort the packages within a file you
can use an X_Module_Faker:order parameter on the
provides class.

    provides:
      Provides::Inner::Sorted::Charlie:
        file: lib/Provides/Inner/Sorted.pm
        version: 0.008
        X_Module_Faker:
          order: 2
      Provides::Inner::Sorted::Alfa:
        file: lib/Provides/Inner/Sorted.pm
        version: 0.001
        X_Module_Faker:
          order: 1

The supported keys from CPAN::Meta are,

=over

=item *  abstract

=item *  license

=item *  name

=item *  release_status

=item *  version

=item *  provides

=item *  prereqs

=item *  x_authority

=back

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Colin Newell David Golden Steinbrunner gregor herrmann Jeffrey Ryan Thalhammer Mohammad S Anwar Moritz Onken Randy Stauner Ricardo Signes

=over 4

=item *

Colin Newell <colin.newell@gmail.com>

=item *

David Golden <dagolden@cpan.org>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

gregor herrmann <gregoa@debian.org>

=item *

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Moritz Onken <onken@netcubed.de>

=item *

Randy Stauner <randy@magnificent-tears.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Ricardo Signes <rjbs@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
