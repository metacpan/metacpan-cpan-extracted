use strict;
use warnings;
use Test::More import => [qw(ok is is_deeply like done_testing)];
use Test::AutoMock qw(mock_overloaded manager);

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    my (undef) = ($z + 0);
    my (undef) = ($z - 0);
    my (undef) = ($z * 1);
    my (undef) = ($z / 1);
    my (undef) = ($z % 1);
    my (undef) = ($z ** 1);
    my (undef) = ($z << 0);
    my (undef) = ($z >> 0);
    my (undef) = ($z x 1);
    my (undef) = ($z . '');

    my @calls = manager($mock)->calls;
    is @calls, 11;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`+`', [0, '']];
    is_deeply $calls[2], ['z->`-`', [0, '']];
    is_deeply $calls[3], ['z->`*`', [1, '']];
    is_deeply $calls[4], ['z->`/`', [1, '']];
    is_deeply $calls[5], ['z->`%`', [1, '']];
    is_deeply $calls[6], ['z->`**`', [1, '']];
    is_deeply $calls[7], ['z->`<<`', [0, '']];
    is_deeply $calls[8], ['z->`>>`', [0, '']];
    is_deeply $calls[9], ['z->`x`', [1, '']];
    is_deeply $calls[10], ['z->`.`', ['', '']];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    $z += 0;
    $z -= 0;
    $z *= 1;
    $z /= 1;
    $z %= 1;
    $z **= 1;
    $z <<= 0;
    $z >>= 0;
    $z x= 1;
    $z .= '';

    my @calls = manager($mock)->calls;
    is @calls, 11;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`+=`', [0, undef]];
    is_deeply $calls[2], ['z->`-=`', [0, undef]];
    is_deeply $calls[3], ['z->`*=`', [1, undef]];
    is_deeply $calls[4], ['z->`/=`', [1, undef]];
    is_deeply $calls[5], ['z->`%=`', [1, undef]];
    is_deeply $calls[6], ['z->`**=`', [1, undef]];
    is_deeply $calls[7], ['z->`<<=`', [0, undef]];
    is_deeply $calls[8], ['z->`>>=`', [0, undef]];
    is_deeply $calls[9], ['z->`x=`', [1, undef]];
    is_deeply $calls[10], ['z->`.=`', ['', undef]];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    my (undef) = ($z < 0);
    my (undef) = ($z <= 0);
    my (undef) = ($z > 0);
    my (undef) = ($z >= 0);
    my (undef) = ($z == 0);
    my (undef) = ($z != 0);

    my @calls = manager($mock)->calls;
    is @calls, 7;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`<`', [0, '']];
    is_deeply $calls[2], ['z->`<=`', [0, '']];
    is_deeply $calls[3], ['z->`>`', [0, '']];
    is_deeply $calls[4], ['z->`>=`', [0, '']];
    is_deeply $calls[5], ['z->`==`', [0, '']];
    is_deeply $calls[6], ['z->`!=`', [0, '']];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    my (undef) = ($z <=> 0);
    my (undef) = ($z cmp 0);

    my @calls = manager($mock)->calls;
    is @calls, 3;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`<=>`', [0, '']];
    is_deeply $calls[2], ['z->`cmp`', [0, '']];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    my (undef) = ($z lt '');
    my (undef) = ($z le '');
    my (undef) = ($z gt '');
    my (undef) = ($z ge '');
    my (undef) = ($z eq '');
    my (undef) = ($z ne '');

    my @calls = manager($mock)->calls;
    is @calls, 7;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`lt`', ['', '']];
    is_deeply $calls[2], ['z->`le`', ['', '']];
    is_deeply $calls[3], ['z->`gt`', ['', '']];
    is_deeply $calls[4], ['z->`ge`', ['', '']];
    is_deeply $calls[5], ['z->`eq`', ['', '']];
    is_deeply $calls[6], ['z->`ne`', ['', '']];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    my (undef) = ($z & 0xff);
    my (undef) = ($z &= 0xff);
    my (undef) = ($z | 0x00);
    my (undef) = ($z |= 0x00);
    my (undef) = ($z ^ 0x00);
    my (undef) = ($z ^= 0x00);
    # my (undef) = ($z &. "\xff");
    # my (undef) = ($z &.= "\xff");
    # my (undef) = ($z |. "\x00");
    # my (undef) = ($z |.= "\x00");
    # my (undef) = ($z ^. "\x00");
    # my (undef) = ($z ^.= "\x00");

    my @calls = manager($mock)->calls;
    is @calls, 7;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`&`', [0xff, '']];
    is_deeply $calls[2], ['z->`&=`', [0xff, undef]];
    is_deeply $calls[3], ['z->`|`', [0x00, '']];
    is_deeply $calls[4], ['z->`|=`', [0x00, undef]];
    is_deeply $calls[5], ['z->`^`', [0x00, '']];
    is_deeply $calls[6], ['z->`^=`', [0x00, undef]];
    # is_deeply $calls[7], ['z->`&.`', ["\xff", '']];
    # is_deeply $calls[8], ['z->`&.=`', ["\xff", undef]];
    # is_deeply $calls[9], ['z->`|.`', ["\x00", '']];
    # is_deeply $calls[10], ['z->`|.=`', ["\x00", undef]];
    # is_deeply $calls[11], ['z->`^.`', ["\x00", '']];
    # is_deeply $calls[12], ['z->`^.=`', ["\x00", undef]];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    my (undef) = - $z;
    my (undef) = ! $z;
    my (undef) = ~ $z;
    # my (undef) = ~. $z;

    my @calls = manager($mock)->calls;
    is @calls, 4;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`neg`', [undef, '']];
    is_deeply $calls[2], ['z->`!`', [undef, '']];
    is_deeply $calls[3], ['z->`~`', [undef, '']];
    # is_deeply $calls[4], ['z->`~.`', [undef, undef]];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    ++$z;
    --$z;

    my @calls = manager($mock)->calls;
    is @calls, 3;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`++`', [undef, '']];
    is_deeply $calls[2], ['z->`--`', [undef, '']];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    my (undef) = (atan2 $z, 1);
    my (undef) = (cos $z);
    my (undef) = (sin $z);
    my (undef) = (exp $z);
    my (undef) = (abs $z);
    my (undef) = (log $z);
    my (undef) = (sqrt $z);
    my (undef) = (int $z);

    my @calls = manager($mock)->calls;
    is @calls, 9;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`atan2`', [1, '']];
    is_deeply $calls[2], ['z->`cos`', [undef, '']];
    is_deeply $calls[3], ['z->`sin`', [undef, '']];
    is_deeply $calls[4], ['z->`exp`', [undef, '']];
    is_deeply $calls[5], ['z->`abs`', [undef, '']];
    is_deeply $calls[6], ['z->`log`', [undef, '']];
    is_deeply $calls[7], ['z->`sqrt`', [undef, '']];
    is_deeply $calls[8], ['z->`int`', [undef, '']];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    ok $z ? 1 : 0;
    like "$z", qr/\bAutoMock\b/;
    is sprintf('%d', $z), '1';
    is qr/$z/, qr//;

    my @calls = manager($mock)->calls;
    is @calls, 5;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`bool`', [undef, '']];
    is_deeply $calls[2], ['z->`""`', [undef, '']];
    is_deeply $calls[3], ['z->`0+`', [undef, '']];
    is_deeply $calls[4], ['z->`qr`', [undef, '']];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    while (<$z>) {}

    my @calls = manager($mock)->calls;
    is @calls, 2;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`<>`', [undef, '']];
}

