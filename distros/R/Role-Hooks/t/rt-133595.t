=pod

=encoding utf-8

=head1 PURPOSE

Calling C<isa> on undefined value in Role::Hooks 0.001.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=133595>

=head1 AUTHOR

Gianni Ceccarelli E<lt>dakkar@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Gianni Ceccarelli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

{ package Local::Dummy1; use Test::Requires 'Moose';  };
{ package Local::Dummy2; use Test::Requires 'Role::Tiny';  };

use Role::Hooks;

my @ARGS;

{
	package MyRole;
	use Role::Tiny;
	Role::Hooks->before_apply( __PACKAGE__, sub { push @ARGS, [ @_ ] } );
}

{
	package OtherRole;
	use Role::Tiny;
}

{
	package MyClass;
	use Role::Tiny::With;
	with 'OtherRole'; # <--- this throws
}

is_deeply( \@ARGS, [] );

done_testing;
