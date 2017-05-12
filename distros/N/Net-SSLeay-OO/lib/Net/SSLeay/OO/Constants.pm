
package Net::SSLeay::OO::Constants;

use strict;
use warnings;

use Net::SSLeay;

=head1 NAME

Net::SSLeay::OO::Constants - Importer interface to Net::SSLeay constants

=head1 SYNOPSIS

 use Net::SSLeay::OO::Constants qw(OP_ALL);

 print OP_ALL;

=head1 DESCRIPTION

This module allows L<Net::SSLeay> constants to be explicitly imported
into your program.

As well as avoiding using the verbose C<&Net::SSLeay::XXXX> syntax all
the time, they can then be spelt as bare words.  It also means that
instead of waiting for run-time for your misspelt Net::SSLeay
constants to crash your program, you find out at compile time.

Some extra constants are allowed to be imported by this module, which
are hard-coded for the event that Net::SSLeay doesn't export them.

=cut

our $VERSION = "0.01";

our %FALLBACK;

BEGIN {
	%FALLBACK = (
		MODE_ENABLE_PARTIAL_WRITE       => 1,
		MODE_ACCEPT_MOVING_WRITE_BUFFER => 2,
		MODE_AUTO_RETRY                 => 4,
		MODE_NO_AUTO_CHAIN              => 8,
	);
}

sub import {
	my $class  = shift;
	my $target = caller;
	while ( my $thingy = shift ) {
		if ( $thingy =~ m{^\d+} ) {
			no warnings "numeric";
			die "insufficient version $thingy"
				if 0 + $thingy < 0 + $VERSION;
		}
		else {
			no strict 'refs';
			my $val = eval { &{"Net::SSLeay::$thingy"}() };
			if ( defined $val ) {
				*{ $target . "::" . $thingy } = sub() {$val};
			}
			elsif ( exists $FALLBACK{$thingy} ) {
				$val = $FALLBACK{$thingy};
				*{ $target . "::" . $thingy } = sub() {
					$val;
				};
			}
			else {
				die
					"tried to import '$thingy', but SSLeay said: $@";
			}
		}
	}
}

1;

__END__

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
# vim: filetype=perl:noexpandtab:ts=3:sw=3
