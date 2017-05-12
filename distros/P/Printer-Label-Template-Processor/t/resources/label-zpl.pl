# template étiquette colis

my $zpl = "";
my $vars = $self->{vars};

# entête
$zpl .= "^XA\n";
$zpl .= "^CI27\n";      # CodePage 1252
$zpl .= "^MUM\n";       # unité mm

# cadre
$zpl .= "^FO2,2^GB80,135,0.2,B,1^FS\n";

# adresse expéditeur
{
    my $count = 0;
    foreach my $line (@{$vars->{adr_exp}}) {
        my $y = 4+2.5*$count;
        $zpl .= "^FO12,$y^APN^FD$line^FS\n" if $line;
        $count += 1;
    }
}

# bloc code barres produit
{
    my $h_code_set = { B => ':', C => ';'};
    my $start_code = $h_code_set->{$vars->{code_set}};
    $start_code or die "Type de code barres inconnu";
    my $yb = 7+12*length($vars->{produit_codealpha});
    my $yt = $yb + ($vars->{mode_exp} =~ /ETR$/ ? 10 : 2);
    $zpl .= "^FO62.5,4^AGR,18,12^FD$vars->{produit_codealpha}^FS\n";
    $zpl .= "^FO66,$yb^BCR,10,N,N,N,N^FD>$start_code$vars->{n_ext_envoi}^FS\n";
    $zpl .= "^FO62,$yt^ADR^FD$vars->{n_ext_envoi_dot}^FS\n";
    $zpl .= "^FO77,$yb^ADR^FD$vars->{post_office}^FS\n" if !($vars->{mode_exp} =~ /ETR$/);
}

# bloc code barres prestation complémentaire
 if ($vars->{prest_compl_codealpha}) {
    $zpl .= "^FO71,80^ATR^FD$vars->{prest_compl_codealpha}^FS\n";
    $zpl .= "^FO56,80^BCN,10,N,N,N,N^FD>;$self->{prest_compl_codenum}^FS\n";
}

# adresse destinataire
{
    my $count = 0;
    foreach my $line (@{$vars->{adr_dest}}) {
        my $x = 42.5-3.75*$count;
        $zpl .= "^FO$x,26.25^ARR^FD$line^FS\n" if $line;
        $count += 1;
    }
}

# footer
$zpl .= "^XZ";

return $zpl;
