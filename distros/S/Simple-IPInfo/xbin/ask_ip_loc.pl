#!/usr/bin/perl
use JSON;
use Encode;
use Data::Validate::IP;
use FindBin;
$|=1;

our $DATA_DIR='data';

our $PRIVATE = { 
    country => '局域网',
    region => '局域网',
    isp => '局域网',
};

my ($i) = @ARGV;
$i = select_file_id() if(!$i);

write_ip_c($i);

sub write_ip_c {
	my ($i) = @_;
	print "$i\n";

	my $file = "$DATA_DIR/$i.csv";
	open my $fh,'>', "$file.temp";
	close $fh;

	open my $fh,'>>', "$file.temp";
	for my $j ( 0 .. 255 ){
        for my $k (0 .. 255){
            my $ip = "$i.$j.$k.1";
            print "\r$ip";
            if(is_public_ipv4($ip) ){
                my $r = ask_ip_taobao($ip);
                $r->{$_}=~s/,//g for keys(%$r);
                my $info =join(",","$i.$j.$k.0", @{$r}{qw/country region isp/});
                print $fh $info, "\n";
                sleep 3;
            }else{
                my $info =join(",","$i.$j.$k.0", @{$PRIVATE}{qw/country region isp/});
                print $fh $info, "\n";
            }
        }
	}
	close $fh;

	rename("$file.temp", $file);
	return $file;
}

sub ask_ip_taobao {
    my ($ip) = @_;

    for( 1 .. 5 ){
        my $url = "http://ip.taobao.com/service/getIpInfo.php?ip=$ip";
        my $c = `/usr/bin/curl -s "$url"`;
        my $r;
        eval {
            $r = decode_json($c);
        };
        unless($r){
            print "retry $ip\n";
            sleep 3;
            next;
        }
        my $h = $r->{data};
        $h->{$_} = encode( 'utf8' =>  $h->{$_}, Encode::FB_CROAK)
        for keys(%$h);
        return $h;
    }
}

sub select_file_id {
	my @files = map { $_->[0] } 
    grep { ! -f "$_->[0].temp" }
	sort { $a->[1] <=> $b->[1] } 
	map { [ $_, (stat($_))[9] ] } 
	glob("$DATA_DIR/*.csv");
	my $f = $files[0];
	my ($i) = $f=~m#$DATA_DIR/(\d+).csv#;
	return $i;
}
