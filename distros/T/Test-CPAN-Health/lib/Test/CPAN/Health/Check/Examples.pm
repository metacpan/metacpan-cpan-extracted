package Test::CPAN::Health::Check::Examples;

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

# Conventional directory names for distribution example scripts.
Readonly::Array my @EXAMPLE_DIRS => qw(examples eg example);

=head1 NAME

Test::CPAN::Health::Check::Examples - Check that example scripts are present

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::Examples;

    my $check  = Test::CPAN::Health::Check::Examples->new;
    my $result = $check->run($dist);

=head1 DESCRIPTION

Checks for the presence of an C<examples/>, C<eg/>, or C<example/> directory
containing at least one file.

Score matrix:

=over 4

=item * 100 -- examples directory found with at least one file.

=item *  50 -- examples directory found but empty.

=item *   0 -- no examples directory found.

=back

=cut

sub id          { return 'examples'                                                    }
sub name        { return 'Examples'                                                    }
sub description { return 'Checks that example scripts are present in the distribution' }
sub weight      { return 2                                                             }
sub category    { return 'quality'                                                     }

=head2 run

=head3 PURPOSE

Locate an examples directory and report whether it contains files.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional  (unused)

=head4 OUTPUT

L<Test::CPAN::Health::Result> with:

  check_id  'examples'
  status    'pass' | 'warn' | 'fail'
  score     100 | 50 | 0
  summary   human-readable verdict

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  EX001 | FAIL     | No examples directory found        | Add an examples/ or eg/ directory
  EX002 | WARN     | Examples directory is empty        | Add at least one script to examples/
  EX003 | PASS     | Examples directory found           |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  ExamplesOp
  dist  : Distribution
  score : {0, 50, 100}
  -------------------------------------------------------
  no_dir      => score = 0
  dir_empty   => score = 50
  dir_nonempty => score = 100

=head3 SIDE EFFECTS

Reads directory listings from disk.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::Examples->new->run($dist);

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	for my $dir_name (@EXAMPLE_DIRS) {
		next unless $dist->has_dir($dir_name);

		my $dir_path = File::Spec->catdir($dist->path, $dir_name);
		my @files    = File::Find::Rule->file->in($dir_path);

		if (@files) {
			return $self->_result(
				status  => 'pass',
				score   => 100,
				summary => sprintf(
					'Examples directory found: %s/ (%d file(s))',
					$dir_name, scalar @files,
				),
				data => { name => $self->name, dir => $dir_name, count => scalar @files },
			);
		}

		return $self->_result(
			status  => 'warn',
			score   => 50,
			summary => sprintf('Examples directory %s/ exists but is empty', $dir_name),
			details => ['Add at least one example script to the directory'],
			data    => { name => $self->name, dir => $dir_name, count => 0 },
		);
	}

	return $self->_result(
		status  => 'fail',
		score   => 0,
		summary => 'No examples directory found (examples/, eg/, or example/)',
		details => [
			'Create an examples/ or eg/ directory containing short, runnable Perl scripts that demonstrate typical use cases',
			'Each script should be self-contained: load the module, perform one clear task, and print output so users can run it directly with "perl examples/basic_usage.pl"',
			'Good examples cover the most common use cases and lower the barrier for new users getting started',
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
