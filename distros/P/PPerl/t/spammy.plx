#!perl
# should do what SpamAssasin does

my $die = shift @ARGV;

eval {
    die $die if $die;
    exit 0;
};
if ($@) {
    warn $@;
    exit 70;
}
