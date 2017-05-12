package Padre::Plugin::Perl6::Util;
BEGIN {
  $Padre::Plugin::Perl6::Util::VERSION = '0.71';
}

# ABSTRACT: Perl 6 plugin utilities

use strict;
use warnings;
use Padre::Constant ();

# Get perl6 full executable path
sub perl6_exe {
	my $exe = Padre::Constant::WIN32 ? 'perl6.exe' : 'perl6';

	# Look for the explicit environment variable
	if ( $ENV{RAKUDO_DIR} ) {
		my $perl6 = File::Spec->catfile( $ENV{RAKUDO_DIR}, $exe );
		if ( -f $perl6 and -x _ ) {
			return $perl6;
		}
	}

	# On Windows, look for the Six distribution
	if (Padre::Constant::WIN32) {

		# Find perl6.exe in PDX and later Six releases
		my $perl6 = 'C:\\strawberry\\six\\bin\\perl6.exe';
		if ( -f $perl6 ) {
			return $perl6;
		}

		# Stay compatible with almost-six 0.41
		$perl6 = 'C:\\strawberry\\six\\perl6.exe';
		if ( -f $perl6 ) {
			return $perl6;
		}
	}

	# Look on the path
	require File::Which;
	my $perl6 = File::Which::which('perl6');
	if ( defined $perl6 and -f $perl6 and -x _ ) {
		return $perl6;
	}

	return undef;
}

sub parrot_bin {
	my $bin = shift;
	my $exe = Padre::Constant::WIN32 ? "$bin.exe" : $bin;

	# Look for the explicit RAKUDO_DIR
	if ( $ENV{RAKUDO_DIR} ) {
		my $command = File::Spec->catfile( $ENV{RAKUDO_DIR}, 'parrot_install', $exe );
		if ( -f $command and -x _ ) {
			return $command;
		}
	}

	# On Windows, look for the Six distribution
	if (Padre::Constant::WIN32) {

		# Find parrot binary in PDX and later Six releases
		my $command = "C:\\strawberry\\six\\bin\\$exe";
		if ( -f $command and -x _ ) {
			return $command;
		}

		# Stay compatible with almost-six 0.41
		$command = "C:\\strawberry\\six\\parrot\\$exe";
		if ( -f $command and -x _ ) {
			return $command;
		}
	}

	# Look in the path for the command, fwiw
	require File::Which;
	my $command = File::Which::which($bin);
	if ( $command and -f $command and -x _ ) {
		return $command;
	}

	return undef;
}

sub libparrot {
	my $lib = Padre::Constant::WIN32 ? "libparrot.dll" : 'libparrot.so';

	# Look for the explicit RAKUDO_DIR
	if ( $ENV{RAKUDO_DIR} ) {
		my $libparrot = File::Spec->catfile( $ENV{RAKUDO_DIR}, 'parrot', $lib );
		if ( -f $libparrot ) {
			return $libparrot;
		}
	}

	# On Windows, look for the Six distribution
	if (Padre::Constant::WIN32) {
		my $libparrot = "C:\\strawberry\\six\\parrot\\libparrot.dll";
		if ( -f $libparrot ) {
			return $libparrot;
		}
	}

	return undef;
}

#
# Guess the new line for the current document
# can return \r, \r\n, or \n
#
sub guess_newline {
	my $text = shift;

	require Padre::Util;
	my $doc_new_line_type = Padre::Util::newline_type($text);
	my $new_line;
	if ( $doc_new_line_type eq "WIN" ) {
		$new_line = "\r\n";
	} elsif ( $doc_new_line_type eq "MAC" ) {
		$new_line = "\r";
	} else {

		#NONE, UNIX or MIXED
		$new_line = "\n";
	}

	return $new_line;
}

1;

__END__
=pod

=head1 NAME

Padre::Plugin::Perl6::Util - Perl 6 plugin utilities

=head1 VERSION

version 0.71

=head1 AUTHORS

=over 4

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo L<http://szabgab.com/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

