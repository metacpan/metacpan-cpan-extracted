use 5.008;
use strict;
use warnings;

package MooseX::AttributeTags::PRole;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use MooseX::Role::Parameterized;

parameter attributes => (
	isa      => 'HashRef[ArrayRef]',
	required => 1,
);

role {
	my $p = shift;
	my %a = %{ $p->attributes };
	
	for my $name (sort keys %a)
	{
		has $name => @{ $a{$name} };
	}
};

1;


__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::AttributeTags::PRole - guts of MooseX::AttributeTags

=head1 DESCRIPTION

No user-serviceable parts within.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-AttributeTags>.

=head1 SEE ALSO

L<MooseX::AttributeTags>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013, 2017, 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

