use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


plan tests => 1;


my $src = <<'END_SRC';

#!./perl

use 5.14.2;
use warnings;

format STDOUT =
@<<< @<<< @<<< @<<<<<<<<<<<<<<<<<<<<<<<
{
map { s/\n$//r } <<A, <<'}', <<"C", <<":"
1
A
2
}
@{[<<"."]}
3
.
C
@{[&format]}
:
}
.

write;

format format =
Hello from the deep
.

sub format {
    open my $h, ">", \my $format;
    select $h;
    local $~ = "format";
    write;
    select STDOUT;
    $format;
    } # format

END_SRC

use PPR;

ok  $src =~ m{ \A (?&PerlDocument) \Z   $PPR::GRAMMAR }xms;

done_testing();
