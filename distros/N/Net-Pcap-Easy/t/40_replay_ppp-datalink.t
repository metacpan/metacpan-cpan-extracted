#!/usr/bin/perl

use strict;
use Net::Pcap::Easy;
use File::Slurp qw(slurp);

use Test;

plan tests => 1;

my $tcp = 0;

my $npe = Net::Pcap::Easy->new(
    dev              => "file:dat/ppp.data",
    promiscuous      => 0,
    packets_per_loop => 100,

    tcp_callback => sub {
        my ($npe, $ether, $tcp_) = @_;

        $tcp ++;
    },
);

$npe->loop;
ok( $tcp, 95 );

__END__
07:21:38.522269 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [S], seq 2303750417, win 5840, options [mss 1460,sackOK,TS val 11965914 ecr 0,nop,wscale 7], length 0
07:21:38.606192 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [S.], seq 846277038, ack 2303750418, win 5792, options [mss 1460,sackOK,TS val 388059457 ecr 11965914,nop,wscale 6], length 0
07:21:38.606229 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 1, win 46, options [nop,nop,TS val 11965923 ecr 388059457], length 0
07:21:38.700577 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 1:40, ack 1, win 91, options [nop,nop,TS val 388059482 ecr 11965923], length 39
07:21:38.700622 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 40, win 46, options [nop,nop,TS val 11965932 ecr 388059482], length 0
07:21:38.700718 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 1:40, ack 40, win 46, options [nop,nop,TS val 11965932 ecr 388059482], length 39
07:21:38.776202 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 40, win 91, options [nop,nop,TS val 388059500 ecr 11965932], length 0
07:21:38.776247 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 40:832, ack 40, win 46, options [nop,nop,TS val 11965939 ecr 388059500], length 792
07:21:38.776219 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 40:824, ack 40, win 91, options [nop,nop,TS val 388059500 ecr 11965932], length 784
07:21:38.816183 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 824, win 58, options [nop,nop,TS val 11965943 ecr 388059500], length 0
07:21:38.886188 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 832, win 116, options [nop,nop,TS val 388059528 ecr 11965939], length 0
07:21:38.886208 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 832:856, ack 824, win 58, options [nop,nop,TS val 11965950 ecr 388059528], length 24
07:21:38.966190 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 824:976, ack 856, win 116, options [nop,nop,TS val 388059547 ecr 11965950], length 152
07:21:38.966209 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 976, win 71, options [nop,nop,TS val 11965958 ecr 388059547], length 0
07:21:38.966957 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 856:1000, ack 976, win 71, options [nop,nop,TS val 11965958 ecr 388059547], length 144
07:21:39.076199 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 976:1696, ack 1000, win 140, options [nop,nop,TS val 388059573 ecr 11965958], length 720
07:21:39.077332 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 1000:1016, ack 1696, win 83, options [nop,nop,TS val 11965969 ecr 388059573], length 16
07:21:39.196189 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 1016, win 140, options [nop,nop,TS val 388059605 ecr 11965969], length 0
07:21:39.196211 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 1016:1064, ack 1696, win 83, options [nop,nop,TS val 11965981 ecr 388059605], length 48
07:21:39.276188 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 1064, win 140, options [nop,nop,TS val 388059625 ecr 11965981], length 0
07:21:39.276191 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 1696:1744, ack 1064, win 140, options [nop,nop,TS val 388059625 ecr 11965981], length 48
07:21:39.277523 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 1064:1128, ack 1744, win 83, options [nop,nop,TS val 11965990 ecr 388059625], length 64
07:21:39.396192 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 1128, win 140, options [nop,nop,TS val 388059655 ecr 11965990], length 0
07:21:39.646191 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 1744:1808, ack 1128, win 140, options [nop,nop,TS val 388059717 ecr 11965990], length 64
07:21:39.652193 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 1128:1768, ack 1808, win 83, options [nop,nop,TS val 11966027 ecr 388059717], length 640
07:21:39.733723 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 1768, win 165, options [nop,nop,TS val 388059739 ecr 11966027], length 0
07:21:39.733725 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 1808:1840, ack 1768, win 165, options [nop,nop,TS val 388059739 ecr 11966027], length 32
07:21:39.733914 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 1768:1896, ack 1840, win 83, options [nop,nop,TS val 11966035 ecr 388059739], length 128
07:21:39.846190 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 1896, win 190, options [nop,nop,TS val 388059768 ecr 11966035], length 0
07:21:40.374942 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 1840:1888, ack 1896, win 190, options [nop,nop,TS val 388059901 ecr 11966035], length 48
07:21:40.375075 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 1896:2344, ack 1888, win 83, options [nop,nop,TS val 11966099 ecr 388059901], length 448
07:21:40.443614 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 2344, win 215, options [nop,nop,TS val 388059918 ecr 11966099], length 0
07:21:40.443616 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 1888:2000, ack 2344, win 215, options [nop,nop,TS val 388059918 ecr 11966099], length 112
07:21:40.454943 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2000:2288, ack 2344, win 215, options [nop,nop,TS val 388059919 ecr 11966099], length 288
07:21:40.454983 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2288, win 95, options [nop,nop,TS val 11966107 ecr 388059918], length 0
07:21:40.715501 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2288:2400, ack 2344, win 215, options [nop,nop,TS val 388059985 ecr 11966107], length 112
07:21:40.755534 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2400, win 95, options [nop,nop,TS val 11966138 ecr 388059985], length 0
07:21:41.218740 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2344:2392, ack 2400, win 95, options [nop,nop,TS val 11966184 ecr 388059985], length 48
07:21:41.278731 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2392:2440, ack 2400, win 95, options [nop,nop,TS val 11966190 ecr 388059985], length 48
07:21:41.306195 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2400:2448, ack 2392, win 215, options [nop,nop,TS val 388060132 ecr 11966184], length 48
07:21:41.306217 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2448, win 95, options [nop,nop,TS val 11966192 ecr 388060132], length 0
07:21:41.356191 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2448:2496, ack 2440, win 215, options [nop,nop,TS val 388060147 ecr 11966190], length 48
07:21:41.356211 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2496, win 95, options [nop,nop,TS val 11966198 ecr 388060147], length 0
07:21:41.368712 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2440:2488, ack 2496, win 95, options [nop,nop,TS val 11966199 ecr 388060147], length 48
07:21:41.456190 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2496:2544, ack 2488, win 215, options [nop,nop,TS val 388060170 ecr 11966199], length 48
07:21:41.496179 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2544, win 95, options [nop,nop,TS val 11966211 ecr 388060170], length 0
07:21:41.807501 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2488:2536, ack 2544, win 95, options [nop,nop,TS val 11966243 ecr 388060170], length 48
07:21:41.906192 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2544:2592, ack 2536, win 215, options [nop,nop,TS val 388060282 ecr 11966243], length 48
07:21:41.906214 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2592, win 95, options [nop,nop,TS val 11966252 ecr 388060282], length 0
07:21:41.938719 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2536:2584, ack 2592, win 95, options [nop,nop,TS val 11966256 ecr 388060282], length 48
07:21:42.026191 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2592:2640, ack 2584, win 215, options [nop,nop,TS val 388060314 ecr 11966256], length 48
07:21:42.026216 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2640, win 95, options [nop,nop,TS val 11966264 ecr 388060314], length 0
07:21:42.026293 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2584:2632, ack 2640, win 95, options [nop,nop,TS val 11966264 ecr 388060314], length 48
07:21:42.106189 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2640:2688, ack 2632, win 215, options [nop,nop,TS val 388060335 ecr 11966264], length 48
07:21:42.156180 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2688, win 95, options [nop,nop,TS val 11966278 ecr 388060335], length 0
07:21:42.168717 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2632:2680, ack 2688, win 95, options [nop,nop,TS val 11966279 ecr 388060335], length 48
07:21:42.245331 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 2688:2736, ack 2680, win 215, options [nop,nop,TS val 388060370 ecr 11966279], length 48
07:21:42.245351 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 2736, win 95, options [nop,nop,TS val 11966287 ecr 388060370], length 0
07:21:42.406255 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 2736:4184, ack 2680, win 215, options [nop,nop,TS val 388060392 ecr 11966287], length 1448
07:21:42.406287 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 4184, win 118, options [nop,nop,TS val 11966302 ecr 388060392], length 0
07:21:42.406258 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 4184:5632, ack 2680, win 215, options [nop,nop,TS val 388060392 ecr 11966287], length 1448
07:21:42.406334 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 5632, win 140, options [nop,nop,TS val 11966302 ecr 388060392], length 0
07:21:42.406260 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 5632:6880, ack 2680, win 215, options [nop,nop,TS val 388060392 ecr 11966287], length 1248
07:21:42.406363 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 6880, win 163, options [nop,nop,TS val 11966302 ecr 388060392], length 0
07:21:42.406262 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 6880:8328, ack 2680, win 215, options [nop,nop,TS val 388060392 ecr 11966287], length 1448
07:21:42.406390 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 8328, win 186, options [nop,nop,TS val 11966302 ecr 388060392], length 0
07:21:42.406264 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 8328:9776, ack 2680, win 215, options [nop,nop,TS val 388060392 ecr 11966287], length 1448
07:21:42.406418 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 9776, win 208, options [nop,nop,TS val 11966302 ecr 388060392], length 0
07:21:42.546326 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 9776:10144, ack 2680, win 215, options [nop,nop,TS val 388060428 ecr 11966302], length 368
07:21:42.546365 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 10144, win 231, options [nop,nop,TS val 11966316 ecr 388060428], length 0
07:21:42.546328 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 10144:11592, ack 2680, win 215, options [nop,nop,TS val 388060428 ecr 11966302], length 1448
07:21:42.546409 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 11592, win 253, options [nop,nop,TS val 11966316 ecr 388060428], length 0
07:21:42.546330 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 11592:13040, ack 2680, win 215, options [nop,nop,TS val 388060428 ecr 11966302], length 1448
07:21:42.546435 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 13040, win 276, options [nop,nop,TS val 11966316 ecr 388060428], length 0
07:21:42.546333 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 13040:14488, ack 2680, win 215, options [nop,nop,TS val 388060428 ecr 11966302], length 1448
07:21:42.546463 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 14488, win 299, options [nop,nop,TS val 11966316 ecr 388060428], length 0
07:21:42.546335 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 14488:15936, ack 2680, win 215, options [nop,nop,TS val 388060428 ecr 11966302], length 1448
07:21:42.546489 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 15936, win 321, options [nop,nop,TS val 11966316 ecr 388060428], length 0
07:21:42.546337 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 15936:17384, ack 2680, win 215, options [nop,nop,TS val 388060428 ecr 11966302], length 1448
07:21:42.546513 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 17384, win 344, options [nop,nop,TS val 11966316 ecr 388060428], length 0
07:21:42.546339 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], seq 17384:18832, ack 2680, win 215, options [nop,nop,TS val 388060428 ecr 11966302], length 1448
07:21:42.546539 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 18832, win 367, options [nop,nop,TS val 11966316 ecr 388060428], length 0
07:21:42.546341 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 18832:19872, ack 2680, win 215, options [nop,nop,TS val 388060428 ecr 11966302], length 1040
07:21:42.546565 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 19872, win 389, options [nop,nop,TS val 11966316 ecr 388060428], length 0
07:21:43.005837 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2680:2728, ack 19872, win 389, options [nop,nop,TS val 11966363 ecr 388060428], length 48
07:21:43.094955 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 19872:20048, ack 2728, win 215, options [nop,nop,TS val 388060581 ecr 11966363], length 176
07:21:43.094985 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 20048, win 412, options [nop,nop,TS val 11966371 ecr 388060581], length 0
07:21:43.094957 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [P.], seq 20048:20112, ack 2728, win 215, options [nop,nop,TS val 388060581 ecr 11966363], length 64
07:21:43.095046 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 20112, win 412, options [nop,nop,TS val 11966371 ecr 388060581], length 0
07:21:43.095191 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2728:2760, ack 20112, win 412, options [nop,nop,TS val 11966371 ecr 388060581], length 32
07:21:43.095241 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [P.], seq 2760:2824, ack 20112, win 412, options [nop,nop,TS val 11966371 ecr 388060581], length 64
07:21:43.095309 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [F.], seq 2824, ack 20112, win 412, options [nop,nop,TS val 11966371 ecr 388060581], length 0
07:21:43.176193 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [.], ack 2825, win 215, options [nop,nop,TS val 388060600 ecr 11966371], length 0
07:21:43.176195 IP 10.1.1.2.ssh > 10.1.1.1.57398: Flags [F.], seq 20112, ack 2825, win 215, options [nop,nop,TS val 388060600 ecr 11966371], length 0
07:21:43.176237 IP 10.1.1.1.57398 > 10.1.1.2.ssh: Flags [.], ack 20113, win 412, options [nop,nop,TS val 11966379 ecr 388060600], length 0
