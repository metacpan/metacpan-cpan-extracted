=head1 PURPOSE

Check Sub::NonRole loads.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 1;

{
	package Local::Role;
	use Moo::Role;
	use Sub::NonRole;
	sub zzz :NonRole { 1 };
}

{
	package Local::Class;
	use Moo;
	with qw< Local::Role >;
}

my $o = Local::Class->new;
ok not $o->can('zzz');
