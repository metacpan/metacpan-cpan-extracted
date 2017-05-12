=pod

=encoding utf-8

=head1 PURPOSE

Test C<< $_where >> with L<MooseX::Types>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -requires => { 'MooseX::Types::Moose' => 0 };

use MooseX::Types::MoreUtils;
use MooseX::Types::Moose qw( ArrayRef Int );

my $type1 = ArrayRef->$_of(Int->$_where(sub { $_ % 2 }));
ok     $type1->check( [1,3,5] );
ok not $type1->check( [1,2,3] );
ok not $type1->check( ['xx'] );

done_testing;

