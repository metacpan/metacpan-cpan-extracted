package Surveyor::App;
use strict;
use warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.12';

=head1 NAME

Surveyor::App - Run benchmarks from a package

=head1 SYNOPSIS

	use Surveyor::App;

=head1 DESCRIPTION

C<Surveyor::App> provides a minimal framework and convention for
people to distribute benchmarks. By creating a package in a special
way, you can easily share your benchmarks with people without having
to repeat a lot of code.

First, if you want to do some setup before your benchmarks run, define
a C<set_up> method. Do whatever you need there, such as setting
environment variables, changing directories, and so on. The C<set_up>
method gets the command-line arguments you specified when you run
C<survey>, save for any that C<survey> used for itself.

Next, define your benchmarks in subroutines whose names start with
C<bench_>. Surveyor::App will find each of those, using the part of
the name after C<bench_> as the label for that test.

Last, if you want to do some setup before your benchmarks run, define
a C<tear_down> method. The C<tear_down> method gets no arguments.

Your benchmarking package doesn't have to have any particular name and
it doesn't need to subclass or C<use> this package. See
L<Surveyor::GetDirectoryListing> for an example.

=over 4

=cut

=item run( PACKAGE, ITERATIONS, @ARGS )

Find all of the subroutines that start with C<bench_> in C<PACKAGE>
and run each of them C<ITERATIONS> times.

Before it does that, though, call the C<set_up> routine in C<PACKAGE>
as a class method. After benchmarking, call the C<tear_down> routine
in C<PACKAGE> as a class method.

=cut

sub run {
	my( $package, $iterations, @args ) = @_;
	$package->set_up( @args ) if $package->can( 'set_up' );

	# the key is a label, which is the stuff after bench_
	no strict 'refs';
	my %hash = map {
		(
			do { (my $s = $_) =~ s/\Abench_//; $s },
			\&{"${package}::$_"}
		)
		} get_all_bench_( $package );

	die "Did not find any bench_ subroutines in [$package]\n"
		unless keys %hash;

	require Benchmark;
	my $results = Benchmark::timethese( $iterations, \%hash );

	$package->tear_down() if $package->can( 'tear_down' );
	}

=item test( PACKAGE, @ARGS )

Find all of the subroutines that start with C<bench_> in C<PACKAGE>
and run each of them once. Compare the return values of each to ensure
they are the same.

Before it does that, though, call the C<set_up> routine in C<PACKAGE>
as a class method. After benchmarking, call the C<tear_down> routine
in C<PACKAGE> as a class method.

=cut

sub test {
	my( $package, @args ) = @_;
	my @subs = get_all_bench_( $package );
	my %results;

	$package->set_up( @args ) if $package->can( 'set_up' );
	foreach my $sub ( get_all_bench_( $package ) ) {
		my @return = $package->$sub();
		$results{$sub} = \@return;
		}
	$package->tear_down() if $package->can( 'tear_down' );

	use Test::More;

	subtest pairs => sub {
		my @subs = keys %results;
		foreach my $i ( 1 .. $#subs ) {
			my @sub_names = @subs[ $i - 1, $i ];
			my( $first, $second ) = @results{ @sub_names };
			local $" = " and ";
			is_deeply( $first, $second, "@sub_names match return values" );
			}
		};

	done_testing();
	}

=item get_all_bench_( PACKAGE )

Extract all of the subroutines starting with C<bench_> in C<PACKAGE>.
If you don't define a package, it uses the package this subroutine
was compiled in (so that's probably useless).


=cut

sub get_all_bench_ {
	my( $package ) = @_;
	$package = defined $package ? $package : __PACKAGE__;

	no strict 'refs';
	my @subs =
		grep /\Abench_/,
		keys %{"${package}::"};
	}


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

Copyright (c) 2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
