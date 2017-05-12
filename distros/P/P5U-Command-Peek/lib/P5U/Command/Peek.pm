package P5U::Command::Peek;

use 5.010;
use strict;
use utf8;
use P5U-command;

BEGIN {
	$P5U::Command::Peek::AUTHORITY = 'cpan:TOBYINK';
	$P5U::Command::Peek::VERSION   = '0.001';
}

use constant {
	abstract    => q[peek at an SV],
	usage_desc  => q[%c peek CODE],
};

sub command_names {qw{ peek }}

sub opt_spec
{
	qw()
}

use constant description => <<'DESC';
This is a simple wrapper around Devel::Peek.

Examples:

	p5u peek '[]'
	p5u peek 'my @arr; push @arr, 1; \@arr'
DESC

sub execute
{
	require Devel::Peek;
	my $__sub = eval "no strict; sub { @{[ join ';', @{ $_[2] } ]} }";
	Devel::Peek::Dump( $__sub->() );
}

1;

__END__

=head1 NAME

P5U::Command::Peek - p5u extension to peek at SVs

=head1 SYNOPSIS

  p5u peek '[]'

  p5u peek 'my @arr; push @arr, 1; \@arr'

=head1 DESCRIPTION

This is a simple wrapper around Devel::Peek.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U-Command-Peek>.

=head1 SEE ALSO

L<P5U>.

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

