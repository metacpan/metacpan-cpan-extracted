#!/usr/bin/perl
use utf8;
my ( $src, $dst ) = @ARGV;
open my $fhr, '<:utf8', $src;
open my $fh, '>:utf8', $dst;
while(<$fhr>){
    chomp;
    s///;
    my @data = split /,/, $_, -1;
    next unless($data[0] and $data[0]=~/^((\d+\.){3})\d+$/);

    for my $i ( 1 .. $#data){
        $data[$i] ||= '';
        $data[$i]=~s/,//g;
        $data[$i]=~s/，//g;
        $data[$i] =~ s/(西藏|内蒙古|宁夏|新疆|广西|香港).*/$1/;
        $data[$i] =~ s/省|市//;
        $data[$i] =~ s/教育网/教育/;
        $data[$i] =~ s/未知//;
    }

    $data[0]=~s/\.\d+$/.0/;
    print $fh join(",", @data),"\n";
}
close $fh;
close $fhr;
