package Ogre::TestBase;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(floats_close_enough);


# Non-integers are kind of fuzzy,
# so this checks if two numbers are "close enough",
# for some arbitrary value of "close enough".
sub floats_close_enough {
    my ($f1, $f2) = @_;
    return(abs($f1 - $f2) < 0.0001);
}



1;
