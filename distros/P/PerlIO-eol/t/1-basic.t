use strict;
use Test::More tests => 23;

BEGIN { use_ok('PerlIO::eol', qw( eol_is_mixed CR LF CRLF NATIVE )) }

my ($CR, $LF, $CRLF) = (CR, LF, CRLF);

is( eol_is_mixed("."), 0 );
is( eol_is_mixed(".$CRLF."), 0 );
is( eol_is_mixed(".$CR.$LF."), 3 );
is( eol_is_mixed(".$CRLF.$CR"), 4 );

$/ = undef;

sub is_hex ($$;$) {
    @_ = (
        join(' ', unpack '(H2)*', $_[0]),
        join(' ', unpack '(H2)*', $_[1]),
        $_[2],
    );
    goto &is;
}

{
    open my $w, ">:raw", "read" or die "can't create testfile: $!";
    print $w "...$CRLF$LF$CR...";
}

{
    ok(open(my $r, "<:raw:eol(CR)", "read"), "open for read");
    is_hex(<$r>, "...$CR$CR$CR...", "read");
}

{
    ok(open(my $r, "<:raw:eol(LF)", "read"), "open for read");
    is_hex(<$r>, "...$LF$LF$LF...", "read");
}

{
    ok(open(my $r, "<:raw:eol(CRLF)", "read"), "open for read");
    is_hex(<$r>, "...$CRLF$CRLF$CRLF...", "read");
}

{
    local $@;
    ok(open(my $r, "<:raw:eol(CR!)", "read"), "open for read");
    is(eval { <$r> }, undef, 'mixed encoding');
    like($@, qr/Mixed newlines/, 'raises exception');
}

{
    ok(open(my $r, "<:raw:eol(CRLF?)", "read"), "open for read");
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    is_hex(<$r>, "...$CRLF$CRLF$CRLF...", "read");
    like($warning, qr/Mixed newlines found in "read"/, 'raises exception');
}

{
    local $@;
    open my $w, ">:raw:eol(LF!)", "write" or die "can't create testfile: $!";
    eval { print $w "...$CRLF$LF$CR..." };
    like($@, qr/Mixed newlines found in "write"/, 'raises exception');
}

TODO: {
    local $@;
    local $TODO = 'Trailing CR in mixed encodings';
    open my $w, ">:raw:eol(LF!)", "write" or die "can't create testfile: $!";
    eval { print $w "...$CRLF$CR" };
    like($@, qr/Mixed newlines found in "write"/, 'raises exception');
}

{
    ok(open(my $w, ">:raw:eol(CrLf-lf)", "write"), "open for write");
    print $w "...$CR$LF...";
}

{
    open my $r, "<:raw", "write" or die "can't read testfile: $!";
    is_hex(<$r>, "...$LF...", "write");
}

{
    ok(open(my $w, ">:raw:eol(LF-Native)", "write"), "open for write");
    print $w "...$CR";
}

{
    open my $r, "<", "write" or die "can't read testfile: $!";
    is_hex(<$r>, "...\n", "write");
}

END {
    unlink "read";
    unlink "write";
}
