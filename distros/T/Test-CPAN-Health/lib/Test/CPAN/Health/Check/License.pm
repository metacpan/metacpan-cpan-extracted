package Test::CPAN::Health::Check::License;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# License identifiers that are technically valid per CPAN::Meta::Spec but are
# too vague to be meaningful -- they give downstream consumers no actionable
# information about how the software may be used.
Readonly::Array my @VAGUE_LICENSES => qw(unknown open_source restricted unrestricted);
Readonly::Hash  my %VAGUE_LICENSE_SET => map { $_ => 1 } @VAGUE_LICENSES;

# File names to check for a licence text, in preference order.
Readonly::Array my @LICENSE_FILES => qw(
	LICENSE
	LICENCE
	LICENSE.txt
	LICENCE.txt
	LICENSE.md
	LICENCE.md
	COPYING
);

=head1 NAME

Test::CPAN::Health::Check::License - Check that a valid licence is declared and a licence file is present

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::License;

    my $check  = Test::CPAN::Health::Check::License->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Verifies two things:

=over 4

=item 1.

The distribution declares a specific, non-vague licence in META (i.e. not
C<unknown>, C<open_source>, C<restricted>, or C<unrestricted>).

=item 2.

A corresponding licence text file exists in the distribution root
(LICENSE, LICENCE, LICENSE.txt, LICENCE.txt, LICENSE.md, LICENCE.md,
or COPYING).

=back

Score matrix:

=over 4

=item * 100 -- Specific licence declared and licence file present.

=item *  50 -- Specific licence declared but no licence file found.

=item *   0 -- No licence declared, or licence is vague/unknown.

=item * skip -- No META file found.

=back

=head1 LIMITATIONS

=over 4

=item * This check does not verify that the licence text in the file matches
the identifier in META.

=item * Licence identifiers are compared case-sensitively against the CPAN::Meta
spec identifiers (lowercase, underscore-separated).

=back

=cut

sub id          { return 'license'                                                    }
sub name        { return 'License'                                                    }
sub description { return 'Checks that a valid licence is declared and a file present' }
sub weight      { return 4                                                            }
sub category    { return 'packaging'                                                  }

=head2 run

=head3 PURPOSE

Inspect the distribution's META licence declaration and confirm a licence text
file is present in the distribution root.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional  prior check results

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'license'>.

=head3 MESSAGES

  Code  | Severity | Message                                     | Resolution
  ------+----------+---------------------------------------------+-----------
  LI001 | SKIP     | No META file -- cannot determine licence    | Add META file
  LI002 | FAIL     | No licence declared in META                 | Add license field
  LI003 | FAIL     | Licence declared as "{id}" -- too vague     | Use specific identifier
  LI004 | WARN     | Licence declared but no licence file found  | Add LICENSE file
  LI005 | PASS     | Licence declared and licence file present   |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  LicenseOp
  dist         : Distribution
  licenses     : seq String
  license_file : String | undefined
  -------------------------------------------------------
  meta = undefined       => status = skip
  #licenses = 0          => status = fail /\ score = 0
  exists vague(licenses) => status = fail /\ score = 0
  license_file = undef   => status = warn /\ score = 50
  license_file /= undef  => status = pass /\ score = 100

=head3 SIDE EFFECTS

None.  Uses the already-parsed META object and filesystem stat calls only.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::License->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my $meta = $dist->meta;

	unless ($meta) {
		return $self->_skip('No META file found -- cannot determine licence');
	}

	my @licenses = $meta->license;

	unless (@licenses) {
		return $self->_result(
			status  => 'fail',
			score   => 0,
			summary => 'No licence declared in META',
			details => [
				'Add a "license" field to META.json',
				'Common CPAN values: perl_5, artistic_2, mit, gpl_2, lgpl_3_0',
			],
			data => { name => $self->name },
		);
	}

	my @vague = grep { $VAGUE_LICENSE_SET{$_} } @licenses;
	if (@vague) {
		return $self->_result(
			status  => 'fail',
			score   => 0,
			summary => sprintf(
				'Licence declared as "%s" which is too vague for downstream consumers',
				join(', ', @vague),
			),
			details => [
				'Replace with a specific SPDX-compatible identifier',
				'Common CPAN values: perl_5, artistic_2, mit, gpl_2, lgpl_3_0',
			],
			data => { name => $self->name, licenses => \@licenses },
		);
	}

	my $license_file;
	for my $filename (@LICENSE_FILES) {
		if (defined $dist->file_path($filename)) {
			$license_file = $filename;
			last;
		}
	}

	unless ($license_file) {
		return $self->_result(
			status  => 'warn',
			score   => 50,
			summary => sprintf(
				'Licence "%s" declared in META but no licence file found in distribution root',
				join(', ', @licenses),
			),
			details => ['Add a LICENSE or LICENCE file to the distribution root'],
			data    => { name => $self->name, licenses => \@licenses },
		);
	}

	return $self->_result(
		status  => 'pass',
		score   => 100,
		summary => sprintf(
			'Licence "%s" declared in META and %s file present',
			join(', ', @licenses), $license_file,
		),
		data => {
			name     => $self->name,
			licenses => \@licenses,
			file     => $license_file,
		},
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
