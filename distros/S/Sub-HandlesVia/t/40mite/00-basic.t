=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::HandlesVia works with L<Mite>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires '5.010001';

use FindBin qw($Bin);
use lib "$Bin/lib";

use MyTest;

my $object = MyTest->new;

$object->push( 22 );
$object->push( 33 );
$object->push( 44 );

is( $object->pop, 44 );
is_deeply( $object->list, [ 11, 22, 33 ] );
is( $object->pop, 33 );
is_deeply( $object->list, [ 11, 22 ] );

$object->reset;

is_deeply( $object->list, [ 11 ] );

done_testing;