{
    my $mock = mock_overloaded;
    my $z = $mock->z;
    my (undef) = (-e $z);

    my @calls = manager($mock)->calls;
    is @calls, 3;
    is_deeply $calls[0], ['z', []];
    is_deeply $calls[1], ['z->`-X`', ['e', '']];
    is_deeply $calls[2], ['z->`-X`->`bool`', [undef, '']];
}

# {
#     my $mock = mock_overloaded;
#     my $z = $mock->z;
#     my (undef) = ($z ~~ [1, 2, 3]);

#     my @calls = manager($mock)->calls;
#     is @calls, 2;
#     is_deeply $calls[0], ['z', []];
#     is_deeply $calls[1], ['z->`~~`', ['1', '']];
# }

{
    my $mock = mock_overloaded;
    my $any_ref = $mock->get_ref;
    is $$any_ref, undef;
    is_deeply \@$any_ref, [];
    ok $any_ref->(1, 2, 3) ? 1 : 0;
    is ref \*$any_ref, 'GLOB';
    is_deeply \%$any_ref, {};

    my @calls = manager($mock)->calls;
    is @calls, 7;
    is_deeply $calls[0], ['get_ref', []];
    is_deeply $calls[1], ['get_ref->`${}`', [undef, '']];
    is_deeply $calls[2], ['get_ref->FETCHSIZE', []];
    is_deeply $calls[3], ['get_ref->()', [1, 2, 3]];
    is_deeply $calls[4], ['get_ref->()->`bool`', [undef, '']];
    is_deeply $calls[5], ['get_ref->`*{}`', [undef, '']];
    is_deeply $calls[6], ['get_ref->FIRSTKEY', []];
}

{
    # a difference between + and +=, ++
    my $mock = mock_overloaded;
    my $n = $mock->n;
    my $m = $n + 1;
    $n += 1;
    $m++;
    is sprintf('%d', $n), '1';
    is sprintf('%d', $m), '1';

    my @calls = manager($mock)->calls;
    is @calls, 6;
    is_deeply $calls[0], ['n', []];
    is_deeply $calls[1], ['n->`+`', [1, '']];
    is_deeply $calls[2], ['n->`+=`', [1, undef]];
    is_deeply $calls[3], ['n->`+`->`++`', [undef, '']];
    is_deeply $calls[4], ['n->`0+`', [undef, '']];
    is_deeply $calls[5], ['n->`+`->`0+`', [undef, '']];
}

done_testing;
