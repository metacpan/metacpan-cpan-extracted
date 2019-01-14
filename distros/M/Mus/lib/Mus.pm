package Mus;

use 5.008_005;
our $VERSION = '0.01';

use strictures 2;
use Import::Into;

use Mu ();
use MooX::StrictConstructor ();

sub import {
    my $caller = caller;
    $_->import::into( $caller ) for qw/ Mu MooX::StrictConstructor /;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mus - Mu but with slightly more typing and strict constructors

=head1 SYNOPSIS

  package Foo;
  use Mus;

  ro "hro";
  lazy hlazy => sub { 2 };
  rwp "hrwp";
  rw "hrw";

  my $foo = Foo->new(i_don_exist => 5, hro => "exists", hrwp => "exists", hrw => "exists");

  # Found unknown attribute(s) passed to the constructor: i_dont_exist at (eval 30) line 52.
  #     Foo::new("Foo", "i_dont_exist", 5, "hro", "exists", "hrwp", "exists", "hrw", ...) called at Foo.pl line 9

=head1 DESCRIPTION

Mus imports both L<Mu> and L<MooX::StrictConstructor> making it even less work in typing
and reading to set up an object with a strict constructor.

L<Mu::Role> should still be used for roles, as strict constructors don't apply to roles, so I did not duplicate this.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Mu>

=item *

L<MooX::StrictConstructor>

=back

=cut
