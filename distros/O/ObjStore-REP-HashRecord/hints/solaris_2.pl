$self->{CC}="CC -vdelx -pta";
$self->{LD}="CC -ztext";

# Insure++
#$self->{CC}="insure -Zoi 'compiler CC' -vdelx -pta";
#$self->{LD}="insure -Zoi 'compiler CC' -ztext";


$self->{CCCDLFLAGS}="-KPIC";
$self->{clean}{FILES} .= ' Templates.DB';
$self->{PERLMAINCC} = 'gcc';

