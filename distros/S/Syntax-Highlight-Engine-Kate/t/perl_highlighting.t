use strict;
use warnings;

use Test::More;
use Test::Differences;
use lib 't/lib';
use TestHighlight ':all';

diag <<'END';
We don't actually know if these are highlighted correctly, but this
makes decent regression tests when we refactor.
END

my ( $before, $after ) = ( 't/perl/before', 't/perl/highlighted' );

my $highlighted_version_of = get_sample_perl_files();
plan tests => scalar keys %$highlighted_version_of;

for my $perl ( sort keys %$highlighted_version_of ) {
    my $highlighted = $highlighted_version_of->{$perl};
    my $have        = get_highlighter('Perl')->highlightText( slurp($perl) );
    my $want        = slurp($highlighted);
	chomp $want;

    eq_or_diff $have, $want, "($perl) was highlighted correctly";
}
