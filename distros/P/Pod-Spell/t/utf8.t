use 5.008; # for utf8
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Deep;
use File::Temp;

use Pod::Spell;
use Pod::Wordlist;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":utf8";

my $podfile  = File::Temp->new;

binmode($podfile, ":utf8");

print $podfile <<'ENDPOD';
=encoding utf8

=for :stopwords
virtE<ugrave> résumé

=head1 Testing virtE<ugrave> & résumé

Our virtE<ugrave> & virtù & résumé for Mengué in 日本

=cut
ENDPOD

my @cases = (
    {
        label => "wide chars allowed",
        options => {},
        expected => [ qw( Testing Our for Mengué in 日本 ) ],
    },
    {
        label => "wide chars stripped",
        options => { no_wide_chars => 1 },
        expected => [ qw( Testing Our for Mengué in ) ],
    },
);

for my $c ( @cases ) {

    my $textfile = File::Temp->new;
    binmode $textfile, ":utf8";

    # reread from beginning
    $podfile->seek( 0, 0 );

    my $p = new_ok 'Pod::Spell' => [ debug => 1, %{ $c->{options} } ];

    $p->parse_from_filehandle( $podfile, $textfile );

    # reread from beginning
    $textfile->seek( 0, 0 );

    my $in = do { local $/ = undef, <$textfile> };

    my @words = split " ", $in;

    my @expected = @{ $c->{expected} };

    is scalar @words, scalar @expected, "$c->{label}: word count";

    cmp_deeply \@words, bag( @expected ), "$c->{label}: words match"
        or diag "@words";
}

done_testing;
