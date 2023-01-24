use 5.010001;
use strict;
use warnings;

package TOBYINK::Test::Template;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001000';

use Moo;

has foo => ( is => 'ro', required => 1 );

has bar => ( is => 'rw', required => 0 );

sub foo_bar {
	my ( $self ) = @_;
	return join( q{ }, grep defined, $self->foo, $self->bar );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

TOBYINK::Test::Template - Skeleton distribution for testing purposes

=head1 SYNOPSIS

  use Test2::V0;
  use TOBYINK::Test::Template;
  
  my $o = TOBYINK::Test::Template->new( foo => 'Hello' );
  is( $o->foo_bar, 'Hello' );
  
  $o->bar( 'world' );
  is( $o->foo_bar, 'Hello world' );
  
  done_testing;

=head1 DESCRIPTION

Demonstration of testing setup.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-tobyink-test-template/issues>.

=head1 SEE ALSO

L<https://toby.ink/blog/2023/01/24/perl-testing-in-2023/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
