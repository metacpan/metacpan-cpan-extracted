use strict;
use warnings;
use Test::More;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

my $pod = << 'POD';
=begin filter num

    CHOMP_CHOMP
    SKWAPPO
    PATWEEEE

    PLORTCH
    WAP_WAP_WAP_WAP

=end filter
POD

my @tests = (
    [ [], << 'OUTPUT' ],
<html><body bgcolor="#ffffff">
<pre>    1: CHOMP_CHOMP
    2: SKWAPPO
    3: PATWEEEE
    4: 
    5: PLORTCH
    6: WAP_WAP_WAP_WAP</pre>
</body></html>
OUTPUT
    [ [ auto_unindent => 0 ], << 'OUTPUT' ],
<html><body bgcolor="#ffffff">
<pre>1:     CHOMP_CHOMP
2:     SKWAPPO
3:     PATWEEEE
4: 
5:     PLORTCH
6:     WAP_WAP_WAP_WAP</pre>
</body></html>
OUTPUT
);

# add a numbering filter
Pod::POM::View::HTML::Filter->add(
    num => {
        code => sub { my $s = shift; my $i = 1; $s =~ s/^/$i++.': '/gem; $s },
        verbatim => 1
    },
);

plan tests => scalar @tests;

my $pom = Pod::POM->new->parse_text($pod);

for my $t (@tests) {
    my $view = Pod::POM::View::HTML::Filter->new( @{ $t->[0] } );
    is( $pom->present($view), $t->[1], "Options: @{$t->[0]}" );
}

