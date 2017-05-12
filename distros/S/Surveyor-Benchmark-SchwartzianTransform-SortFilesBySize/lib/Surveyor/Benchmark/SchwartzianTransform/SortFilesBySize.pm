package Surveyor::Benchmark::SchwartzianTransform::SortFilesBySize;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.12';

=head1 NAME

Surveyor::Benchmark::SchwartzianTransform::SortFilesBySize -  Compare the low-tech and Schwartzian Transform sorts

=head1 SYNOPSIS

Use with C<survey> from L<Surveyor::App>:

	% survey -p Surveyor::Benchmark::SchwartzianTransform::SortFilesBySize '/glob/pattern/*'

=head1 DESCRIPTION

=over 4

=item set_up

=cut

sub set_up {
	my( $self, @args ) = @_;
	
	my $glob = $args[0];
	@L::files = glob $glob;
	print "Testing with " . @L::files . " files\n";

	my $transform = q|map $_->[0], sort { $a->[1] <=> $b->[1] } map [ $_, -M ]|;
	my $sort      = q|sort { -M $a <=> -M $b }|;

	my $code = {
		assign               =>  sub { my @r = @L::files },
		'glob'               =>  sub { my @files = glob $glob },

		sort_names           =>  sub { sort { $a cmp $b } @L::files },
		sort_names_assign    =>  sub { my @r = sort { $a cmp $b } @L::files },
		sort_times_assign    => eval "sub { my \@r = $sort \@L::files }",

		ordinary_orig        => eval "sub { my \@r = $sort glob \$glob }",
		ordinary_mod         => eval "sub { my \@r = $sort \@L::files }",

		schwartz_orig        => eval "sub { $transform, glob \$glob }",
		schwartz_orig_assign => eval "sub { my \@r = $transform, glob \$glob }",
		schwartz_mod         => eval "sub { my \@r = $transform, \@L::files }",
	};
	
	foreach my $key ( keys %$code ) {
		no strict 'refs';
		*{"bench_$key"} = $code->{$key};
		}
}

=item tear_down

=cut

sub tear_down { 1; }

=item test

=cut

sub test {
	warn "I haven't defined tests yet";
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in a Git repository:

	https://github.com/briandfoy/surveyor-benchmark-schwartziantransform-sortfilesbysize

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
