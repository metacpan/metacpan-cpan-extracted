# benchmark/Common.pm
use 5.008_001;

use strict;
use B qw(svref_2object);
use Config qw(%Config);
use XSLoader();
use DynaLoader();
use Carp qw(longmess);

$SIG{__WARN__} = \&longmess;

sub perl_signature{
    printf "Perl %vd on %s\n", $^V, $Config{archname};
}

sub module_signature{
    my($name, $subr) = @_;
    my $cv = svref_2object($subr);

    printf "%s(%s)/%s\n", $name, $cv->XSUB ? 'XS' : 'PurePerl', $name->VERSION;
}

sub signature{
    my %mods = @_;
    perl_signature();

    while(my($name, $subr) = each %mods){
        module_signature($name => $subr);
    }

    print "\n";
}


if(grep { /^--pureperl$/ } @ARGV){
    no warnings 'redefine';
    *DynaLoader::bootstrap = sub{ die };
    *XSLoader::load        = sub{ die };
}
1;
