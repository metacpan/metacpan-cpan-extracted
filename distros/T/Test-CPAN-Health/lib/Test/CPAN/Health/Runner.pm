package Test::CPAN::Health::Runner;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use Readonly;
use Scalar::Util qw(blessed);
use Params::Validate::Strict qw(validate_strict);

our $VERSION = '0.1.0';

=head1 NAME

Test::CPAN::Health::Runner - Orchestrate health checks against a distribution

=head1 SYNOPSIS

    use Test::CPAN::Health::Runner;

    my $runner = Test::CPAN::Health::Runner->new(
        checks => \@check_objects,
        cache  => $cache,
    );

    my $report = $runner->run($distribution);

=head1 DESCRIPTION

The Runner iterates over an ordered list of L<Test::CPAN::Health::Check>
objects, invokes each against a L<Test::CPAN::Health::Distribution>, wraps
any exceptions so a single failing check cannot abort the run, and collects
the L<Test::CPAN::Health::Result> objects into a L<Test::CPAN::Health::Report>.

Context propagation: after each check completes its result is stored, and
subsequent checks can inspect previously-completed results via the context
hashref passed to C<run>.  This is how C<ReverseDeps> count reaches
C<SecurityAdvisories> to scale its weight.

=head1 LIMITATIONS

=over 4

=item * Checks run sequentially.  Parallel execution via C<Parallel::ForkManager>
is planned for a future release.

=item * A check that calls C<exit> directly will terminate the entire run.

=back

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			checks => { type => 'arrayref', optional => 1, default => [] },
			cache  => { type => 'object', isa => 'Test::CPAN::Health::Cache', optional => 1 },
		},
		input => \%args,
	) };

	my $self = bless {
		_checks  => $args{checks},
		_cache   => $args{cache},
	}, $class;

	return $self;
}

=head2 run

=head3 PURPOSE

Execute all configured checks against the given distribution and return a
populated L<Test::CPAN::Health::Report>.

Each check is wrapped in an eval block: exceptions produce an C<error>-status
Result rather than aborting the run.  Checks may return C<undef> to indicate
they are not applicable; those are silently skipped.

=head3 API SPECIFICATION

=head4 INPUT

  dist  Test::CPAN::Health::Distribution  required

=head4 OUTPUT

L<Test::CPAN::Health::Report> object with all results attached.

=head3 MESSAGES

  Code  | Severity | Message                              | Resolution
  ------+----------+--------------------------------------+------------------------
  RUN01 | WARNING  | Check {id} failed with exception {e} | Fix check or report bug

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  RunOp
  checks      : seq Check
  dist        : Distribution
  report!     : Report
  -------------------------------------------------------
  #report!.results <= #checks
  forall c : checks @
    (exists r : report!.results @ r.check_id = c.id)
    \/ c returned undefined

=head3 SIDE EFFECTS

Runs each check, which may have network, filesystem, and subprocess side
effects.  Writes check results to the cache if a cache is configured.

=head3 USAGE EXAMPLE

    my $report = $runner->run($dist);
    printf "%d checks run\n", scalar @{$report->results};

=cut

sub run {
	my ($self, $dist) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless blessed($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	require Test::CPAN::Health::Report;

	my $report  = Test::CPAN::Health::Report->new(checks => $self->{_checks});
	my %context;    # shared state for inter-check communication

	for my $check (@{$self->{_checks}}) {
		my $result = $self->_run_one($check, $dist, \%context);
		next unless defined $result;

		# Stamp the check category onto the result's data hash so the
		# Report can group by category without holding a reference to checks.
		$result->data->{category} = $check->category;

		$report->add_result($result);

		# Publish to context so later checks can observe earlier outcomes.
		$context{ $check->id } = $result;
	}

	return $report;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Attempt to run one check, catching any exception and converting it to an
# error Result.  Also handles the cache lookup/store cycle.
sub _run_one {
	my ($self, $check, $dist, $context) = @_;

	my $cache_key = $self->_cache_key($check, $dist);

	# Cache hit: deserialise and return early -- avoids network/disk work.
	if ($self->{_cache} && defined $cache_key) {
		my $cached = $self->{_cache}->get($cache_key);
		if (defined $cached) {
			require Test::CPAN::Health::Result;
			return Test::CPAN::Health::Result->new(%{$cached});
		}
	}

	my $result;
	my $ok = eval {
		local $SIG{__DIE__} = sub { };   # suppress autodie noise inside eval
		$result = $check->run($dist, $context);
		1;
	};

	if (!$ok) {
		carp sprintf("Check '%s' failed with exception: %s", $check->id, $@);
		$result = $check->_error("Internal check error: $@");
	} elsif (defined $result
		&& !(blessed($result) && $result->isa('Test::CPAN::Health::Result')))
	{
		# A check that returns a defined non-Result value is a programming error.
		# Convert it to an error Result so the run can continue rather than dying
		# when the outer loop tries to call $result->data->{category}.
		carp sprintf("Check '%s' returned a non-Result value (type: %s); treating as error",
			$check->id, ref($result) || 'SCALAR');
		$result = $check->_error(
			sprintf('Check returned non-Result: %s', ref($result) || 'SCALAR'),
		);
	}

	# Cache pass/warn/fail results so network API calls are not repeated.
	# Skip results are NOT cached -- they reflect runtime flags (e.g. --no-network)
	# or missing optional deps, not immutable distribution properties.  Caching a
	# skip would hide the real result on the next run once the flag is removed or
	# the optional dep is installed.
	if ($self->{_cache} && defined $result
		&& !$result->is_error && !$result->is_skip && defined $cache_key)
	{
		$self->{_cache}->store($cache_key, $result->as_hash);
	}

	return $result;
}

# Build a cache key from the dist name+version and check id.
# Returns undef for checks that should never be cached (future: per-check flag).
sub _cache_key {
	my ($self, $check, $dist) = @_;

	my $name    = $dist->name    // return;
	my $version = $dist->version // 'UNKNOWN';

	return join(':', $check->id, $name, $version);
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
