package Slackware::SBoKeeper::DataFile;
our $VERSION = '1.02';
use 5.016;
use strict;
use warnings;

my $DELIMIT = '%%';

sub write_data {

	my $data = shift;
	my $out  = shift;

	open my $fh, '>', $out or die "Failed to open $out for writing: $!\n";

	foreach my $p (sort keys %{$data}) {

		say { $fh } "PACKAGE: $p";
		say { $fh } "DEPS: ", join(' ', @{$data->{$p}->{Deps}});
		say { $fh } "MANUAL: $data->{$p}->{Manual}";
		say { $fh } $DELIMIT;

	}

	close $fh;

}

sub read_data {

	my $file = shift;
	my $data = {};

	open my $fh, '<', $file or die "Failed to open $file for reading: $!\n";

	my $pkg = '';
	my $lnum = 1;

	while (my $l = readline $fh) {

		chomp $l;

		if ($l eq $DELIMIT) {
			$pkg = '';
		} elsif ($l =~ /^PACKAGE: /) {
			$pkg = $l =~ s/^PACKAGE: //r;
			$data->{$pkg} = {};
		} elsif ($pkg eq '') {
			die "Bad line in $file at line $lnum: PACKAGE not set\n";
		} elsif ($l =~ /^DEPS: /) {
			my $depstr = $l =~ s/^DEPS: //r;
			@{$data->{$pkg}->{Deps}} = split /\s/, $depstr;
		} elsif ($l =~ /^MANUAL: /) {
			my $manual = $l =~ s/^MANUAL: //r;
			$data->{$pkg}->{Manual} = $manual eq '1' ? 1 : 0;
		} else {
			die "Bad line in $file at line $lnum\n";
		}

		$lnum++;

	}

	close $fh;

	return $data;

}

1;



=head1 NAME

Slackware::SBoKeeper::DataFile - Read/write sbokeeper data files

=head1 SYNOPSIS

  use Slackware::SBoKeeper::DataFile;

  $data = Slackware::SBoKeeper::DataFile->read_data($datafile);

  Slackware::SBoKeeper::DataFile->write_data($data, $path);

=head1 DESCRIPTION

Slackware::SBoKeeper::DataFile is a component of L<sbokeeper> that deals with
reading/writing sbokeeper data files. The data file format is described in the
manual page for L<sbokeeper>.

=head1 Functions

=head2 Slackware::SBoKeeper::DataFile->read_data($datafile)

Reads data from $datafile and returns data hash ref. The hash ref will look
something like this:

  {
    'pkg1' => {
      Deps   => [ ... ],
      Manual => 1 or 0,
    },
    'pkg2' => {
      ...
    },
    ...
  }

=head2 Slackware::SBoKeeper::DataFile->write_data($data, $path)

Writes data hash ref $data to $path.

=head1 AUTHOR

Written by Samuel Young E<lt>L<samyoung12788@gmail.com>E<gt>.

=head1 BUGS

Report bugs on my Codeberg, L<https://codeberg.org/1-1sam>.

=head1 COPYRIGHT

Copyright (C) 2024 Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

=head1 SEE ALSO

L<sbokeeper>, L<Slackware::SBoKeeper>

=cut
