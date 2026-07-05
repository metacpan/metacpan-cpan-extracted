use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::Kwalitee;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::Kwalitee->new;
isa_ok($check, 'Test::CPAN::Health::Check::Kwalitee');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'kwalitee',        'id');
is($check->name,     'CPANTS Kwalitee', 'name');
is($check->weight,   5,                 'weight');
is($check->category, 'quality',         'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

sub write_file {
	my ($path, $content) = @_;
	make_path(dirname($path));
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
}

# ---------------------------------------------------------------------------
# run() croaks on wrong argument type
# ---------------------------------------------------------------------------

throws_ok(
	sub { $check->run('not a dist') },
	qr/must be a Test::CPAN::Health::Distribution/,
	'run() croaks on non-Distribution argument',
);

# ---------------------------------------------------------------------------
# Everything below requires Module::CPANTS::Analyse
# ---------------------------------------------------------------------------

my $have_mcpants = eval { require Module::CPANTS::Analyse; 1 };

SKIP: {
	skip 'Module::CPANTS::Analyse not installed', 14 unless $have_mcpants;

	# ------------------------------------------------------------------
	# Minimal dist: very few files -- should get a low score
	# ------------------------------------------------------------------

	{
		my ($tmp, $dist) = make_dist();

		# A bare-minimum distribution with no META, no MANIFEST, no README.
		# Kwalitee will fail many indicators -> low score.
		write_file(File::Spec->catfile($tmp, 'lib', 'Bare.pm'), <<'END');
package Bare;
our $VERSION = '0.01';
1;
END

		my $result = $check->run($dist);
		isa_ok($result, 'Test::CPAN::Health::Result', 'bare dist returns a Result');
		is($result->check_id, 'kwalitee', 'result check_id');

		# Module::CPANTS::Analyse may fail on some platforms (e.g. fork-open
		# on Windows); skip score/data assertions when the check itself errored.
		SKIP: {
			skip 'bare dist: Module::CPANTS::Analyse could not run: '
				. $result->summary, 9
				unless grep { $result->status eq $_ } qw(pass warn fail);

			ok(defined $result->score,                        'bare dist: score defined');
			ok($result->score >= 0 && $result->score <= 100, 'bare dist: score in 0..100');
			ok(grep { $result->status eq $_ } qw(pass warn fail), 'bare dist: status is pass/warn/fail');
			ok(@{ $result->details } > 0,                    'bare dist: details populated');
			ok(exists $result->data->{passed},               'data has passed');
			ok(exists $result->data->{total},                'data has total');
			ok(exists $result->data->{failed_core},          'data has failed_core');
			ok(exists $result->data->{failed_extra},         'data has failed_extra');
			ok($result->data->{total} > 0,                   'total indicators > 0');
		}
	}

	# ------------------------------------------------------------------
	# Well-equipped dist: README, MANIFEST, Makefile.PL, META.yml,
	# lib/, t/, LICENSE -- should pass more indicators.
	# ------------------------------------------------------------------

	{
		my ($tmp, $dist) = make_dist();

		write_file(File::Spec->catfile($tmp, 'lib', 'Good.pm'), <<'END');
package Good;
use strict;
use warnings;
our $VERSION = '0.01';

=head1 NAME

Good - A well-written module

=head1 SYNOPSIS

    use Good;

=head1 DESCRIPTION

Does something good.

=head1 AUTHOR

Test Author

=head1 LICENSE

This module is free software.

=cut

1;
END

		write_file(File::Spec->catfile($tmp, 't', 'basic.t'), <<'END');
use strict;
use warnings;
use Test::More;
ok(1, 'trivial test');
done_testing;
END

		write_file(File::Spec->catfile($tmp, 'Makefile.PL'), <<'END');
use ExtUtils::MakeMaker;
WriteMakefile(NAME => 'Good', VERSION => '0.01');
END

		write_file(File::Spec->catfile($tmp, 'README'), 'This is the README.');

		write_file(File::Spec->catfile($tmp, 'LICENSE'), <<'END');
This software is copyright (c) 2025 by Test Author.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.
END

		write_file(File::Spec->catfile($tmp, 'META.yml'), <<'END');
---
name: Good
version: '0.01'
abstract: 'A well-written module'
author:
  - 'Test Author <test@example.com>'
license: perl
meta-spec:
  version: '1.4'
  url: http://module-build.sourceforge.net/META-spec-v1.4.html
END

		write_file(File::Spec->catfile($tmp, 'MANIFEST'), <<'END');
lib/Good.pm
t/basic.t
Makefile.PL
README
LICENSE
META.yml
MANIFEST
END

		my $result = $check->run($dist);

		SKIP: {
			skip 'good dist: Module::CPANTS::Analyse could not run: '
				. $result->summary, 3
				unless grep { $result->status eq $_ } qw(pass warn fail);

			ok(defined $result->score,          'good dist: score defined');
			ok($result->score > 0,              'good dist: score > 0');
			ok($result->data->{passed} > 0,     'good dist: some indicators passed');
		}
	}
}

done_testing;
