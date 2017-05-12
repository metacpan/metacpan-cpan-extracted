$self->{CC}="CC -vdelx -pta";
$self->{LD}="CC -ztext";

my $dbv = 0;
if ($dbv >= 1) {
    $self->{OPTIMIZE} = '-g';
}
if ($dbv >= 2) {
    # Insure++ is amazing!  http://www.parasoft.com
    $self->{CC} = "insure -Zoi 'compiler CC' -vdelx -pta";
    $self->{LD} = "insure -Zoi 'compiler CC' -ztext";
}

$self->{CCCDLFLAGS} = "-KPIC";
$self->{clean}{FILES} .= ' Templates.DB';
$self->{PERLMAINCC} = 'gcc';

