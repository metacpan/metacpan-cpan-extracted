package Module::Build::Functions::DSL;

use strict;
use vars qw( $VERSION );

BEGIN {
	$VERSION = '0.04';

	*inc::Module::Build::Functions::DSL::VERSION = *VERSION;
	@inc::Module::Build::Functions::DSL::ISA     = __PACKAGE__;
}

sub import {
	my $package = shift;

	# Read in the rest of the Makefile.PL
	open 0 or die "Couldn't open $0: $!";
	my $dsl;
    SCOPE: {
		local $/ = undef;
		$dsl = join "", <0>;
	}

	# Change inc::Module::Build::Functions::DSL to the regular one.
	# Remove anything before the use inc::... line.
	$dsl =~ s/.*?^\s*use\s+(?:inc::)?$package(\b[^;]*);\s*\n//sm;

	# Stripping leading prefix
	$package =~ s/^\Qinc\E:://;


	my $code = $package->get_header_code(@_);

	# Execute the header code
	if (ref $code eq 'CODE') {
    	eval { &$code() }
	} else {
	    eval $code
	}
	print STDERR "Failed to execute the generated code: $@" if $@;

	# Add the DSL plugin to the list of packages in /inc
	Module::Build::Functions::copy_package($package);

	# Convert the basic syntax to code
	$code = "package main;\n\n" . dsl2code($dsl) . "\n\nWriteAll();\n";

	# Execute the script
	eval $code;
	print STDERR "Failed to execute the generated code: $@" if $@;

	exit(0);
} ## end sub import


sub get_header_code {
    my ($self, @import_params) = @_;
    

    # Load inc::Module::Build::Functions as we would in a regular Makefile.Pl
	return sub {
        package main;
        
        require inc::Module::Build::Functions;
        inc::Module::Build::Functions->import(@import_params);
	}
}


sub dsl2code {
	my $dsl = shift;

	# Split into lines and strip blanks
	my @lines = grep {/\S/} split /[\012\015]+/, $dsl;

	# Each line represents one command
	my @code = ();
	foreach my $line (@lines) {

		# Split the lines into tokens
		my @tokens = split /\s+/, $line;

		# The first word is the command
		my $command = shift @tokens;
		my @params  = ();
		my @suffix  = ();
		while (@tokens) {
			my $token = shift @tokens;
			my $next_token;
			my $token_quoted;

			if ( $token =~ /^(\'|\")/ ) {
				$token_quoted = 1;

				if ( $token !~ /(\'|\")$/ ) {
					do {
						$next_token = shift @tokens;

						$token .= ' ' . $next_token if $next_token;

					} while ( $next_token && $next_token !~ /(\'|\")$/ );
				}
			} ## end if ( $token =~ /^(\'|\")/)

			if ( $token eq 'if' or $token eq 'unless' ) {

				# This is the beginning of a suffix
				push @suffix, $token;
				push @suffix, @tokens;
				last;
			} else {

				# Convert to a string
				$token =~ s/([\\\'\"])/\\$1/g unless $token_quoted;
				push @params, $token_quoted ? $token : "'$token'";
			}
		} ## end while (@tokens)

		# Merge to create the final line of code
		@tokens =
		  ( $command, @params ? join( ', ', @params ) : (), @suffix );
		push @code, join( ' ', @tokens ) . ";\n";
	} ## end foreach my $line (@lines)

	# Join into the complete code block
	return join( '', @code );
} ## end sub dsl2code

1;
