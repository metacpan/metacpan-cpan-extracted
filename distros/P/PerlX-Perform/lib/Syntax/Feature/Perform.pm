package Syntax::Feature::Perform;

use 5.006;
use strict qw(vars subs);
use PerlX::Perform qw();

BEGIN {
	$Syntax::Feature::Perform::AUTHORITY = 'cpan:TOBYINK';
	$Syntax::Feature::Perform::VERSION   = '0.006';
}

sub install
{
	my ($class, %args) = @_;
	my $into = delete $args{into};
	
	foreach my $f (qw/perform wherever/)
	{
		*{"$into\::$f"} = \&{"PerlX::Perform::$f"};
	}
}

__FILE__
__END__

=head1 NAME

Syntax::Feature::Perform - use syntax qw/perform/

=head1 DESCRIPTION

Tiny shim between L<PerlX::Perform> and L<syntax>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=PerlX-Perform>.

=head1 SEE ALSO

L<PerlX::Perform>, L<syntax>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

