=pod

=encoding utf-8

=head1 PURPOSE

Test that Regexp::Util compiles and seems to work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More tests => 1;

use Regexp::Util qw( :all );

my $re = deserialize_regexp serialize_regexp qr/^foo$/;

ok("foo" =~ $re and not "fool" =~ $re);
