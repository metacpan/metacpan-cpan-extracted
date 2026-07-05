package Test::CPAN::Health::Check;

use strict;
use warnings;
use autodie qw(:all);

# Sub::Protected enforces that _result/_skip/_error may only be called from
# within Test::CPAN::Health::Check or its subclasses -- not from the outside.
use Sub::Protected;

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);

our $VERSION = '0.1.0';

# Valid categories for grouping checks in the report.
Readonly::Array my @VALID_CATEGORIES => qw(packaging quality security ci);
Readonly::Hash  my %CATEGORY_SET     => map { $_ => 1 } @VALID_CATEGORIES;

=head1 NAME

Test::CPAN::Health::Check - Abstract base class for all health checks

=head1 SYNOPSIS

    package Test::CPAN::Health::Check::MyCheck;

    use parent 'Test::CPAN::Health::Check';

    sub id          { return 'my_check'                }
    sub name        { return 'My Check'                }
    sub description { return 'Checks something useful' }
    sub weight      { return 4                         }
    sub category    { return 'quality'                 }

    sub run {
        my ($self, $dist) = @_;

        # ... perform analysis on $dist ...

        return $self->_result(
            status  => 'pass',
            score   => 100,
            summary => 'Everything looks good',
        );
    }

    1;

=head1 DESCRIPTION

Every health check in C<Test::CPAN::Health> is a subclass of this base class.
Subclasses B<must> override C<id>, C<name>, and C<run>.  Overriding
C<description>, C<weight>, and C<category> is recommended.

The base class provides three B<protected> helpers (callable only from
subclasses): C<_result>, C<_skip>, and C<_error>.  These wrap
L<Test::CPAN::Health::Result> construction so subclasses never need to
C<use> Result directly.  Access is enforced at runtime by L<Sub::Protected>;
calling them from outside the class hierarchy throws an exception.

=head1 LIMITATIONS

=over 4

=item * This is not a Moo/Moose role -- inheritance is via C<use parent>.

=item * The C<run> method receives a fully-constructed
L<Test::CPAN::Health::Distribution> object; checks that need network access
should honour C<no_network>.

=item * C<_result>, C<_skip>, and C<_error> are protected (subclass-only)
via L<Sub::Protected>.  White-box test packages that inherit from this class
may call them freely; non-inheriting test code cannot.

=item * L<Sub::Protected> uses a CHECK block to install access control.
When this module is first loaded at runtime (e.g. via C<use_ok> in a test
harness rather than at compile-time via C<use parent>), Perl emits a
"Too late to run CHECK block" warning.  The runtime protection still
operates correctly despite this warning; it is cosmetic only.

=back

=cut

=head2 new

=head3 PURPOSE

Construct a check instance.  Subclasses do not normally need to override
C<new>; all check-level configuration (severity, network flag, cover flag)
is managed here.

=head3 API SPECIFICATION

=head4 INPUT

  severity    integer  1..5   optional  default 3
  no_network  scalar   bool   optional  default 0
  no_cover    scalar   bool   optional  default 0

=head4 OUTPUT

Blessed hashref of the concrete subclass.

=head3 MESSAGES

  Code  | Severity | Message                               | Resolution
  ------+----------+---------------------------------------+----------------------------
  CHK00 | FATAL    | Unknown parameter '<key>'             | Remove unrecognised argument
  CHK00 | FATAL    | severity must be integer 1..5         | Pass integer in range

=head3 FORMAL SPECIFICATION

  Pre:  class isa Test::CPAN::Health::Check
        0 < severity <= 5   (if supplied)
  Post: self._severity   = severity // 3
        self._no_network = no_network // 0
        self._no_cover   = no_cover // 0

=head3 USAGE EXAMPLE

    my $check = Test::CPAN::Health::Check::SemVer->new(no_network => 1);

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			severity   => { type => 'integer', min => 1, max => 5, optional => 1, default => 3 },
			no_network => { type => 'scalar',  optional => 1, default => 0 },
			no_cover   => { type => 'scalar',  optional => 1, default => 0 },
		},
		input => \%args,
	) };

	my $self = bless {
		_severity   => $args{severity},
		_no_network => $args{no_network},
		_no_cover   => $args{no_cover},
	}, $class;

	return $self;
}

=head2 id

=head3 PURPOSE

Returns a stable, lowercase_underscore string that uniquely identifies
this check.  Used as the hash key in Report results and in C<--skip>/C<--check>
CLI flags.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Non-empty scalar string; lowercase alphanumeric and underscores only.

=head3 MESSAGES

  Code  | Severity | Message                                   | Resolution
  ------+----------+-------------------------------------------+----------------------
  CHK01 | FATAL    | <Class> must implement id()               | Override id() in subclass

=head3 FORMAL SPECIFICATION

  Pre:  self isa concrete subclass that overrides id()
  Post: result /= ""
        result =~ /^[a-z][a-z0-9_]*$/

=head3 USAGE EXAMPLE

    print $check->id;    # 'sem_ver'

=cut

sub id { my ($self) = @_; croak ref($self) . ' must implement id()' }

=head2 name

=head3 PURPOSE

Returns a short human-readable display name for use in report headers and
terminal output.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Non-empty scalar string.

