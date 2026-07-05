package Test::CPAN::Health::Check::AbandonedDeps;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use HTTP::Tiny ();
use JSON::MaybeXS ();
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

Readonly::Scalar my $METACPAN_API     => 'https://fastapi.metacpan.org/v1';
Readonly::Scalar my $HTTP_TIMEOUT     => 30;
Readonly::Scalar my $SCORE_PASS       => 80;
Readonly::Scalar my $SCORE_WARN       => 60;
Readonly::Scalar my $ABANDONED_YEARS  => 3;

# Seconds in one year (approximate)
Readonly::Scalar my $SECS_PER_YEAR => 31_557_600;   # 365.25 * 24 * 3600

=head1 NAME

Test::CPAN::Health::Check::AbandonedDeps - Check for dependencies with no recent releases

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::AbandonedDeps;

    my $check  = Test::CPAN::Health::Check::AbandonedDeps->new;
    my $result = $check->run($dist);

=head1 DESCRIPTION

Queries MetaCPAN to find the date of the latest release for each runtime
dependency.  A dependency is flagged as I<potentially abandoned> when its
most recent release is older than C<ABANDONED_YEARS> (currently 3 years).

Perl core modules and lowercase pragmas are excluded from analysis.

Score = (active_deps / total_checked) * 100.
Status thresholds: pass E<ge> 80, warn E<ge> 60, fail otherwise.

=head1 LIMITATIONS

=over 4

=item * An old module that is stable and needs no updates would also be
flagged.  The signal is I<potentially> abandoned, not definitively so.

=item * MetaCPAN is queried serially for each dependency.

=item * The date threshold is computed against the current system clock.

=back

=cut

sub id          { return 'abandoned_deps'                                           }
sub name        { return 'Abandoned Dependencies'                                   }
sub description { return 'Checks for dependencies that appear to be unmaintained'   }
sub weight      { return 5                                                          }
sub category    { return 'security'                                                 }

=head2 new

Construct an AbandonedDeps check.  Accepts all base-class parameters plus
an optional C<ignore> arrayref of module names to exclude from the check.

=cut

sub new {
	my ($class, %args) = @_;

	my @ignore = @{ delete $args{ignore} // [] };

	my $self = $class->SUPER::new(%args);

	$self->{_ignore} = { map { $_ => 1 } @ignore };

	return $self;
}

=head2 run

=head3 PURPOSE

Check each runtime dependency's latest release date and flag those that have
not had a release in the past C<ABANDONED_YEARS> years.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'abandoned_deps'>.

=head3 MESSAGES

  Code  | Severity | Message                                   | Resolution
  ------+----------+-------------------------------------------+-----------
  AD001 | SKIP     | Network checks disabled                   | Remove --no-network
  AD002 | SKIP     | No META file found                        | Add META.yml / META.json
  AD003 | SKIP     | No checkable runtime dependencies         | n/a
  AD004 | PASS     | All N dependencies are actively maintained|
  AD005 | WARN     | N of M dependencies may be abandoned      | Find alternatives
  AD006 | FAIL     | N of M dependencies may be abandoned      | Find alternatives

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  AbandonedDepsOp
  abandoned : N
  total     : N
  score     : 0..100
  -------------------------------------------------------
  no_network    => status = skip
  meta = undef  => status = skip
  total = 0     => status = skip
  score >= 80   => status = pass
  score >= 60   => status = warn
  score < 60    => status = fail

=head3 SIDE EFFECTS

Makes one HTTPS GET request to C<fastapi.metacpan.org> per dependency.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::AbandonedDeps->new->run($dist);
    printf "Abandoned: %s\n", $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	return $self->_skip('Network checks disabled (--no-network)')
		if $self->no_network;

	my $meta = $dist->meta;
	return $self->_skip('No META file found') unless $meta;

	my @checkable = _collect_checkable($meta, $self->{_ignore});
	return $self->_skip('No checkable runtime dependencies found')
		unless @checkable;

	my $now    = time;
	my $cutoff = $now - ($ABANDONED_YEARS * $SECS_PER_YEAR);
	my (@abandoned, @active);

	for my $mod (@checkable) {
		my ($is_abandoned, $detail) = _classify_dep($mod, $now, $cutoff);
		next unless defined $is_abandoned;
		if ($is_abandoned) { push @abandoned, $detail }
		else               { push @active,    $mod    }
	}

	my $total = @abandoned + @active;
	return $self->_skip('No dependency release dates available from MetaCPAN')
		unless $total;

	my $n_abandoned = scalar @abandoned;
	my $score       = int(($total - $n_abandoned) / $total * 100);
	# Any abandoned dep is worth at least a warning so details are always shown.
	my $status      = $n_abandoned == 0     ? 'pass'
	                : $score >= $SCORE_WARN ? 'warn'
	                :                         'fail';

	my $summary = $n_abandoned
		? "$n_abandoned of $total runtime dependencies may be abandoned "
		  . "(no release in $ABANDONED_YEARS+ years)"
		: ($total == 2 ? 'Both' : "All $total") . ' checked runtime dependencies are actively maintained';

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => $summary,
		details => [ map { "Potentially abandoned: $_" } sort @abandoned ],
		data    => {
			name           => $self->name,
			total          => $total,
			abandoned      => $n_abandoned,
			abandoned_mods => \@abandoned,
			active_mods    => \@active,
		},
	);
}

sub _collect_checkable {
	my ($meta, $ignore_ref) = @_;

	$ignore_ref //= {};

	my $prereqs      = $meta->effective_prereqs;
	my $runtime      = $prereqs->requirements_for('runtime', 'requires');
	my %deps         = %{ $runtime->as_string_hash };
	my $use_corelist = eval { require Module::CoreList; 1 };

	my @checkable;
	for my $mod (sort keys %deps) {
		next if $mod eq 'perl';
		next if $mod =~ / ^ [a-z] /x;    # pragmas are lowercase
		next if $ignore_ref->{$mod};
		next if $use_corelist && Module::CoreList->first_release($mod);
		push @checkable, $mod;
	}
	return @checkable;
}

sub _classify_dep {
	my ($mod, $now, $cutoff) = @_;

	my ($data, $err) = _http_get("$METACPAN_API/module/$mod");
	return if $err || !defined $data->{date};

	my $epoch = _iso8601_to_epoch($data->{date});
	return unless defined $epoch;

	my $age_years = ($now - $epoch) / $SECS_PER_YEAR;
	if ($epoch < $cutoff) {
		my $detail = sprintf '%s (last release %.1f years ago)', $mod, $age_years;
		return (1, $detail);
	}
	return (0, undef);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Parse an ISO 8601 date string to a Unix epoch (UTC).
# Handles both "2024-01-01T12:00:00" and "2024-01-01T12:00:00.000Z".
sub _iso8601_to_epoch {
	my ($str) = @_;
	return unless defined $str;
	my ($y, $mo, $d) = $str =~ / ^ (\d{4}) - (\d{2}) - (\d{2}) /x
		or return;
	require Time::Local;
	return eval {
		Time::Local::timegm(0, 0, 0, $d + 0, $mo - 1, $y - 1900)
	};
}

sub _http_get {
	my ($url) = @_;

	my $ua  = HTTP::Tiny->new(timeout => $HTTP_TIMEOUT);
	my $res = $ua->get($url, { headers => { 'Accept' => 'application/json' } });

	return (undef, "HTTP $res->{status} $res->{reason}") unless $res->{success};

	my $data = eval { JSON::MaybeXS::decode_json($res->{content}) };
	return (undef, "JSON parse error: $@") if $@;

	return ($data, undef);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
