package Path::Resolver::SimpleEntity 3.100455;
# ABSTRACT: a dead-simple entity to return, only provides content
use Moose;

use MooseX::Types::Moose qw(ScalarRef);

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod   my $entity = Path::Resolver::SimpleEntity->new({
#pod     content_ref => \$string,
#pod   });
#pod
#pod   printf "Content: %s\n", $entity->content; 
#pod
#pod This class is used as an extremely simple way to represent hunks of stringy
#pod content.
#pod
#pod =attr content_ref
#pod
#pod This is the only real attribute of a SimpleEntity.  It's a reference to a
#pod string that is the content of the entity.
#pod
#pod =cut

has content_ref => (is => 'ro', isa => ScalarRef, required => 1);

#pod =method content
#pod
#pod This method returns the dereferenced content from the C<content_ref> attribuet.
#pod
#pod =cut

sub content { return ${ $_[0]->content_ref } }

#pod =method length
#pod
#pod This method returns the length of the content.
#pod
#pod =cut

sub length  {
  length ${ $_[0]->content_ref }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::SimpleEntity - a dead-simple entity to return, only provides content

=head1 VERSION

version 3.100455

=head1 SYNOPSIS

  my $entity = Path::Resolver::SimpleEntity->new({
    content_ref => \$string,
  });

  printf "Content: %s\n", $entity->content; 

This class is used as an extremely simple way to represent hunks of stringy
content.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 content_ref

This is the only real attribute of a SimpleEntity.  It's a reference to a
string that is the content of the entity.

=head1 METHODS

=head2 content

This method returns the dereferenced content from the C<content_ref> attribuet.

=head2 length

This method returns the length of the content.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
