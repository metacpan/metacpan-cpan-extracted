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
plan tests => 1 + scalar keys %$highlighted_version_of;

for my $perl ( sort keys %$highlighted_version_of ) {
    my $highlighted = $highlighted_version_of->{$perl};
    my $have        = get_highlighter('Perl')->highlightText( slurp($perl) );
    my $want        = slurp($highlighted);
	chomp $want;

    eq_or_diff $have, $want, "($perl) was highlighted correctly";
}

# https://rt.cpan.org/Public/Bug/Display.html?id=76160
my $pod_bug = do { local $/; <DATA>; };
my $have = highlight_perl($pod_bug);

my $want = <<'END';
<normal>
</normal><keyword>#!/usr/bin/env perl</keyword><normal>
</normal><comment># https://rt.cpan.org/Ticket/Display.html?id=76160</comment><comment>
</comment><comment>=pod
</comment><comment>
</comment><comment>=head1 BORKED</comment><comment>
</comment><comment>
</comment><comment>All Perl code after this was considered a "comment" and Kate could not</comment><comment>
</comment><comment>highlight it correctly.</comment><comment>
</comment><comment>
</comment><comment>=cutabove</comment><comment>
</comment><comment>
</comment><comment>=cut</comment><normal>
</normal><normal>
</normal><keyword>my</keyword><normal> </normal><datatype>$this_is_not_a_comment</datatype><normal> = </normal><operator>'</operator><string>or a pipe</string><operator>'</operator><normal>;</normal><normal>
</normal>
END
chomp($want);

eq_or_diff $have, $want, 'post pod parsing all good';

__DATA__

#!/usr/bin/env perl
# https://rt.cpan.org/Ticket/Display.html?id=76160
=pod

=head1 BORKED

All Perl code after this was considered a "comment" and Kate could not
highlight it correctly.

=cutabove

=cut

my $this_is_not_a_comment = 'or a pipe';
