package Shell::Var::Reader;

use 5.006;
use strict;
use warnings;
use File::Slurp qw(read_file);

=head1 NAME

Shell::Var::Reader - Runs a sh or bash script and returns the variables that have been set as well as their values.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

Lets say '/usr/local/etc/someconfig.conf' which is basically a shell
config and read via include in a sh or bash script, this can be used for
getting a hash ref conttaining them.

Similarly on systems like FreeBSD, this is also useful for reading '/etc/rc.conf'.

    use Shell::Var::Reader;
    use Data::Dumper;

    my $found_vars=Shell::Var::Reader->read_in('/usr/local/etc/someconfig.conf');

    print Dumper($found_vars);

=head1 SUBROUTINES

=head2 read_in

This runs a specified file as a include and then figures out what the
new variables are. fetching them.

=cut

sub read_in {
	my $file = $_[1];

	if ( !defined($file) ) {
		die('No file specified');
	}

	if ( !-f $file ) {
		die( '"' . $file . '" does not exist or is not a file' );
	}

	# figure out if we are using bash or not
	my $raw_file  = read_file($file) or die 'Failed to read "' . $file . '"';
	my @raw_split = split( /\n/, $raw_file );
	my $shell     = 'sh';
	if ( defined( $raw_split[0] ) && ( $raw_split[0] =~ /^\#\!.*bash/ ) ) {
		$shell = 'bash';
	}

	#
	# figure out what variables already exist...
	#
	my $cmd           = $shell . " -c 'if [ -z \"\$BASH_VERSION\" ]; then set; else set -o posix; set; fi'";
	my $results       = `$cmd`;
	my $base_vars     = {'ShellVarReaderFile'=>1};
	my @results_split = split( /\n/, $results );
	foreach my $line (@results_split) {
		if ( $line =~ /^[\_a-zA-Z]+[\_a-zA-Z0-9]*\=/ ) {
			my @line_split = split( /=/, $line, 2 );
			$base_vars->{ $line_split[0] } = 1;
		}
	}

	#
	# Figure out what has been set
	#
	$ENV{ShellVarReaderFile} = $file;
	$cmd
		= $shell . " -c ' . \"\$ShellVarReaderFile\" > /dev/null 2> /dev/null ; if [ -z \"\$BASH_VERSION\" ]; then set; else set -o posix; set; fi'";
	$results = `$cmd`;
	my $found_vars = {};
	@results_split = split( /\n/, $results );
	my $multiline = 0;
	my $var_key;

	foreach my $line (@results_split) {
		if ( $line =~ /^[\_a-zA-Z]+[\_a-zA-Z0-9]*\=/ && !$multiline ) {
			my @line_split = split( /=/, $line, 2 );
			$var_key = $line_split[0];
			$found_vars->{$var_key} = $line_split[1];

			# if the value starts with a ' and does not end with a '
			# it is going to be multiline
			if (   $found_vars->{$var_key} =~ /^\'/
				&& $found_vars->{$var_key} !~ /\'$/ )
			{
				$found_vars->{$var_key} =~ s/^\'//;
				$multiline = 1;
			}else {
				$found_vars->{$var_key} =~ s/^\'//;
				$found_vars->{$var_key} =~ s/\'$//;
			}
		}
		else {
			$found_vars->{$var_key} = $line;
			# if it ends with ', then we have reached the end of the variable
			if ( $found_vars->{$var_key} =~ /\'$/ ) {
				$found_vars->{$var_key} =~ s/\'$//;
				$multiline = 0;
			}
		}
	}

	#
	# remove base vars
	#
	my @found_keys=keys(%{ $found_vars });
	foreach my $var_key (@found_keys) {
		if (defined($base_vars->{$var_key})) {
			delete $found_vars->{$var_key};
		}
	}

	return $found_vars;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-shell-var-reader at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Shell-Var-Reader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Shell::Var::Reader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Shell-Var-Reader>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Shell-Var-Reader>

=item * Search CPAN

L<https://metacpan.org/release/Shell-Var-Reader>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Shell::Var::Reader
