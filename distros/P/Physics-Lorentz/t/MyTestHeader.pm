package MyTestHeader;
use strict;
use warnings;

use Carp qw/confess/;
use File::Spec;
use PDL;
use Params::Util qw/_INSTANCE/;

use vars qw/$Regfile $Trials @EXPORT/;
use base 'Exporter';
@EXPORT = qw(
    pdl_approx_equiv
    myisa
    $Trials
    $Regfile
);

BEGIN {
    $Regfile = $0;
    $Regfile =~ s/\.t$/.regression/;
    $Regfile = File::Spec->catfile(
        't',
        (File::Spec->splitpath($Regfile))[2]
    );
    $Trials = 100;
    $Trials = $ENV{PERL_TEST_ATTEMPTS}+0 if $ENV{PERL_TEST_ATTEMPTS};
}


sub pdl_approx_equiv {
    my ($p1, $p2, $eps) = @_;
    my $bool = all approx $p1, $p2, $eps||1e-6;
    # PDL was smarter than I

    return $bool;
}

sub myisa {
    my ($o,$c)=@_;
    my ($pkg,$file,$line)=caller(0);
    _INSTANCE($o,$c) or confess("Object not in class $c in $file line $line.\n");
}
