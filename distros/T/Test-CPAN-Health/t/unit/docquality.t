use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::DocQuality;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::DocQuality->new;
isa_ok($check, 'Test::CPAN::Health::Check::DocQuality');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'doc_quality',            'id');
is($check->name,     'Documentation Quality',  'name');
is($check->weight,   4,                         'weight');
is($check->category, 'quality',                 'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

sub write_lib_pm {
	my ($tmp, $filename, $content) = @_;
	my $lib = File::Spec->catdir($tmp, 'lib');
	make_path($lib);
	my $path = File::Spec->catfile($lib, $filename);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
}

# ---------------------------------------------------------------------------
# No .pm files -> skip
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);
	is($result->status, 'skip', 'no pm files -> skip');
}

# ---------------------------------------------------------------------------
# Well-documented module (all required sections, no errors) -> pass
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Good.pm', <<'END');
package Good;

=head1 NAME

Good - a well-documented module

=head1 SYNOPSIS

    use Good;

=head1 DESCRIPTION

This module is perfectly documented.

=head1 AUTHOR

Test Author

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Test Author. GPL v2.

=cut

1;
END

	my $result = $check->run($dist);
	is($result->status, 'pass', 'fully documented -> pass');
	is($result->score,  100,    'fully documented -> score 100');
}

# ---------------------------------------------------------------------------
# Missing required sections -> warn
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Partial.pm', <<'END');
package Partial;

=head1 NAME

Partial - module with partial docs

=head1 DESCRIPTION

Missing SYNOPSIS and AUTHOR.

=cut

1;
END

	my $result = $check->run($dist);
	is($result->status, 'warn', 'missing sections -> warn');
	ok($result->score < 100, 'missing sections: score < 100');
	ok(@{ $result->details }, 'details list populated');
}

# ---------------------------------------------------------------------------
# No POD at all -> score 0 for that file
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'NoPod.pm', <<'END');
package NoPod;
sub foo { 1 }
1;
END

	my $result = $check->run($dist);
	ok($result->score < 50, 'no POD -> low score');
	like($result->summary, qr/issue/i, 'summary mentions issues');
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
# Result is a proper Result object
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'doc_quality', 'result carries correct check_id');
}

done_testing;
