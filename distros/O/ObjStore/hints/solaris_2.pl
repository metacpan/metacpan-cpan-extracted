my $cc = '-vdelx -pta';
my $ld = '-ztext';

$self->{CC}="CC $cc";
$self->{LD}="CC $ld";

my $dbv = 0;
if ($dbv >= 1) {
    $self->{OPTIMIZE} = '-g';
}
if ($dbv >= 2) {
    # Insure++ is amazing!  http://www.parasoft.com
    $self->{CC} = "insure -Zoi 'compiler CC' $cc";
    $self->{LD} = "insure -Zoi 'compiler CC' $ld";
}

$self->{CCCDLFLAGS} = "-KPIC";
$self->{clean}{FILES} .= ' Templates.DB';
