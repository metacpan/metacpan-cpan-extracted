package Surveyor::Benchmark::GetDirectoryListing;
use strict;
use warnings;

our $VERSION = '0.121';

=encoding utf8

=head1 NAME

Surveyor::App - Run benchmarks from a package

=head1 SYNOPSIS

Use this package with the C<survey> program from L<Surveyor::App>. Give
it a directory to list.

	% survey -p Surveyor::Benchmark::GetDirectoryListing directory_to_list

=head1 DESCRIPTION

This benchmark pits C<glob> against C<opendir> in the directory that
you choose.

=over 4

=item set_up( DIRECTORY )

Change to C<DIRECTORY> before running the benchmark.

=item tear_down()

A no-op.

=cut

sub set_up {
	my( $class, $directory ) = @_;
	unless( defined $directory ) {
		require Cwd;
		$directory = Cwd::cwd();
		}
	die "Directory [$directory] does not exist!\n" unless -e $directory;
	die "[$directory] does not exist!\n" unless -e $directory;
	chdir( $directory ) or die "Could not change to $ARGV[0]: $!\n";
	my @files = glob( '.* *' );
	printf "$directory has %d files\n", scalar @files;
	}

sub tear_down { 1 }

=item bench_opendir

=cut

sub bench_opendir {
	opendir my( $dh ), ".";
	my @f = readdir( $dh );
	}

=item bench_glob

=cut

sub bench_glob {
	my @f = glob(".* *")
	}

__PACKAGE__;

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in a Git repository that I haven't made public
because I haven't bothered to set it up. If you want to clone
it, just ask and we'll work something out.

	https://github.com/briandfoy/surveyor-app

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2013-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
