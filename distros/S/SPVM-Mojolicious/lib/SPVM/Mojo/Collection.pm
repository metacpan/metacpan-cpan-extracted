package SPVM::Mojo::Collection;



1;

=encoding utf8

=head1 Name

SPVM::Mojo::Collection - Collection

=head1 Description

Mojo::Collection class in L<SPVM> is an array-based container for collections.

=head1 Usage

  use Mojo::Collection;
  
  my $collection = Mojo::Collection->new(["just", "works"]);

=head1 Details

SPVM's Mojo::Colletion is just a child class of L<List|SPVM::List> different from Perl's L<Mojo::Collection>.

This is because currently we want to add methods freely to L<List|SPVM::List> class without conflicting with L<Mojo::Collection|SPVM::Mojo::Collection>.

=head1 Super Class

L<List|SPVM::List>

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::Collection|SPVM::Mojo::Collection> ($array : object[] = undef, $capacity : int = -1);>

Same as L<List#new|SPVM::List/"new"> method except for the return value.

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
