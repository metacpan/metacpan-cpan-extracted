use strict;
use warnings;

use Test::More;

if ( $^O eq 'MSWin32' )
{
    plan skip_all => "Test gets stuck on Windows - RT #40771";
}
else
{
    plan tests => 1;
}

require Term::Shell;

{

    package Term::Shell::Test;
    use base 'Term::Shell';

    sub summary
    {
        my $self = shift;
        $::called = 1;
        $self->SUPER::summary(@_);
    }
    sub run_fuzz { }
};

my $sh = Term::Shell::Test->new;

{
    $sh->run_help;
};

unless ( is( $::called, 1, "catch_smry gets called for unknown methods" ) )
{
    diag "Term::Shell did not call a custom catch_smry handler";
    diag "This is most likely because your version of Term::Shell";
    diag "has a bug. Please upgrade to v0.02 or higher, which";
    diag "should close this bug.";
    diag "If that is no option, patch sub help() in Term/Shell.pm, line 641ff.";
    diag "to:";
    diag '      #my $smry = exists $o->{handlers}{$h}{smry};';
    diag '    #? $o->summary($h);';
    diag '    #: "undocumented";';
    diag '      my $smry = $o->summary($h);';
    diag 'Fixing this is not necessary - you will get no online help';
    diag 'but the shell will otherwise work fine. Help is still';
    diag 'available through ``perldoc WWW::Mechanize::Shell``';
}

