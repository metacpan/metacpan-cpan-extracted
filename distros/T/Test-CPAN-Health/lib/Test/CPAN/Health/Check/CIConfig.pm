package Test::CPAN::Health::Check::CIConfig;

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

# YAML-based CI config files that live at the distribution root.
Readonly::Array my @ROOT_YAML_CONFIGS => qw(
	.travis.yml
	.appveyor.yml
	azure-pipelines.yml
);

# Non-YAML CI config files (syntax checking not applicable).
Readonly::Array my @ROOT_OTHER_CONFIGS => qw(
	Jenkinsfile
);

=head1 NAME

Test::CPAN::Health::Check::CIConfig - Check that a CI configuration is present and valid

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::CIConfig;

    my $check  = Test::CPAN::Health::Check::CIConfig->new;
    my $result = $check->run($dist);

=head1 DESCRIPTION

Checks for the presence of a recognised CI configuration file and, where the
format is YAML, validates that the file parses without errors.

Recognised CI systems:

=over 4

=item * GitHub Actions -- C<.github/workflows/*.yml>

=item * Travis CI -- C<.travis.yml>

=item * AppVeyor -- C<.appveyor.yml>

=item * Azure Pipelines -- C<azure-pipelines.yml>

=item * CircleCI -- C<.circleci/config.yml>

=item * Jenkins -- C<Jenkinsfile>

=back

Score matrix:

=over 4

=item * 100 -- at least one valid CI config found.

=item *  70 -- CI config file(s) found but all YAML files failed to parse.

=item *   0 -- no CI configuration found.

=back

=cut

sub id          { return 'ci_config'                                            }
sub name        { return 'CI Configuration'                                     }
sub description { return 'Checks that a valid CI configuration file is present' }
sub weight      { return 4                                                      }
sub category    { return 'ci'                                                   }

=head2 run

=head3 PURPOSE

Scan the distribution root for known CI configuration files and validate
YAML ones for parse errors.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional  (unused)

=head4 OUTPUT

L<Test::CPAN::Health::Result> with:

  check_id  'ci_config'
  status    'pass' | 'warn' | 'fail'
  score     100 | 70 | 0
  summary   human-readable verdict
  details   list of file names found or error descriptions

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  CI001 | FAIL     | No CI configuration found          | Add .github/workflows/ or .travis.yml
  CI002 | WARN     | CI config found but YAML invalid   | Fix YAML syntax errors
  CI003 | PASS     | CI configuration found             |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  CIConfigOp
  dist   : Distribution
  files  : seq String
  valid  : seq String
  score  : {0, 70, 100}
  -------------------------------------------------------
  #files = 0  => score = 0
  #valid > 0  => score = 100
  #files > 0 /\ #valid = 0 => score = 70

=head3 SIDE EFFECTS

Reads CI configuration files from disk.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::CIConfig->new->run($dist);

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my (@yaml_files, @other_files);

	# GitHub Actions: .github/workflows/*.yml or *.yaml
	my $workflows_dir = File::Spec->catdir($dist->path, '.github', 'workflows');
	if (-d $workflows_dir) {
		push @yaml_files,
			File::Find::Rule->file->name('*.yml', '*.yaml')->in($workflows_dir);
	}

	# CircleCI
	my $circle = File::Spec->catfile($dist->path, '.circleci', 'config.yml');
	push @yaml_files, $circle if -f $circle;

	# Root-level YAML configs
	for my $name (@ROOT_YAML_CONFIGS) {
		my $f = File::Spec->catfile($dist->path, $name);
		push @yaml_files, $f if -f $f;
	}

	# Non-YAML configs
	for my $name (@ROOT_OTHER_CONFIGS) {
		my $f = File::Spec->catfile($dist->path, $name);
		push @other_files, $f if -f $f;
	}

	unless (@yaml_files || @other_files) {
		return $self->_result(
			status  => 'fail',
			score   => 0,
			summary => 'No CI configuration file found',
			details => [
				'Add .github/workflows/*.yml for GitHub Actions,',
				'or .travis.yml, .appveyor.yml, .circleci/config.yml, etc.',
			],
			data => { name => $self->name },
		);
	}

	# Validate YAML files; non-YAML files (Jenkinsfile) are always accepted.
	my (@valid_labels, @invalid_labels);

	for my $f (@yaml_files) {
		my $label = File::Spec->abs2rel($f, $dist->path);
		my $ok = _yaml_valid($f);
		if ($ok) {
			push @valid_labels, $label;
		} else {
			push @invalid_labels, $label;
		}
	}

	for my $f (@other_files) {
		push @valid_labels, File::Spec->abs2rel($f, $dist->path);
	}

	if (@valid_labels) {
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => sprintf('CI configuration found: %s', join(', ', @valid_labels)),
			data    => { name => $self->name, files => \@valid_labels },
		);
	}

	# Files found but all YAML failed to parse.
	return $self->_result(
		status  => 'warn',
		score   => 70,
		summary => sprintf(
			'%d CI config file(s) found but contain invalid YAML',
			scalar @invalid_labels,
		),
		details => [ map { "Invalid YAML: $_" } @invalid_labels ],
		data    => { name => $self->name, files => \@invalid_labels },
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _yaml_valid {
	my ($file) = @_;

	# CPAN::Meta::YAML is a transitive dep via CPAN::Meta (in core since 5.14).
	# If unavailable, give benefit of the doubt and call the file valid.
	my $loaded = eval { require CPAN::Meta::YAML; 1 };
	return 1 unless $loaded;

	my $ok = eval { CPAN::Meta::YAML->read($file); 1 };
	return $ok ? 1 : 0;
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
