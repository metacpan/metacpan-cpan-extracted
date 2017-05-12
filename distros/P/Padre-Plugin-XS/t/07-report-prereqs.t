use strict;
use warnings;

use Test::More;

our $VERSION = '0.04';
use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::Requires {'ExtUtils::MakeMaker'   => 6.66};
use Test::Requires {'File::Spec::Functions' => 3.40};
use Test::Requires {'List::Util'            => 1.27};

use List::Util qw/max/;

my @modules = qw(
);

# replace modules with dynamic results from MYMETA.json if we can
# (hide CPAN::Meta from prereq scanner)
my $cpan_meta = "CPAN::Meta";
if (-f "MYMETA.json" && eval "require $cpan_meta") {    ## no critic
	if (my $meta = eval { CPAN::Meta->load_file("MYMETA.json") }) {
		my $prereqs = $meta->prereqs;
		my %uniq
			= map { $_ => 1 } map { keys %$_ } map { values %$_ } values %$prereqs;
		$uniq{$_} = 1 for @modules;    # don't lose any static ones
		@modules = sort keys %uniq;
	}
}

my @reports = [qw/Version Module/];

for my $mod (@modules) {
	next if $mod eq 'perl';
	my $file = $mod;
	$file =~ s{::}{/}g;
	$file .= ".pm";
	my ($prefix) = grep { -e catfile($_, $file) } @INC;
	if ($prefix) {
		my $ver = MM->parse_version(catfile($prefix, $file));
		$ver = "undef" unless defined $ver;    # Newer MM should do this anyway
		push @reports, [$ver, $mod];
	}
	else {
		push @reports, ["missing", $mod];
	}
}

if (@reports) {
	my $vl = max map { length $_->[0] } @reports;
	my $ml = max map { length $_->[1] } @reports;
	splice @reports, 1, 0, ["-" x $vl, "-" x $ml];
	diag "Prerequisite Report:\n",
		map { sprintf("  %*s %*s\n", $vl, $_->[0], -$ml, $_->[1]) } @reports;
}

pass;

done_testing();

__END__

pass;

# vim: ts=2 sts=2 sw=2 et:

