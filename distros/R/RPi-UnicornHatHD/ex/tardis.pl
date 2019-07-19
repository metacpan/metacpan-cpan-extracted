use strict;
use warnings;
use RPi::UnicornHatHD;
use Time::HiRes qw[sleep];

# Blue Box
my $display = RPi::UnicornHatHD->new();
$display->off;
$display->rotation(90);
#
$display->set_pixel(8, 0, 0,    0,    0xFF);
$display->set_pixel(8, 1, 0xFF, 0xFF, 0xFF);
$display->set_pixel($_, 2, 0, 0, 0xFF) for 6 .. 10;
$display->set_pixel($_, 3, 0, 0, 0xFF) for 4 .. 12;
$display->set_pixel($_, 4, 0, 0, 0xFF) for 4 .. 12;
{
    $display->set_pixel($_, 4, 0x22, 0x22, 0x22) for 5 .. 11;
}
$display->set_pixel($_, 5, 0, 0, 0xFF) for 4 .. 12;
{
    $display->set_pixel($_, 5, 0xFF, 0xFF, 0xFF) for 5 .. 7;
    $display->set_pixel($_, 5, 0xFF, 0xFF, 0xFF) for 9 .. 11;
}
$display->set_pixel($_, 6, 0, 0, 0xFF) for 4 .. 12;
{
    $display->set_pixel($_, 6, 0xFF, 0xFF, 0xFF) for 5 .. 7;
    $display->set_pixel($_, 6, 0xFF, 0xFF, 0xFF) for 9 .. 11;
}
$display->set_pixel($_, 7, 0, 0, 0xFF) for 4 .. 12;
{
    $display->set_pixel($_, 7, 0xFF, 0xFF, 0xFF) for 5 .. 7;
    $display->set_pixel($_, 7, 0xFF, 0xFF, 0xFF) for 9 .. 11;
}
$display->set_pixel($_, 8, 0, 0, 0xFF) for 4 .. 12;
$display->set_pixel($_, 9, 0, 0, 0xFF) for 4 .. 12;
{
    $display->set_pixel($_, 9, 0,    0,    0xFF) for 5 .. 7;
    $display->set_pixel($_, 9, 0,    0,    0x78) for 9 .. 11;
    $display->set_pixel($_, 9, 0xB4, 0xB4, 0xB4) for 5 .. 6;
}
$display->set_pixel($_, 10, 0, 0, 0xFF) for 4 .. 12;
{
    $display->set_pixel($_, 10, 0,    0,    0x78) for 5 .. 7;
    $display->set_pixel($_, 10, 0,    0,    0x78) for 9 .. 11;
    $display->set_pixel($_, 10, 0xB4, 0xB4, 0xB4) for 5 .. 6;
}
$display->set_pixel($_, 11, 0, 0, 0xFF) for 4 .. 12;
$display->set_pixel($_, 12, 0, 0, 0xFF) for 4 .. 12;
{
    $display->set_pixel($_, 12, 0, 0, 0x78) for 5 .. 7;
    $display->set_pixel($_, 12, 0, 0, 0x78) for 9 .. 11;
}
$display->set_pixel($_, 13, 0, 0, 0xFF) for 4 .. 12;
{
    $display->set_pixel($_, 13, 0, 0, 0x78) for 5 .. 7;
    $display->set_pixel($_, 13, 0, 0, 0x78) for 9 .. 11;
}
$display->set_pixel($_, 14, 0, 0, 0xFF) for 4 .. 12;
$display->set_pixel($_, 15, 0, 0, 0x78) for 3 .. 13;
{
    $display->set_pixel($_, 15, 0, 0, 0xFF) for 4 .. 12;
}

# $display->set_pixel($_, 16, 0, 0, 0xFF) for 7..9;
for my $brightness (0 .. 100) {
    $display->brightness($brightness / 100);
    $display->show;
    sleep 0.05;
}
for (1 .. 10) {
    for (reverse 0 .. 255) {
        $display->set_pixel(8, 1, $_, $_, $_);
        $display->show;
        sleep 0.001;
    }
    for (0 .. 255) {
        $display->set_pixel(8, 1, $_, $_, $_);
        $display->show;
        sleep 0.001;
    }
}
for my $brightness (reverse(0 .. 100)) {
    $display->brightness($brightness / 100);
    $display->show;
    sleep 0.05;
}

$display->off;