=head3 MESSAGES

  Code  | Severity | Message                                   | Resolution
  ------+----------+-------------------------------------------+----------------------
  CHK02 | FATAL    | <Class> must implement name()             | Override name() in subclass

=head3 FORMAL SPECIFICATION

  Pre:  self isa concrete subclass that overrides name()
  Post: result /= ""

=head3 USAGE EXAMPLE

    print $check->name;    # 'Semantic Versioning'

=cut

sub name { my ($self) = @_; croak ref($self) . ' must implement name()' }

=head2 description

=head3 PURPOSE

Returns a one-sentence description of what the check measures.
The default implementation returns an empty string; subclasses are
encouraged to override this for tooling that exposes check metadata.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Scalar string.  Empty string is acceptable but discouraged.

=head3 MESSAGES

  (none -- default returns empty string; no exception path)

=head3 FORMAL SPECIFICATION

  Post: is_string(result)   -- empty string is valid

=head3 USAGE EXAMPLE

    print $check->description;

=cut

sub description { return '' }

=head2 weight

=head3 PURPOSE

Returns the numeric weight applied to this check's score in the weighted
average that produces the overall Report score.  Higher weights make a
check more influential.  The default is 1.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Positive integer or float.

=head3 MESSAGES

  (none -- default returns 1; no exception path)

=head3 FORMAL SPECIFICATION

  Post: result > 0

=head3 USAGE EXAMPLE

    print $check->weight;    # 8

=cut

sub weight { return 1 }

=head2 category

=head3 PURPOSE

Returns the category string used to group checks in the report.
Must be one of: C<packaging>, C<quality>, C<security>, C<ci>.
The default is C<'quality'>.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

One of: packaging, quality, security, ci.

=head3 MESSAGES

  (none -- default returns 'quality'; subclass overrides must use a valid value)

=head3 FORMAL SPECIFICATION

  Post: result IN {packaging, quality, security, ci}

=head3 USAGE EXAMPLE

    print $check->category;    # 'quality'

=cut

sub category { return 'quality' }

=head2 run

=head3 PURPOSE

Executes the check against a distribution and returns a Result.  Returns
C<undef> when the check is not applicable (e.g. CPANTesters for a dist
that has never been released to CPAN).

B<Subclasses must override this method.>  The base-class implementation
always croaks.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref of check_id => Result     optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> object, or C<undef> if not applicable.

=head3 MESSAGES

  Code  | Severity | Message                                    | Resolution
  ------+----------+--------------------------------------------+---------------------
  CHK03 | FATAL    | <Class> must implement run()               | Override run() in subclass

=head3 FORMAL SPECIFICATION

  Pre:  dist isa Test::CPAN::Health::Distribution
        context is hashref (may be empty)
  Post: result = undef
        OR (result isa Result AND result.check_id = self.id)

=head3 SIDE EFFECTS

May perform network I/O, filesystem reads, and subprocess invocations
depending on the concrete check.  Honours C<no_network> and C<no_cover>
flags to suppress optional side effects.

=head3 USAGE EXAMPLE

    my $result = $check->run($dist, \%context);
    print $result->summary if defined $result;

=cut

sub run { my ($self) = @_; croak ref($self) . ' must implement run()' }

# ---------------------------------------------------------------------------
# Protected helpers -- callable from this class and all subclasses only.
# Sub::Protected enforces this at runtime; any call from outside the
# inheritance chain throws "Can't locate object method".
# ---------------------------------------------------------------------------

# Purpose:    Build a Result object stamped with this check's id.
#             Convenience so subclasses don't need to 'use' Result directly.
# Entry:      %args are passed verbatim to Result->new (with check_id prepended).
# Exit:       Returns a Test::CPAN::Health::Result.
# Side effects: Requires Test::CPAN::Health::Result lazily.
## no critic (ProhibitUnusedPrivateSubroutines)
sub _result : Protected {
	my ($self, %args) = @_;

	require Test::CPAN::Health::Result;

	return Test::CPAN::Health::Result->new(
		check_id => $self->id,
		%args,
	);
}

# Purpose:    Return a skip Result conveying why the check was not applicable.
# Entry:      $reason is a human-readable explanation.
# Exit:       Test::CPAN::Health::Result with status='skip'.
# Side effects: None beyond _result.
## no critic (ProhibitUnusedPrivateSubroutines)
sub _skip : Protected {
	my ($self, $reason) = @_;

	return $self->_result(
		status  => 'skip',
		summary => $reason // 'Not applicable',
		data    => { name => $self->name },
	);
}

# Purpose:    Return an error Result when the check itself malfunctions.
#             (Distinct from a 'fail' result, which means the dist is defective.)
# Entry:      $message describes the check's internal failure.
# Exit:       Test::CPAN::Health::Result with status='error'.
# Side effects: None beyond _result.
## no critic (ProhibitUnusedPrivateSubroutines)
sub _error : Protected {
	my ($self, $message) = @_;

	return $self->_result(
		status  => 'error',
		summary => $message // 'Unknown error',
		data    => { name => $self->name },
	);
}

# ---------------------------------------------------------------------------
# Public read-only accessors
# ---------------------------------------------------------------------------

sub severity   { my ($self) = @_; return $self->{_severity}   }
sub no_network { my ($self) = @_; return $self->{_no_network} }
sub no_cover   { my ($self) = @_; return $self->{_no_cover}   }

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
