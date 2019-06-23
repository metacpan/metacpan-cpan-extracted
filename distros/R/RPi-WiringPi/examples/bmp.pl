use constant {
    BMP_BASE => 100,
};

my $bmp_run_counts = 0;

my $pi = RPi::WiringPi->new;

my $bmp = $pi->bmp(BMP_BASE);

while (1){
    say $bmp_run_counts += 1;
    say "temp C " . $bmp->temp('c');
    say "bmp    " . $bmp->pressure;
    print "\n";
    sleep 1;
}
