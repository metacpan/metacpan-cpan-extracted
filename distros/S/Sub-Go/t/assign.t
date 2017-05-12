use strict;
use warnings;

use Test::More;
use Sub::Go;

sub sum { my $x; $x+=$_ for @_; $x }
{
    my $ret = 10 ~~ go { $_ * 10 };
    is( $ret, 100, 'assign num' );
}
{
    my $ret = 10 ~~ go { $_ * 10 } go { $_ * 2 };
    is( $ret, 200, 'assign num chained' );
}
{
    my $ret = { 1=>11, 2=>22 } ~~ go { "$a$b" };
    is sum(@$ret), 333, 'a-b keys';

    my $hh = { aa=>11 };
    my $h2 = $hh ~~ go { +{ "x$a" => $b } };
    is $h2->{xaa}, 11, 'hash creation';

    my %h3;
    { aa=>11, bb=>22} ~~ go { ( $a => $b*2 ) } \%h3;
    is $h3{bb}, 44, 'hash assign';
}
{
    my $ret = [1..3] ~~ go { $_ * 10 };
    is( sum(@$ret), 60, 'arr to scalar num' );
}
{
    my @rs = ( { name=>'jack', age=>20 }, { name=>'joe', age=>45 } );
    #@rs ~~ sub { warn shift->{name} };
    @rs ~~ go { $_->{name} = 'sue' };
    is( join(',',map { $_->{name} } @rs), 'sue,sue', 'rs modify' );
}
{
    my @arr = qw/1 2 3/;
    my @out;
    @arr ~~ go { $_ * 2 } \@out;
    is( join(',',@out), '2,4,6', 'out array' );
}
{
    my $out;
    'hello' ~~ go { $_ . ' world' } \$out;
    is( $out, 'hello world', 'out scalar' );
}
{
    my %hash = ( aa=>11, bb=>22 );
    my %out;
    %hash ~~ go { "xx$_[0]" => $_[1] } \%out;
    #use YAML;
    #warn Dump \%out;
    is( $out{xxaa}, 11, 'out hash' );
}

done_testing;
