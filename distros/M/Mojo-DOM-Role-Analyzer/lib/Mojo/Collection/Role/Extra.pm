package Mojo::Collection::Role::Extra ;
$Mojo::Collection::Role::Extra::VERSION = '0.015';
use Role::Tiny;

sub common {
  my $c = shift;
  my $size = $c->size;
  my $current_node = $c->first;
  my $parent_node;
  my $enclosed;
  do  {
    $parent_node = $current_node->parent;
    $enclosed = $c->grep(sub { $parent_node->is_ancestor_to($_) } );
    $current_node = $parent_node;
  } while ($size > $enclosed->size);

  return $parent_node;
}

1; # Magic true value
# ABSTRACT: provides methods for use with Mojo::DOM::Role::Analyzer

__END__

=pod

=head1 NAME

Mojo::Collection::Role::Extra - provides methods for use with Mojo::DOM::Role::Analyzer

=head1 DESCRIPTION

=head2 METHODS

=head3 common

  $dom->find('p')->common;
  $dom->at('div.foo')->find('p');

Returns the lowest common ancestor for all nodes in a collection.

=head1 VERSION

version 0.015

=head1 SEE ALSO

L<Mojo::DOM::Role::Analyzer>

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
