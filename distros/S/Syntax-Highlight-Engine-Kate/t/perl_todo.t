use strict;
use warnings;

use Test::More;
use Test::Differences;
use lib 't/lib';
use TestHighlight 'highlight_perl';

plan tests => 2;

# https://rt.cpan.org/Ticket/Display.html?id=76182
my $underscore_bug = <<'END';
my
$underscore_bug
=
10_000
;
END

my $want = <<'END';
<keyword>my</keyword><normal>
</normal><variable>$underscore_bug</variable><datatype>
</datatype><operator>=</operator><normal>
</normal><float>10_100</float><normal>
</normal><operator>;</operator><normal>
</normal>
END
my $have = highlight_perl($underscore_bug);
TODO: {
    local $TODO = 'Kate does not yet handle numbers with underscores (10_000)';
    eq_or_diff $have, $want, 'Numbers with underscores should parse correctly';
}

# https://rt.cpan.org/Ticket/Display.html?id=76168
my $heredoc_bug = <<'END';
my $heredoc_bug = <<'HEY';
We be here
HEY! <-- this is not the terminator
and here
HEY
END
$have = highlight_perl($heredoc_bug);

$want = <<'END';
<keyword>my</keyword><normal> </normal><variable>$heredoc_bug</variable><normal> </normal><operator>=</operator><operator> <<</operator><keyword>'HEY';</keyword><normal>
</normal><string>We be here</string><normal>
</normal><string>HEY! <-- this is not the terminator</string><normal>
</normal><string>and here</string><normal>
</normal><keyword>HEY</keyword><normal>
</normal>
END

TODO: {
    local $TODO = 'Kate sometimes guesses the heredoc terminator incorrectly';
    eq_or_diff $have, $want, 'heredocs should parse correctly';
}
__END__

#!/usr/bin/env perl


my $heredoc_bug = <<'HEY';
We be here
HEY! <-- this is not the terminator
and here
HEY

# https://rt.cpan.org/Ticket/Display.html?id=76160

=head1 BORKED

All Perl code after this was considered a "comment" and Kate could not
highlight it correctly.

=cut

my $this_is_not_a_comment = 'or a pipe';
