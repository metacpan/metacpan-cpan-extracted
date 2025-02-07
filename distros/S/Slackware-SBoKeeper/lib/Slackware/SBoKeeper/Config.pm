package Slackware::SBoKeeper::Config;
our $VERSION = '2.04';
use 5.016;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(read_config);

sub read_config {

	my $file     = shift;
	my $callback = shift;

	my $config = {};

	open my $fh, '<', $file
		or die "Failed to open config file $file for reading: $!\n";

	my $ln = 0;
	while (my $l = readline $fh) {

		$ln++;

		# Skip comments and blanks
		next if $l =~ /^#/ or $l =~ /^\s*$/;

		unless ($l =~ /=/) {
			die "$file line $ln: Missing '='\n";
		}

		my ($field, $val) = split '=', $l, 2;
		$field =~ s/^\s+|\s+$//g;
		$val   =~ s/^\s+|\s+$//g;

		if ($val eq '') {
			die "$file line $ln: Value cannot be empty\n";
		}

		unless (defined $callback->{$field}) {
			die "$file line $ln: '$field' is not a valid field\n";
		}

		eval {
			$config->{$field} = $callback->{$field}($val);
			1; # so that $config->{$field} being 0 won't cause problems.
		} or do {
			my $e = $@ || 'Something went wrong';
			chomp $e;
			die "$file line $ln: $e\n";
		};

	}

	return $config;

}

1;

=head1 NAME

Slackware::SBoKeeper::Config - Configuration file reader

=head1 SYNOPSIS

 use Slackware::SBoKeeper::Config qw(read_config);

 my $config = read_config($file, $callbacks);

=head1 DESCRIPTION

Slackware::SBoKeeper::Config is a module that provides the C<read_config()>
subroutine, which can read L<sbokeeper> config files.
Slackware::SBoKeeper::Config is not meant to be used outside of L<sbokeeper>.
If you are looking for L<sbokeeper> user documentation, please consult its
manual.

=head1 SUBROUTINES

=over 4

=item read_config($file, $callbacks)

C<read_config> is a subroutine that reads the config file C<$file> and returns
its contents in the form of a hash ref. C<$callbacks> is a hash ref of config
fields and their respective callback subroutine references that process the
value of said field. C<$callbacks> must contain every field that is able to be
read, otherwise C<read_config> will fail on unknown fields.

Configuration files consists of lines of key-value pairs, seperated by an
equal sign (=). Blank lines and comments are ignored.

C<read_config> must be manually imported.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

=head1 BUGS

Report bugs on my Codeberg, L<https://codeberg.org/1-1sam>.

=head1 COPYRIGHT

Copyright (C) 2024-2025 Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

=head1 SEE ALSO

L<sbokeeper>

=cut
