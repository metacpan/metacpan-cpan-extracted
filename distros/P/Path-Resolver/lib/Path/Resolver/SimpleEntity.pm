package Path::Resolver::SimpleEntity;
{
  $Path::Resolver::SimpleEntity::VERSION = '3.100454';
}
# ABSTRACT: a dead-simple entity to return, only provides content
use Moose;

use MooseX::Types::Moose qw(ScalarRef);

use namespace::autoclean;


has content_ref => (is => 'ro', isa => ScalarRef, required => 1);


sub content { return ${ $_[0]->content_ref } }


sub length  {
  length ${ $_[0]->content_ref }
}

1;

__END__

=pod

=head1 NAME

Path::Resolver::SimpleEntity - a dead-simple entity to return, only provides content

=head1 VERSION

version 3.100454

=head1 SYNOPSIS

  my $entity = Path::Resolver::SimpleEntity->new({
    content_ref => \$string,
  });

  printf "Content: %s\n", $entity->content; 

This class is used as an extremely simple way to represent hunks of stringy
content.

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

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
