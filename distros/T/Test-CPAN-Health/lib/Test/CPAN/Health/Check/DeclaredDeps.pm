package Test::CPAN::Health::Check::DeclaredDeps;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

Readonly::Scalar my $SCORE_WARN => 80;

# Perl pragma modules that are always part of the interpreter and need not be
# declared as dependencies.  All-lowercase names (strict, warnings, autodie,
# utf8 ...) are caught by the /^[a-z]/ guard; this list handles mixed-case
# pragma-like modules that are always available.
Readonly::Array my @ALWAYS_AVAILABLE => qw(
	POSIX Carp Config Cwd Exporter Fcntl Storable Symbol
	Data::Dumper Scalar::Util List::Util
	File::Basename File::Copy File::Path File::Spec File::Temp
	IO::File IO::Handle
	Module::CoreList Time::HiRes Time::Local
	MIME::Base64 Encode Encode::Detect
);
Readonly::Hash my %ALWAYS_AVAILABLE_SET => map { $_ => 1 } @ALWAYS_AVAILABLE;

=head1 NAME

Test::CPAN::Health::Check::DeclaredDeps - Verify all runtime module dependencies are declared in META

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::DeclaredDeps;

    my $check  = Test::CPAN::Health::Check::DeclaredDeps->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Scans all C<.pm> and script files in the distribution for C<use MODULE>
and C<require MODULE> statements, then cross-references the extracted
module names against the runtime prerequisites declared in the distribution's
META (or MYMETA) file.

A module is B<not> flagged as undeclared when it is:

=over 4

=item * An all-lowercase Perl pragma (C<strict>, C<warnings>, C<autodie>,
C<utf8>, C<feature>, C<constant>, etc.).

=item * An internal module within this distribution (same namespace prefix).

=item * A version string (C<require 5.014>) -- starts with a digit.

=item * A module known to be in Perl core for the declared minimum Perl
version, detected via L<Module::CoreList> when available.

=item * A member of the hardcoded C<@ALWAYS_AVAILABLE> list for cases where
L<Module::CoreList> is unavailable.

=back

Score = 100 * (used_and_declared / total_used).
Status: C<pass> when all dependencies are declared; C<warn> when score E<ge>
80; C<fail> otherwise.

=head1 LIMITATIONS

=over 4

=item * Requires a META or MYMETA file to provide the declared prerequisite
list.  If no META exists the check is skipped.

=item * Dynamic C<require> expressions (e.g. C<require $class>) are not
detected -- only static string forms.

=item * POD code examples that contain C<use MODULE> are excluded via a
simple line-by-line POD state machine.

=back

=cut

sub id          { return 'declared_deps'                                                            }
sub name        { return 'Declared Dependencies'                                                    }
sub description { return 'Checks that all runtime module uses are declared in META prerequisites'   }
sub weight      { return 5                                                                          }
sub category    { return 'packaging'                                                                }

=head2 run

=head3 PURPOSE

Scan source files for C<use>/C<require> module statements and compare against
the runtime prerequisites declared in META.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'declared_deps'>.

=head3 MESSAGES

  Code  | Severity | Message                                      | Resolution
  ------+----------+----------------------------------------------+-----------
  DD001 | SKIP     | No META file found                           | Run perl Makefile.PL first
  DD002 | SKIP     | No source files to scan                      | Add .pm files under lib/
  DD003 | PASS     | All N runtime dependencies are declared      |
  DD004 | WARN     | N undeclared runtime dependencies found      | Add to PREREQ_PM / cpanfile
  DD005 | FAIL     | N undeclared runtime dependencies found      | Add to PREREQ_PM / cpanfile

=head3 FORMAL SPECIFICATION

  Pre:  dist isa Test::CPAN::Health::Distribution
        META or MYMETA file present (else skip)
  Post: n_bad = 0         => status = pass  /\ score = 100
        n_bad > 0
          /\ score >= 80  => status = warn
          /\ score < 80   => status = fail

=head3 SIDE EFFECTS

