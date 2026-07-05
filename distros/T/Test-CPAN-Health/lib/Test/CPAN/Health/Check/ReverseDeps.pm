package Test::CPAN::Health::Check::ReverseDeps;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use HTTP::Tiny ();       # load at compile time so mock_scoped works in tests
use JSON::MaybeXS ();   # same reason -- lazy require inside _http_get is overwritten
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

Readonly::Scalar my $METACPAN_API  => 'https://fastapi.metacpan.org/v1';
Readonly::Scalar my $HTTP_TIMEOUT  => 30;

# Score brackets based on reverse-dependency count.
# Having zero revdeps is unusual but not a defect; score is warn, not fail.
Readonly::Scalar my $SCORE_NONE  => 50;   # 0 reverse deps
Readonly::Scalar my $SCORE_FEW   => 75;   # 1-9
Readonly::Scalar my $SCORE_SOME  => 90;   # 10-99
Readonly::Scalar my $SCORE_MANY  => 100;  # 100+

Readonly::Scalar my $THRESH_FEW  => 1;
Readonly::Scalar my $THRESH_SOME => 10;
Readonly::Scalar my $THRESH_MANY => 100;

=head1 NAME

Test::CPAN::Health::Check::ReverseDeps - Count how many CPAN distributions depend on this one

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::ReverseDeps;

    my $check  = Test::CPAN::Health::Check::ReverseDeps->new;
    my $result = $check->run($dist);

=head1 DESCRIPTION

Queries the MetaCPAN API to count how many other CPAN distributions declare a
dependency on this distribution.  A higher reverse-dependency count is a
positive quality signal: widely-depended-upon code tends to be well-maintained.

The count is stored in C<data-E<gt>{count}> and is read from the runner context
by the C<SecurityAdvisories> check to scale the urgency of its messages.

Score brackets: 0 E<rarr> 50 (warn), 1-9 E<rarr> 75 (pass), 10-99 E<rarr> 90
(pass), 100+ E<rarr> 100 (pass).

=head1 LIMITATIONS

=over 4

=item * Results are accurate only for distributions that have been indexed on
MetaCPAN.  A purely local path will usually still match by dist name from the
META file.

=item * The count reflects CPAN metadata at query time and is cached for 24 h
by the Runner's C<Test::CPAN::Health::Cache>.

=back

=cut

sub id          { return 'reverse_deps'                                                    }
sub name        { return 'Reverse Dependencies'                                            }
sub description { return 'Reports how many CPAN distributions depend on this one'         }
sub weight      { return 2                                                                 }
sub category    { return 'quality'                                                         }

=head2 run

=head3 PURPOSE

Query MetaCPAN for the distribution's reverse-dependency count and return a
scored result.  The count is stored in C<data-E<gt>{count}>.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'reverse_deps'>.

=head3 MESSAGES

  Code  | Severity | Message                               | Resolution
  ------+----------+---------------------------------------+-----------
  RD001 | SKIP     | Network checks disabled               | Remove --no-network
  RD002 | SKIP     | Distribution name not available       | Add META.yml with name field
  RD003 | ERROR    | MetaCPAN API error: ...               | Transient; retry
  RD004 | WARN     | 0 reverse dependencies found          | Publish / promote the dist
  RD005 | PASS     | N reverse dependencies found          |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  ReverseDepsOp
  count  : N
  score  : {50, 75, 90, 100}
  -------------------------------------------------------
  count = 0          => score = 50  /\ status = warn
  1 <= count < 10    => score = 75  /\ status = pass
  10 <= count < 100  => score = 90  /\ status = pass
  count >= 100       => score = 100 /\ status = pass

=head3 SIDE EFFECTS

Makes one HTTPS GET request to C<fastapi.metacpan.org>.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::ReverseDeps->new->run($dist);
    printf "Reverse deps: %d\n", $result->data->{count};

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	return $self->_skip('Network checks disabled (--no-network)')
		if $self->no_network;

	my $dist_name = $dist->name;
	return $self->_skip('Distribution name not available')
		unless defined $dist_name && length $dist_name;

	# MetaCPAN uses dash-separated dist names, not double-colon
	(my $dist_slug = $dist_name) =~ s/ :: /-/gx;

	my ($data, $err) = _http_get(
		"$METACPAN_API/reverse_dependencies/dist/$dist_slug?size=0",
	);
	return $self->_error("MetaCPAN API error: $err") if $err;

	# MetaCPAN may return:
	#   {total: N}                      -- legacy top-level form
	#   {hits: {total: {value: N}}}     -- Elasticsearch 7+ wrapped form
	#   {hits: {total: N}}              -- Elasticsearch 6 plain integer form
	# Guard the {value} deref so a plain integer does not crash under strict.
	my $hits_total = $data->{hits}{total};
	my $count = $data->{total}
	         // ( ref($hits_total) eq 'HASH' ? $hits_total->{value} : $hits_total )
	         // 0;

	my ($score, $status);
	if ($count >= $THRESH_MANY) {
		($score, $status) = ($SCORE_MANY, 'pass');
	} elsif ($count >= $THRESH_SOME) {
		($score, $status) = ($SCORE_SOME, 'pass');
	} elsif ($count >= $THRESH_FEW) {
		($score, $status) = ($SCORE_FEW, 'pass');
	} else {
		($score, $status) = ($SCORE_NONE, 'warn');
	}

	my $noun = $count == 1 ? 'reverse dependency' : 'reverse dependencies';

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => "$count $noun found on CPAN",
		data    => {
			name  => $self->name,
			count => $count,
		},
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _http_get {
	my ($url) = @_;

	# HTTP::Tiny and JSON::MaybeXS are loaded at compile time (use at top of
	# file) so that test mocks installed via mock_scoped are not overwritten
	# when a lazy require fires inside this helper on first invocation.
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

Copyright (C) 2025-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
