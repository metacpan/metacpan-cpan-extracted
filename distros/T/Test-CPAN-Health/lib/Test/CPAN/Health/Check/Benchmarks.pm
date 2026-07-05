package Test::CPAN::Health::Check::Benchmarks;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Find::Rule;
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# Conventional directory names for distribution benchmarks.
Readonly::Array my @BENCH_DIRS => qw(bench benchmarks benchmark);

=head1 NAME

Test::CPAN::Health::Check::Benchmarks - Check that benchmark scripts are present

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::Benchmarks;

    my $check  = Test::CPAN::Health::Check::Benchmarks->new;
    my $result = $check->run($dist);

=head1 DESCRIPTION

Checks for the presence of a C<bench/>, C<benchmarks/>, or C<benchmark/>
directory containing at least one file.

Score matrix:

=over 4

=item * 100 -- benchmarks directory found with at least one file.

=item *  50 -- benchmarks directory found but empty.

=item *   0 -- no benchmarks directory found.

=back

=cut

sub id          { return 'benchmarks'                                                    }
sub name        { return 'Benchmarks'                                                    }
sub description { return 'Checks that benchmark scripts are present in the distribution' }
sub weight      { return 1                                                               }
sub category    { return 'quality'                                                       }

=head2 run

=head3 PURPOSE

Locate a benchmarks directory and report whether it contains files.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional  (unused)

=head4 OUTPUT

L<Test::CPAN::Health::Result> with:

  check_id  'benchmarks'
  status    'pass' | 'warn' | 'fail'
  score     100 | 50 | 0
  summary   human-readable verdict

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  BM001 | FAIL     | No benchmarks directory found      | Add a bench/ or benchmarks/ directory
  BM002 | WARN     | Benchmarks directory is empty      | Add at least one benchmark script
  BM003 | PASS     | Benchmarks directory found         |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  BenchmarksOp
  dist  : Distribution
  score : {0, 50, 100}
  -------------------------------------------------------
  no_dir       => score = 0
  dir_empty    => score = 50
  dir_nonempty => score = 100

=head3 SIDE EFFECTS

Reads directory listings from disk.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::Benchmarks->new->run($dist);

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	for my $dir_name (@BENCH_DIRS) {
		next unless $dist->has_dir($dir_name);

		my $dir_path = File::Spec->catdir($dist->path, $dir_name);
		my @files    = File::Find::Rule->file->in($dir_path);

		if (@files) {
			return $self->_result(
				status  => 'pass',
				score   => 100,
				summary => sprintf(
					'Benchmarks directory found: %s/ (%d file(s))',
					$dir_name, scalar @files,
				),
				data => { name => $self->name, dir => $dir_name, count => scalar @files },
			);
		}

		return $self->_result(
			status  => 'warn',
			score   => 50,
			summary => sprintf('Benchmarks directory %s/ exists but is empty', $dir_name),
			details => ['Add at least one benchmark script to the directory'],
			data    => { name => $self->name, dir => $dir_name, count => 0 },
		);
	}

	return $self->_result(
		status  => 'fail',
		score   => 0,
		summary => 'No benchmarks directory found (bench/, benchmarks/, or benchmark/)',
		details => [
			'Create a bench/ or benchmarks/ directory containing Perl scripts that use the Benchmark module',
			'Each script should time key operations or compare alternative implementations, e.g.: use Benchmark qw(cmpthese); cmpthese(-1, { approach_a => sub { ... }, approach_b => sub { ... } })',
			'Benchmarks help users choose between options and help maintainers catch performance regressions early',
		],
		data    => { name => $self->name },
	);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
