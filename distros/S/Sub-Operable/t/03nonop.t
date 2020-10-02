=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::Operable works in a trickier case.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use 5.008009;
use strict;
use warnings;
use Test::More;
use Sub::Operable -all;

my $bold = subop { "<b>" . $_ . "</b>" };
my $caps = subop { uc $_ };

my $caps_bold = $caps->($bold);
my $bold_caps = $bold->($caps);

ok isa_Sub_Operable($caps_bold);
ok isa_Sub_Operable($bold_caps);

is $caps_bold->("foo"), '<B>FOO</B>';
is $bold_caps->("foo"), '<b>FOO</b>';

done_testing;

