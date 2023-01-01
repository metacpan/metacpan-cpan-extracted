package Path::Resolver::Resolver::Hash 3.100455;
# ABSTRACT: glorified hash lookup
use Moose;
with 'Path::Resolver::Role::Resolver';

use namespace::autoclean;

use Moose::Util::TypeConstraints;
use Path::Resolver::SimpleEntity;

#pod =head1 SYNOPSIS
#pod
#pod   my $resolver = Path::Resolver::Resolver::Hash->new({
#pod     hash => {
#pod       foo => {
#pod         'bar.txt' => "This is the content.\n",
#pod       },
#pod     }
#pod   });
#pod
#pod   my $simple_entity = $resolver->entity_at('foo/bar.txt');
#pod
#pod This resolver looks through a has to find string content.  Path parts are used
#pod to drill down through the hash.  The final result must be a string.  Unless you
#pod really know what you're doing, it should be a byte string and not a character
#pod string.
#pod
#pod The native type of the Hash resolver is a class type of
#pod Path::Resolver::SimpleEntity.  There is no default converter.
#pod
#pod =cut

sub native_type { class_type('Path::Resolver::SimpleEntity') }

#pod =attr hash
#pod
#pod This is a hash reference in which lookups are performed.  References to copies
#pod of the string values are returned.
#pod
#pod =cut

has hash => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

sub __str_path {
  my ($self, $path) = @_;

  my $str = join '/', map { my $part = $_; $part =~ s{/}{\\/}g; $part } @$path;
}

sub entity_at {
  my ($self, $path) = @_;

  my @path = @$path;
  shift @path if $path[0] eq '';

  my $cwd = $self->hash;
  my @path_so_far;
  while (defined (my $name = shift @path)) {
    push @path_so_far, $name;

    my $entry = $cwd->{ $name};

    if (! @path) {
      return unless defined $entry;

      # XXX: Should we return because we're at a notional -d instead of -f?
      return if ref $entry;

      return Path::Resolver::SimpleEntity->new({ content_ref => \$entry });
    }

    return unless ref $entry and ref $entry eq 'HASH';

    $cwd = $entry;
  }

  Carp::confess("this should never be reached -- rjbs, 2009-04-28")
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::Resolver::Hash - glorified hash lookup

=head1 VERSION

version 3.100455

=head1 SYNOPSIS

  my $resolver = Path::Resolver::Resolver::Hash->new({
    hash => {
      foo => {
        'bar.txt' => "This is the content.\n",
      },
    }
  });

  my $simple_entity = $resolver->entity_at('foo/bar.txt');

This resolver looks through a has to find string content.  Path parts are used
to drill down through the hash.  The final result must be a string.  Unless you
really know what you're doing, it should be a byte string and not a character
string.

The native type of the Hash resolver is a class type of
Path::Resolver::SimpleEntity.  There is no default converter.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 hash

This is a hash reference in which lookups are performed.  References to copies
of the string values are returned.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
