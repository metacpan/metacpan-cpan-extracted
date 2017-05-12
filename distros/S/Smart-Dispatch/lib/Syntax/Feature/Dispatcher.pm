package Syntax::Feature::Dispatcher;

use 5.010;
use strict;
use warnings;

BEGIN {
	$Syntax::Feature::Dispatcher::AUTHORITY = 'cpan:TOBYINK';
	$Syntax::Feature::Dispatcher::VERSION   = '0.006';
}

sub install
{
	my ($class, %args) = @_;
	my $into = delete $args{into};

	require Smart::Dispatch;
	eval "package $into; Smart::Dispatch->import;";
}

__PACKAGE__
__END__

=head1 NAME

Syntax::Feature::Dispatcher - use syntax qw/dispatcher/

=head1 DESCRIPTION

Tiny shim between L<Smart::Dispatch> and L<syntax>.

=begin private

=item install

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Smart-Dispatch>.

=head1 SEE ALSO

L<Smart::Dispatch>, L<syntax>.

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


