#!/usr/bin/perl
#ip as info is from: ftp://routeviews.org/dnszones/originas.bz2
use Net::CIDR qw/cidr2range/;
use Socket qw/inet_aton/;
use SimpleR::Reshape;
use Data::Dumper;

my ($dst) = @ARGV;
$dst ||= 'inet_as.csv';

system("curl ftp://routeviews.org/dnszones/originas.bz2 -o originas.bz2");
system("bunzip2 -f originas.bz2");
my $in_file = 'originas';

my $temp = "$in_file.inet";
parse_raw_file($in_file, $temp);
system(qq[sort -t, -k1,1 -n $temp | uniq > $temp.sort]);
system(qq[refine_inet.pl $temp.sort $dst.clean]);

fix_gap_as("$dst.clean", $dst);

#unlink($temp);
#unlink("$temp.sort");

sub fix_gap_as {
    my ( $raw, $dst ) = @_;
    open my $fh,  '<', $raw;
    open my $fhw, '>', $dst;
    my $head=<$fh>;
    chomp($head);
    my ($s, $e, $d) = split /,/, $head;
    while (<$fh>) {
        chomp;
        my ($ss, $ee, $dd) = split /,/;
        if($dd ne $d){
            print $fhw join(",", $s, $e, $d),"\n";
            ($s, $e, $d) = ($ss, $ee, $dd);
        }else{
            ($s, $e, $d) = ($s, $ee, $d);
        }
    }
    print $fhw join(",", $s, $e, $d),"\n";
    close $fhw;
    close $fh;
    return $dst;
}

sub parse_raw_file {
    my ( $raw, $temp ) = @_;
    open my $fh,  '<', $raw;
    open my $fhw, '>', $temp;
    print $fhw "s,e,as\n";
    while (<$fh>) {
        my $rr = extract_asn_line($_);
        print $fhw join(",", @$rr),"\n";
    }
    close $fhw;
    close $fh;
    return $temp;
}

sub extract_asn_line {
    my ($line) = @_;
    chomp $line;

    my @data = split /\s+/, $line;
    s/"//g for @data;
    my @r = cidr2range("$data[-2]/$data[-1]");
    #print Dumper(\@r);
    my ( $s_ip, $e_ip ) = $r[0] =~ /(.+?)-(.+)/;
    my ( $s_inet, $e_inet ) = map { unpack( 'N', inet_aton($_) ) } ( $s_ip, $e_ip );

    $data[-3]=~s/[\{\}"]//sg;
    $data[-3]=~s/,.*//; # { n, m } only extract n
    return [ $s_inet, $e_inet, $data[-3] ] ;
}
