use strict;
use warnings;
use Pod::Markdown::Github;
use Test::More;


{
my $str = q[
=pod

    sub a {
        say "ok";
    }

=cut
];
my $ok = q[```perl
sub a {
    say "ok";
}
```
];
parse_ok( $str, $ok );
}

{
my $str = q[
=pod

    find ./ | grep *.pl
    ls -al

=cut
];

my $ok = q[```
find ./ | grep *.pl
ls -al
```
];

parse_ok( $str, $ok );

}

done_testing;

sub parse_ok {
    my ( $in, $out ) = @_;
    my $result;
    my $parser = Pod::Markdown::Github->new;
    $parser->output_string( \$result );
    $parser->parse_string_document($in);
    is $result, $out;
}
