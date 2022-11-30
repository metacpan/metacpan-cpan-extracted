=pod

=encoding utf-8

=head1 PURPOSE

Test that Object::Adhoc objects can be passed through JSON encoders.

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

use Object::Adhoc;
use JSON::PP;

my $obj  = object { foo => 1, bar => 2 };
my $json = 'JSON::PP'->new->convert_blessed( 1 )->encode( $obj );

like $json, qr/foo/;
like $json, qr/bar/;

done_testing;
