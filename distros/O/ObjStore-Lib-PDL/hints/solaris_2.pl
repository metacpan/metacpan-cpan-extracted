my $dv = 1;
if ($dv >= 0) {
    $self->{CC}="CC -vdelx -pta";
    $self->{LD}="CC -ztext";
}
if ($dv >= 1) {
    $self->{OPTIMIZE} = '-g';
}
if ($dv >= 2) {
    # Insure++
    $self->{CC}="insure -Zoi 'compiler CC' -vdelx -pta";
    $self->{LD}="insure -Zoi 'compiler CC' -ztext";
}

$self->{CCCDLFLAGS}="-KPIC";
$self->{clean}{FILES} .= ' Templates.DB';
$self->{PERLMAINCC} = 'gcc';

