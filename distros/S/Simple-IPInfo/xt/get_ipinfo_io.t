sub get_ipinfo_io {
    my ($ip) = @_;
    my $s = `curl -s ipinfo.io/$ip/json`;
    my $r = decode_json $s;

    my ($asn, $isp)= $r->{org}=~m#AS(\d+)\s*(.*)#;
    if($r->{country} eq 'CN'){
        $isp = $isp=~/\bTelecom\b/ ? '电信' : 
        $isp=~/\bCNCGROUP\b/ ?  '联通' :
        $isp=~/\bTieTong\b/ ? '铁通':
        $isp=~/\bEducation\b/ ? '教育' :
        $isp=~/\bMobile Communication\b/ ? '移动' : $isp;
    }

    $r = {
        ip => $r->{ip}, 
        loc => $r->{loc}, 
        country => $r->{country}, 
        isp => $isp, 
        as => $asn, 
    };
    return $r;
}
