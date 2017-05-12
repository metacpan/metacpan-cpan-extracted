use strict;
use warnings;
use Test::More;
use SQL::QueryMaker;
use Data::Dumper;

open my $fh, '<', 'lib/SQL/QueryMaker.pm' or die "cannot open file: $!";
# skip header
while (<$fh>) {
    last if /=head1 CHEAT SHEET/;
}
my ($src, $query, @bind);
while (<$fh>) {
    $src = $1 if /IN:\s*(.+)\s*$/;
    $query = eval $1 if /OUT QUERY:(.+)/;
    if (/OUT BIND:(.+)/) {
        @bind = eval $1;
        test($src, $query, \@bind);
    }
}
done_testing;
exit(0);

sub test {
    my ($src, $expected_term, $expected_bind) = @_;
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;

    subtest $src => sub {
        my $term;
        do {
            local $@;
            $term = eval $src;
            die $@ if $@;
        };
        my $sql = $term->as_sql();
        my @bind = $term->bind();
        is $sql, $expected_term;
        is_deeply \@bind, $expected_bind;
    };
}
