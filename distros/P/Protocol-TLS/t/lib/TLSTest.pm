use strict;
use warnings;
use Exporter qw(import);
our @EXPORT = qw(hstr binary_eq bin2hex);

sub hstr {
    my $str = shift;
    $str =~ s/\#.*//g;
    $str =~ s/\s//g;
    my @a = ( $str =~ /../g );
    return pack "C*", map { hex $_ } @a;
}

sub bin2hex {
    my $bin = shift;
    my $c   = 0;
    my $s;

    join "", map {
        $c++;
        $s = !( $c % 16 ) ? "\n" : ( $c % 2 ) ? "" : " ";
        $_ . $s
    } unpack( "(H2)*", $bin );

}

sub binary_eq {
    my ( $b1, $b2 ) = @_;
    if ( $b1 eq $b2 ) {
        return 1;
    }
    else {
        $b1 = bin2hex($b1);
        $b2 = bin2hex($b2);
        chomp $b1;
        chomp $b2;
        print "$b1\n not equal \n$b2 \n";
        return 0;
    }
}

1;

