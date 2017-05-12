use Test::More tests => 31;

use strict;
use warnings;

BEGIN {
    use_ok('String::Unquotemeta');
}

diag("Testing String::Unquotemeta $String::Unquotemeta::VERSION");

ok( defined &unquotemeta, 'Exported' );

my @strings = ( q{http://howdy.com/foo?howdy=skip a space @ \ }, q{ftp://foo.com.buz/\"I am you pal\"}, q{aim://foo.com/~!@#$%^&*()_+||:"<>?,./;'[]\"}, 'curly://queue{}', q{non interp, three \\\ }, qq{interp, three \\\ }, q{double://slashs/\\\\howdy}, q{triple://slashs/\\\\\\howdy}, q{quad://slashs/\\\\\\\\howdy}, 'noquotemetadata', '', undef, );

# test w/ arg
for my $string (@strings) {
    no warnings 'uninitialized';    # avoid undef's: "Use of uninitialized value $string in [quotemeta|length] ..."
    my $qm = quotemeta($string);
    if ( !defined $string ) {
        $qm = undef;                # so that unquotemeta() will get the same value
    }
    my $uq = unquotemeta($qm);

    my $label = length($string) ? $string : 'empty string';    # Use of uninitialized value $string in length ...å
    if ( !defined $string ) {
        $string = '';                                          # so that is() will test for the expected result
        $label  = "undefined";
    }

    is( $uq, $string, 'via arg: ' . $label );
}

# test $_
for (@strings) {
    my $orig = $_;
    $_ = quotemeta;
    if ( !defined $orig ) {
        $_    = undef;                                         # so that unquotemeta() will get the same value
        $orig = '';                                            # so that is() will test for the expected result
    }
    my $uq = unquotemeta;

    my $label = length($orig) ? $orig : 'empty string';
    $label = "undefined" if !defined $_;

    is( $uq, $orig, 'via $_: ' . $label );
}

# prototype similarities
my @x;
is( quotemeta(@x), unquotemeta(@x), 'ARRAY empty' );
push @x, "howdy";
is( quotemeta(@x), unquotemeta(@x), 'ARRAY 1' );
push @x, "dooty";
is( quotemeta(@x), unquotemeta(@x), 'ARRAY 2' );

{
    local $@;
    eval q{quotemeta('too','many','args')};
    ok( $@, 'quotemeta() prototype $@' );
}

{
    undef $@;
    eval q{unquotemeta('too','many','args')};
    ok( $@, 'unquotemeta() prototype $@' );
}