Reads source files from disk.  No network I/O.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::DeclaredDeps->new->run($dist);
    if ($result->status ne 'pass') {
        print "Undeclared: ", join(', ', @{ $result->details }), "\n";
    }

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my $meta = $dist->meta;
	return $self->_skip('No META or MYMETA file found -- run perl Makefile.PL first')
		unless $meta;

	my %declared  = _collect_declared($meta);
	my @files     = (@{ $dist->pm_files }, @{ $dist->pl_files });
	return $self->_skip('No source files to scan') unless @files;

	# Determine the distribution's own top-level namespace so self-referential
	# internal uses (e.g. the dist using its own sub-modules) are not flagged.
	my $dist_ns = do {
		my $n = $dist->name // '';
		$n =~ s/-/::/gx;
		$n;
	};

	my $use_corelist = eval { require Module::CoreList; 1 };

	my %used;
	for my $file (@files) {
		my %file_used = _scan_file($file, $dist_ns, $use_corelist);
		$used{$_}++ for keys %file_used;
	}

	return $self->_result(
		status  => 'pass',
		score   => 100,
		summary => 'No external runtime dependencies detected in source',
		data    => { name => $self->name, used => 0, undeclared => 0 },
	) unless %used;

	my @undeclared = sort grep {
		!$declared{$_} && !_covered_by_namespace(\%declared, $_)
	} keys %used;

	return $self->_build_result(\%used, \@undeclared);
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _build_result {
	my ($self, $used_ref, $undeclared_ref) = @_;

	my $n_bad   = scalar @{$undeclared_ref};
	my $n_total = scalar keys %{$used_ref};

	if ($n_bad == 0) {
		my $dep_word = $n_total == 1 ? 'dependency is' : 'dependencies are';
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => "All $n_total runtime $dep_word declared",
			data    => { name => $self->name, used => $n_total, undeclared => 0 },
		);
	}

	my $score  = int(100 * ($n_total - $n_bad) / $n_total);
	my $status = $score >= $SCORE_WARN ? 'warn' : 'fail';
	my $noun   = $n_bad == 1 ? 'dependency' : 'dependencies';

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => "$n_bad undeclared runtime $noun found",
		details => [ map { "Undeclared: $_" } @{$undeclared_ref} ],
		data    => {
			name       => $self->name,
			used       => $n_total,
			undeclared => $n_bad,
			modules    => $undeclared_ref,
		},
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## no critic (ProhibitUnusedPrivateSubroutines)
sub _collect_declared {
	my ($meta) = @_;
	my $prereqs = $meta->effective_prereqs;
	my %declared;
	for my $phase (qw(runtime configure build develop)) {
		my $req = $prereqs->requirements_for($phase, 'requires');
		$declared{$_} = 1 for $req->required_modules;
	}
	return %declared;
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _scan_file {
	my ($file, $dist_ns, $use_corelist) = @_;
	my %found;
	my $in_pod = 0;

	open my $fh, '<', $file;
	my @lines = <$fh>;
	close $fh;

	for my $line (@lines) {
		if ($line =~ /^ = (\w+) /x) {
			$in_pod = ($1 ne 'cut');
			next;
		}
		next if $in_pod;
		next if $line =~ /^\s*[#]/x;   # [#] so /x does not eat the literal #

		# Remove eval { ... } blocks so that optional 'require' inside eval
		# (e.g. eval { require Module::Foo; 1 }) are not treated as hard deps.
		my $scan = $line;
		$scan =~ s/ \b eval \s* [{] [^}]* [}] //gx;

		while ($scan =~ / \b (?:use|require) \s+ ([\w:]+) /gx) {
			my $mod = $1;
			next if $mod =~ /^\d/x;
			next unless _is_external_dep($mod, $dist_ns, $use_corelist);
			$found{$mod}++;
		}
	}

	return %found;
}

# Returns true when $mod is covered by a parent-namespace or two-part-prefix
# match in %declared.  This handles:
#   - CPAN::Audit::Query covered by declared CPAN::Audit
#   - Module::CPANTS::Kwalitee covered by declared Module::CPANTS::Analyse
## no critic (ProhibitUnusedPrivateSubroutines)
sub _covered_by_namespace {
	my ($declared_ref, $mod) = @_;

	for my $decl (keys %{$declared_ref}) {
		# Strict sub-namespace: Foo::Bar::Baz covered by declared Foo::Bar
		return 1 if index($mod, "${decl}::") == 0;

		# Two-part-prefix sibling: Module::CPANTS::Kwalitee covered by Module::CPANTS::Analyse
		my @mod_p  = split /  ::/x, $mod;
		my @dec_p  = split /  ::/x, $decl;
		next if @mod_p < 3 || @dec_p < 3;
		return 1 if $mod_p[0] eq $dec_p[0] && $mod_p[1] eq $dec_p[1];
	}

	return 0;
}

# Returns true when $mod is an external CPAN dependency that must be declared.
## no critic (ProhibitUnusedPrivateSubroutines)
sub _is_external_dep {
	my ($mod, $dist_ns, $use_corelist) = @_;

	# All-lowercase names are Perl pragmas (strict, warnings, autodie, etc.)
	return 0 if $mod =~ /^ [a-z] [a-z0-9_]* (?: :: [a-z] [a-z0-9_]* )* $/x;

	# Internal -- same distribution namespace
	if (length $dist_ns) {
		return 0 if index($mod, $dist_ns) == 0;
	}

	# Hardcoded always-available set (core modules we know to always be present)
	return 0 if $ALWAYS_AVAILABLE_SET{$mod};

	# Module::CoreList: if the module has ever been in Perl core, skip it.
	if ($use_corelist) {
		return 0 if defined Module::CoreList->first_release($mod);
	}

	return 1;
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
