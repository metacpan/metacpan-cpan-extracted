use strict;
use warnings;
no warnings 'uninitialized';

use Test::More tests => 4 ;

diag( "Testing Printer::Label::Template::Processor $Printer::Label::Template::Processor::VERSION, Perl $], $^X" );

BEGIN {use_ok("Printer::Label::Template::Processor");}

sub _check_syntax_zpl {
    my $zpl_code = shift;

    # vérifie la présence des commandes start/stop
    return ($zpl_code =~ /^\^XA(.*\s)*\^XZ.*\s*/);
}

my $print_con = Printer::Label::Template::Processor->new(
    script_file   => "t/resources/label-zpl.tt2",
    print_mode    => "CON",
    check_syntax  => \&_check_syntax_zpl,
);
isa_ok($print_con, 'Printer::Label::Template::Processor', '$print_con');

$print_con->printout(
    vars => {
        c_ori_dest         => "DEST",
        code_set           => "C",
        licence_affranchis => "12300045",
        n_envoi            => "10002345",
        n_ext_envoi        => "981230004510002345",
        n_ext_envoi_dot    => "98.12300045.10002345",
        post_office        => "1211 GENEVE 3",
        produit_cle        => "REC",
        produit_codealpha  => "R",
        produit_libelle    => "Recommandé suisse",
        type_envoi         => "Envoi de type Lettre",
        type_envoi_codenum => "98",
        mode_exp           => "LETTRE_REC",
        adr_exp            => ["Alexa Workman", "Place Blandin 14", "CH-1211 Genève 3"],
        adr_dest           => ["Anne Beard", "Avenue Drake 12", "CH-1209 Genève"],
    }
);
cmp_ok(length($print_con->{output_data}), '>', 0, "label content is not empty");
ok(_check_syntax_zpl($print_con->{output_data}), "ZPL syntax is valid");

