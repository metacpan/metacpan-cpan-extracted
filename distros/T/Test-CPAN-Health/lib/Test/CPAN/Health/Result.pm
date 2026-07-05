package Test::CPAN::Health::Result;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use Readonly;
use Params::Validate::Strict qw(validate_strict);

our $VERSION = '0.1.0';

Readonly::Array my @VALID_STATUSES => qw(pass warn fail skip error);
Readonly::Hash  my %STATUS_SET     => map { $_ => 1 } @VALID_STATUSES;

=head1 NAME

Test::CPAN::Health::Result - Outcome of a single health check

=head1 SYNOPSIS

    use Test::CPAN::Health::Result;

    my $result = Test::CPAN::Health::Result->new(
        check_id => 'sem_ver',
        status   => 'pass',
        score    => 100,
        summary  => 'Version 1.2.3 follows semantic versioning',
    );

    print $result->status;           # 'pass'
    print $result->score;            # 100
    print $result->is_pass ? 'ok' : 'not ok';

=head1 DESCRIPTION

Encapsulates the outcome of one L<Test::CPAN::Health::Check> run.  Each
Result carries a status (pass/warn/fail/skip/error), an optional 0-100
score used in the weighted overall calculation, a human-readable summary,
an optional list of detail strings, an optional URL pointing to external
evidence, and an optional raw data hashref for machine-readable reporters.

=head1 LIMITATIONS

=over 4

=item * C<score> is not validated to the range 0..100 at construction time;
enforcement is the caller's responsibility.

=back

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			check_id => { type => 'string',  min => 1              },
			status   => { type => 'string',  min => 1              },
			score    => { type => 'integer', min => 0, max => 100, optional => 1 },
			summary  => { type => 'string',  optional => 1         },
			details  => { type => 'arrayref', optional => 1        },
			url      => { type => 'string',  optional => 1         },
			data     => { type => 'hashref', optional => 1         },
		},
		input => \%args,
	) };

	croak "Invalid status '$args{status}'; expected one of: " . join(', ', @VALID_STATUSES)
		unless $STATUS_SET{ $args{status} };

	my $self = bless {
		_check_id => $args{check_id},
		_status   => $args{status},
		_score    => $args{score},
		_summary  => $args{summary} // '',
		_details  => $args{details} // [],
		_url      => $args{url},
		_data     => $args{data} // {},
	}, $class;

	return $self;
}

=head2 check_id

=head3 PURPOSE

Returns the stable string identifier of the check that produced this result.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Scalar string.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
        |          |                                    |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  check_id : String
  -------------------------------------------------------
  check_id /= ""

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    print $result->check_id;    # 'sem_ver'

=cut

sub check_id { my ($self) = @_; return $self->{_check_id} }

=head2 status

=head3 PURPOSE

Returns the pass/warn/fail/skip/error status string.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

One of: C<pass>, C<warn>, C<fail>, C<skip>, C<error>.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
        |          |                                    |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  status : {pass, warn, fail, skip, error}

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    print $result->status;    # 'fail'

=cut

sub status  { my ($self) = @_; return $self->{_status}  }
sub score   { my ($self) = @_; return $self->{_score}   }
sub summary { my ($self) = @_; return $self->{_summary} }
sub details { my ($self) = @_; return $self->{_details} }
sub url     { my ($self) = @_; return $self->{_url}     }
sub data    { my ($self) = @_; return $self->{_data}    }

# Convenience predicates -- avoids scattered string comparisons in reporters

sub is_pass  { my ($self) = @_; return $self->{_status} eq 'pass'  }
sub is_warn  { my ($self) = @_; return $self->{_status} eq 'warn'  }
sub is_fail  { my ($self) = @_; return $self->{_status} eq 'fail'  }
sub is_skip  { my ($self) = @_; return $self->{_status} eq 'skip'  }
sub is_error { my ($self) = @_; return $self->{_status} eq 'error' }

=head2 as_hash

=head3 PURPOSE

Serialise the Result to a plain hashref, suitable for JSON encoding or
passing between processes.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Hashref with keys: check_id, status, score, summary, details, url, data.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
        |          |                                    |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  AsHashOp
  result  : Result
  output  : Hashref
  -------------------------------------------------------
  dom(output) = {check_id, status, score, summary, details, url, data}

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    my $href = $result->as_hash;
    my $json = encode_json($href);

=cut

sub as_hash {
	my ($self) = @_;

	return {
		check_id => $self->{_check_id},
		status   => $self->{_status},
		score    => $self->{_score},
		summary  => $self->{_summary},
		details  => [ @{$self->{_details}} ],
		url      => $self->{_url},
		data     => { %{$self->{_data}} },
	};
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
