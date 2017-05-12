#!/usr/bin/perl -w
use strict;
use Test::More;
use Mobile::UserAgent;

my @lines = <DATA>;
plan('tests' => scalar(@lines));
foreach my $line (@lines) {
 chomp($line);
 my $o = new Mobile::UserAgent($line);
 if ($o->success()) {
  ok(defined($o->vendor()) && defined($o->model()));
 }
 else {
  ok(0);
 }
}

__DATA__
ACER-Pro80/1.02 UP/4.1.20i UP.Browser/4.1.20i-XXXX
AUDIOVOX-9155GPX/07.13 UP.Browser/4.1.26c3
AUDIOVOX-CDM9100/05.89 UP.Browser/4.1.24c UP.Link/5.0.2.7a
AUDIOVOX-CDM9500/111.030 UP.Browser/5.0.4.1 (GUI)
AUDIOVOX-CDM9500/111.030 UP.Browser/5.0.4.1 (GUI) UP.Link/5.1.2.3
Alcatel-BE3/1.0 UP/4.1.8d
Alcatel-BE3/1.0 UP/4.1.8d UP.Browser/4.1.8d-XXXX UP.Link/5.1.1.5
Alcatel-BE3/1.0 UP/4.1.8h
Alcatel-BE4/1.0 UP/4.1.16f
Alcatel-BE4/1.0 UP/4.1.16m
Alcatel-BE4/1.0 UP/4.1.19e
Alcatel-BE4/1.0 UP/4.1.19e UP.Browser/4.1.19e-XXXX UP.Link/4.2.2.1
Alcatel-BE4/2.0 UP/4.1.19e
Alcatel-BE4/2.0 UP/4.1.19e UP.Browser/4.1.19e-XXXX UP.Link/4.2.2.1
Alcatel-BE4/2.0 UP/4.1.19e UP.Browser/4.1.19e-XXXX UP.Link/5.1.1.3
Alcatel-BE5/1.0 UP/4.1.19e
Alcatel-BE5/1.0 UP/4.1.19e UP.Browser/4.1.19e-XXXX UP.Link/4.2.2.1
Alcatel-BE5/1.5 UP/4.1.19e
Alcatel-BE5/1.5 UP/4.1.19e UP.Browser/4.1.19e-XXXX UP.Link/4.2.2.1
Alcatel-BE5/2.0 UP.Browser/4.1.21d
Alcatel-BE5/2.0 UP/4.1.19e
Alcatel-BE5/2.0 UP/4.1.19e UP.Browser/4.1.19e-XXXX UP.Link/4.2.2.1
Alcatel-BF3/1.0 UP.Browser/4.1.23a
Alcatel-BF3/1.0 UP.Browser/4.1.23a UP.Link/4.2.2.1
Alcatel-BF3/1.0 UP.Browser/4.1.23a UP.Link/5.01
Alcatel-BF3/1.0 UP.Browser/4.1.23a UP.Link/5.1.0.2
Alcatel-BF3/1.0 UP.Browser/4.1.23a UP.Link/5.1.1.3
Alcatel-BF4/1.0 UP.Browser/4.1.23a
Alcatel-BF4/1.0 UP.Browser/4.1.23a UP.Link/4.2.2.1
Alcatel-BF4/1.0 UP.Browser/4.1.23a UP.Link/5.1.1.3
Alcatel-BF4/2.0 UP.Browser/5.0.1.10
Alcatel-BF4/2.0 UP.Browser/5.0.1.10.1
Alcatel-BF4/2.0 UP.Browser/5.0.1.10.1 UP.Link/5.1.1.2a
Alcatel-BF4/2.0 UP.Browser/5.0.1.5
Alcatel-BF4/2.0 UP.Browser/5.0.1.8.100
Alcatel-BF4/2.0 UP.Browser/5.0.1.8.100 UP.Link/4.2.2.1
Alcatel-BF5/1.0 UP.Browser/4.1.23a
Alcatel-BF5/1.0 UP.Browser/5.0.2.1.100
Alcatel-BF5/1.0 UP.Browser/5.0.2.1.103
Alcatel-BF5/1.0 UP.Browser/5.0.3
Alcatel-BF5/1.0 UP.Browser/5.0.3 UP.Link/4.2.2.1
Alcatel-BF5/1.0 UP.Browser/5.0.3.1
Alcatel-BF5/1.0 UP.Browser/5.0.3.1 UP.Link/5.1.1.5a
Alcatel-BF5/1.0 UP.Browser/5.0.3.1 UP.Link/5.1.2.3
Alcatel-BF5/1.0 UP.Browser/5.0.3.1.2
Alcatel-BF5/1.0 UP.Browser/5.0.3.1.2 UP.Link/4.2.0.1
Alcatel-BF5/1.0 UP.Browser/5.0.3.1.2 UP.Link/5.1.1.2a
Alcatel-BF5/1.0 UP.Browser/5.0.3.521
Alcatel-BG3-color/1.0 UP.Browser/5.0.3.3.11
Alcatel-BG3/1.0 UP.Browser/5.0.3
Alcatel-BG3/1.0 UP.Browser/5.0.3 UP.Link/4.2.2.1
Alcatel-BG3/1.0 UP.Browser/5.0.3.1
Alcatel-BG3/1.0 UP.Browser/5.0.3.1.2
Alcatel-BG3/1.0 UP.Browser/5.0.3.1.2 UP.Link/4.2.1.2
Alcatel-BG3/1.0 UP.Browser/5.0.3.1.2 UP.Link/4.2.2.1
Alcatel-BG3/1.0 UP.Browser/5.0.3.1.2 UP.Link/5.1.1.5a
Alcatel-BG3/1.0 UP.Browser/5.0.3.3.11
Alcatel-BG3/1.0 UP.Browser/5.0.3.3.11 UP.Link/5.1.1.5
Alcatel-BG3/1.0 UP.Browser/5.0.3.3.11 UP.Link/5.1.2.3
Alcatel-BG3/1.0 UP.Browser/5.0.3.x
Alcatel-BH4/1.0 UP.Browser/6.1.0.4.123 (GUI) MMP/1.0
Alcatel-BH4/1.0 UP.Browser/6.1.0.5 (GUI) MMP/1.0
Alcatel-BH4/1.0 UP.Browser/6.1.0.6.1 (GUI)+JPEG Patch MMP/1.0
Alcatel-BH4/1.0 UP.Browser/6.2.ALCATEL MMP/1.0
Alcatel-BH4/1.0 UP.Browser/6.2.ALCATEL MMP/1.0 UP.Link/5.01
Alcatel-BH4R/1.0 UP.Browser/6.2.ALCATEL MMP/1.0
Alcatel-TH3/1.0 UP.Browser/6.2.ALCATEL MMP/1.0
Alcatel-TH4/1.0 UP.Browser/6.2.ALCATEL MMP/1.0
BlackBerry5820/3.6.0
BlackBerry6210/3.6.0
BlackBerry6210/3.6.0 UP.Link/5.1.2.1
BlackBerry6710/3.6.0
BlackBerry7230/3.7.0
CDM-8150/P15 UP.Browser/4.1.26c4 UP.Link/4.3.3.4
CDM-8150/P15 UP.Browser/4.1.26c4 UP.Link/4.3.3.4a
CDM-8300/T10 UP.Browser/4.1.26l UP.Link/4.3.3.4
CDM-8300/T10 UP.Browser/4.1.26l UP.Link/4.3.4.4d
DoCoMo/1.0/D209i
DoCoMo/1.0/D209i/c10
DoCoMo/1.0/D210i/c10
DoCoMo/1.0/D211i/c10
DoCoMo/1.0/D501i
DoCoMo/1.0/D502i
DoCoMo/1.0/D502i/c10
DoCoMo/1.0/D503i/c10
DoCoMo/1.0/D503iS/c10
DoCoMo/1.0/ER209i
DoCoMo/1.0/ER209i/c15
DoCoMo/1.0/F209i
DoCoMo/1.0/F209i/c10
DoCoMo/1.0/F210i/c10
DoCoMo/1.0/F211i/c10
DoCoMo/1.0/F501i
DoCoMo/1.0/F502i
DoCoMo/1.0/F502i/c10
DoCoMo/1.0/F502it
DoCoMo/1.0/F502it/c10
DoCoMo/1.0/F503i/c10
DoCoMo/1.0/F503iS/c10
DoCoMo/1.0/F671i/c10
DoCoMo/1.0/KO209i
DoCoMo/1.0/KO210i
DoCoMo/1.0/KO210i/c10
DoCoMo/1.0/N209i
DoCoMo/1.0/N209i/c08
DoCoMo/1.0/N210i
DoCoMo/1.0/N210i/c10
DoCoMo/1.0/N211i/c10
DoCoMo/1.0/N501i
DoCoMo/1.0/N502i
DoCoMo/1.0/N502i/c08
DoCoMo/1.0/N502it
DoCoMo/1.0/N502it/c10
DoCoMo/1.0/N503i/c10
DoCoMo/1.0/N503iS/c10
DoCoMo/1.0/N821i
DoCoMo/1.0/N821i/c08
DoCoMo/1.0/NM502i
DoCoMo/1.0/NM502i/c10
DoCoMo/1.0/P209i
DoCoMo/1.0/P209i/c10
DoCoMo/1.0/P209is
DoCoMo/1.0/P209is/c10
DoCoMo/1.0/P210i
DoCoMo/1.0/P210i/c10
DoCoMo/1.0/P211i/c10
DoCoMo/1.0/P501i
DoCoMo/1.0/P502i
DoCoMo/1.0/P502i/c10
DoCoMo/1.0/P502i/c10 (Google CHTML Proxy/1.0)
DoCoMo/1.0/P503i/c10
DoCoMo/1.0/P503iS/c10
DoCoMo/1.0/P821i
DoCoMo/1.0/P821i/c08
DoCoMo/1.0/R209i
DoCoMo/1.0/R691i
DoCoMo/1.0/R691i/c10
DoCoMo/1.0/SH505iS/c20/TB/W24H12
DoCoMo/1.0/SH821i
DoCoMo/1.0/SH821i/c10
DoCoMo/1.0/SO210i/c10
DoCoMo/1.0/SO502i
DoCoMo/1.0/SO502iWM/c10
DoCoMo/1.0/SO503i/c10
DoCoMo/1.0/SO503iS/c10
DoCoMo/1.0/SO505i/c20/TB/W21H09
DoCoMo/2.0 D2101V(c100)
DoCoMo/2.0 N2001(c10)
DoCoMo/2.0 N2002(c100)
DoCoMo/2.0 P2101V(c100)
EricssonA2618s/R1A
EricssonA2628s/R2A
EricssonR320/R1A
EricssonR320/R1A (Fast WAP Crawler)
EricssonR320/R1A UP.Link/4.1.0.1 (Fast Mobile Crawler)
EricssonR520/R1A
EricssonR520/R1A UP.Link/4.3.2.1
EricssonR520/R201
EricssonR520/R201 UP.Link/4.3.2.1
EricssonR520/R202
EricssonR520/R202 UP.Link/4.3.2.1
EricssonR520/R202 UP.Link/5.1.1.2a
EricssonR520/R202 UP.Link/5.1.2.4
EricssonT20/R2A
EricssonT20/R2A UP.Link/4.1.0.9b
EricssonT20/R2A UP.Link/4.2.2.1
EricssonT20/R2A UP.Link/5.02
EricssonT20/R2A UP.Link/5.1.1.3
EricssonT200/R101
EricssonT200/R101 UP.Link/5.1.1.5a
EricssonT39/R201
EricssonT39/R201 UP.Link/4.2.2.1
EricssonT39/R201 UP.Link/4.3.2.1
EricssonT39/R201 UP.Link/5.1.1.2a
EricssonT39/R201 UP.Link/5.1.1.4
EricssonT39/R201 UP.Link/5.1.1.5
EricssonT39/R202
EricssonT39/R202 UP.Link/4.2.2.1
EricssonT39/R202 UP.Link/4.3.2.1
EricssonT39/R202 UP.Link/5.0
EricssonT39/R202 UP.Link/5.1.0.2
EricssonT39/R202 UP.Link/5.1.1.2a
EricssonT39/R202 UP.Link/5.1.1.4
EricssonT39/R202 UP.Link/5.1.2.4
EricssonT65/R101
EricssonT65/R101 UP.Link/4.2.0.1
EricssonT65/R101 UP.Link/4.2.1.8
EricssonT65/R101 UP.Link/4.2.2.1
EricssonT65/R101 UP.Link/4.2.3.3
EricssonT65/R101 UP.Link/4.3.2.1
EricssonT65/R101 UP.Link/4.3.2.4
EricssonT65/R101 UP.Link/5.1.1
EricssonT65/R101 UP.Link/5.1.1.2a
EricssonT65/R101 UP.Link/5.1.1.4
EricssonT65/R101 UP.Link/5.1.1.5a
EricssonT65/R101 UP.Link/5.1.2.4
EricssonT68
EricssonT68/R101
EricssonT68/R101 (;; ;; ;; ;)
EricssonT68/R101 (;; ;; ;; Smartphone; 176x220)
EricssonT68/R101 (Google WAP Proxy/1.0)
EricssonT68/R101 UP.Link/1.1
EricssonT68/R101 UP.Link/4.2.2.1
EricssonT68/R101 UP.Link/4.2.2.5
EricssonT68/R101 UP.Link/4.2.3.3
EricssonT68/R101 UP.Link/4.3.2.1
EricssonT68/R101 UP.Link/4.3.2.4
EricssonT68/R101 UP.Link/5.0.1.1
EricssonT68/R101 UP.Link/5.01
EricssonT68/R101 UP.Link/5.1.0.1
EricssonT68/R101 UP.Link/5.1.1.4
EricssonT68/R101 UP.Link/5.1.1.5a
EricssonT68/R101 UP.Link/5.1.2.3
EricssonT68/R101 UP.Link/5.1.2.4
EricssonT68/R101-WG
EricssonT68/R1A
EricssonT68_NIL
LG G8000/1.0 PDK/2.5
LG G8000/1.0 PDK/2.5 UP.Link/5.1.0.2
LG-C1200 MIC/WAP2.0 MIDP-2.0/CLDC-1.0
LG-C1200 MIC/WAP2.0 MIDP-2.0/CLDC-1.0 UP.Link/5.1.2.10
LG-C3100 AU/4.10 Profile MIDP-1.0 Configuration CLDC-1.0
LG-G510 AU/4.2
LG-G510 AU/4.2 UP.Link/5.1.1.5
LG-G5200
LG-G5200 UP.Link/5.1.2.3
LG-G5300 AU/4.10
LG-G5300 AU/4.10 UP.Link/5.1.1.5a
LG-G5300i/JM AU/4.10 Profile/MIDP-1.0 Configuration/CLDC-1.0
LG-G5400 AU/4.10 Profile/MIDP-1.0 Configuration/CLDC-1.0
LG-G5400 AU/4.10 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
LG-G7000 AU/4.10
LG-G7020
LG-G7050 UP.Browser/6.2.2 (GUI) MMP/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
LG-G7100 AU/4.10 Profile/MIDP-1.0 Configuration/CLDC-1.0
LG-G7100 AU/4.10 Profile/MIDP-2.0 Configuration/CLDC-1.0
LG-G7200 UP.Browser/6.2.2 (GUI) MMP/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
LGE-CU8080/1.0 UP.Browser/4.1.26l UP.Link/5.1.1.5c
LGE-DB520/1.0 UP.Browser/4.1.22b1
LGE-DB525/1.0 UP.Browser/4.1.24f UP.Link/5.0.2.8
LGE-DM310/1.0 UP.Browser/4.1.26l UP.Link/4.3.2.4
LGE-DM310/1.0 UP.Browser/4.1.26l UP.Link/4.3.4.1
LGE-DM515H/1.0 UP.Browser/4.1.22b UP.Link/4.3.2.4
LGE-LX5350/1.0 UP.Browser/6.1.0.2.135 (GUI) MMP/2.0
LGE-TM540C/1.0 UP.Browser/4.1.26l
LGE-TM540C/1.0 UP.Browser/4.1.26l UP.Link/5.1.2.3
LGE/U8150/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0
LGE510W-V137-AU4.2
MOT-2000./10.01 UP/4.1.21b
MOT-2000./10.01 UP/4.1.21b UP.Browser/4.1.21b-XXXX UP.Link/4.2.1.8
MOT-2100./11.03 UP.Browser/4.1.24f
MOT-2100./11.03 UP.Browser/4.1.24f UP.Link/4.3.3.4
MOT-2100./11.03 UP.Browser/4.1.25i UP.Link/5.0.2.7a
MOT-2102./11.03 UP.Browser/4.1.24f
MOT-2200./11.03 UP.Browser/4.1.25i UP.Link/4.2.1.8
MOT-2200./11.03 UP.Browser/4.1.25i UP.Link/5.1.0.1
MOT-2200./11.03 UP.Browser/4.1.25i UP.Link/5.1.2.3
MOT-28/04.02 UP/4.1.17r
MOT-28/04.04 UP/4.1.17r UP.Browser/4.1.17r-XXXX UP.Link/4.3.3.4
MOT-32/00.03 UP/4.1.21b UP.Browser/4.1.21b-XXXX UP.Link/4.3.1.1
MOT-32/01.00 UP.Browser/4.1.23
MOT-32/01.00 UP.Browser/4.1.23 UP.Link/4.2.3.5c
MOT-40/04.04 UP/4.1.17r
MOT-43/04.05 UP/4.1.17r
MOT-61/04.02 UP/4.1.17r
MOT-61/04.02 UP/4.1.17r UP.Browser/4.1.17r-XXXX UP.Link/4.3.4.4
MOT-61/04.05 UP/4.1.17r UP.Browser/4.1.17r-XXXX UP.Link/4.3.2.1
MOT-62/04.05 UP/4.1.17r UP.Browser/4.1.17r-XXXX
MOT-62/04.05 UP/4.1.17r UP.Browser/4.1.17r-XXXX UP.Link/4.3.4.4
MOT-70/00.01 UP/4.1.21b
MOT-76/00.01 UP.Browser/4.1.23
MOT-76/00.01 UP.Browser/4.1.23 UP.Link/4.3.4.4
MOT-76/01.01 UP.Browser/4.1.26m.737 UP.Link/4.2.3.5c
MOT-76/02.01 UP.Browser/4.1.26m.737 UP.Link/4.2.3.5c
MOT-76/02.01 UP.Browser/4.1.26m.737 UP.Link/4.3.3.4
MOT-820/00.00.00 MIB/2.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-8300_/11.03 UP.Browser/4.1.25i UP.Link/5.1.1a
MOT-85/00.00 UP.Browser/4.1.26m.737 UP.Link/4.2.3.5c
MOT-85/01.00 UP.Browser/4.1.26m.737 UP.Link/4.2.3.5c
MOT-85/01.01 UP.Browser/4.1.26m.737 UP.Link/4.2.3.5c
MOT-A-88/01.02 UP.Browser/4.1.26m.737 UP.Link/4.2.3.5c
MOT-A-88/01.04 UP.Browser/4.1.26m.737 UP.Link/4.2.3.5c
MOT-A835/72.32.05I MIB/2.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
MOT-AF/0.0.22 UP/4.0.5n
MOT-AF/4.1.8 UP/4.1.16s
MOT-AF/4.1.9 UP.Browser/4.1.23c
MOT-AF/4.1.9 UP.Browser/4.1.23c UP.Link/4.2.1.8
MOT-AF/4.1.9 UP.Browser/4.1.23c UP.Link/4.3.2.1
MOT-AF/4.1.9 UP.Browser/4.1.23c UP.Link/5.1.2.4
MOT-AF/4.1.9 UP/4.1.19i
MOT-AF/4.1.9 UP/4.1.19i UP.Browser/4.1.19i-XXXX UP.Link/4.2.2.1
MOT-AF/4.1.9 UP/4.1.19i UP.Browser/4.1.19i-XXXX UP.Link/4.2.2.9
MOT-AF/4.1.9 UP/4.1.19i UP.Browser/4.1.19i-XXXX UP.Link/5.1.1
MOT-BC/4.1.9 UP.Browser/4.1.23
MOT-C2/4.1.8 UP/4.1.16s
MOT-C350M/G_09.04.23R MIB/2.0
MOT-C350M/G_09.04.23R MIB/2.0-WG
MOT-C350M/G_09.04.24R MIB/2.0
MOT-C385/0B.D1.09R MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-C4/0.0.21 UP/4.0.5m
MOT-C4/0.0.23 UP/4.0.5o
MOT-C4/0.0.23 UP/4.0.5o UP.Browser/4.0.5o-XXXX UP.Link/4.2.2.1
MOT-C4/4.1.5 UP/4.1.16f
MOT-C4/4.1.6 UP/4.1.16g
MOT-C4/4.1.8 UP/4.1.16s
MOT-C4/4.1.8 UP/4.1.16s UP.Browser/4.1.16s-XXXX UP.Link/5.0
MOT-C4/4.1.9 UP/4.1.16s
MOT-C4/4.1.9 UP/4.1.19i
MOT-C650/0B.D0.1FR MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Link/1.1
MOT-CB/0.0.18 UP/4.1.20a UP.Browser/4.1.20a-XXXX UP.Link/4.1.HTTP-DIRECT
MOT-CB/0.0.19 UP/4.0.5j UP.Browser/4.0.5j-XXXX UP.Link/5.1.1.3
MOT-CB/0.0.21 UP/4.0.5m
MOT-CB/0.0.23 UP/4.0.5o
MOT-CB/0.0.23 UP/4.0.5o UP.Browser/4.0.5o-XXXX UP.Link/4.2.2.1
MOT-CB/4.1.5 UP/4.1.16f
MOT-CB/4.1.6 UP/4.1.16g
MOT-CB/4.1.6+UP/4.1.16g
MOT-CB/4.1.6+UP/4.1.16g UP.Link/4.2.2.1
MOT-CB/4.1.7 UP/4.1.16p
MOT-CF/00.12.13 UP/4.1.9m
MOT-CF/00.26.31 UP/4.1.16f
MOT-D1/0.0.22 UP/4.0.5n
MOT-D3/0.0.22 UP/4.0.5n
MOT-D4/4.1.4 UP/4.1.16a
MOT-D4/4.1.5 UP/4.1.16f
MOT-D4/4.1.8 UP/4.1.16s
MOT-D5/0.0.22 UP/4.0.5n
MOT-D5/4.1.5 UP.Browser/4.1.23c
MOT-D5/4.1.5 UP.Browser/4.1.23c UP.Link/4.2.2.1
MOT-D5/4.1.5 UP.Browser/4.1.23c UP.Link/5.0.1.1
MOT-D5/4.1.5 UP.Browser/4.1.23c UP.Link/5.01
MOT-D5/4.1.5 UP/4.1.20i
MOT-D5/5.0.2 UP.Browser/5.0.2.3 (GUI)
MOT-D5/5.0.2 UP.Browser/5.0.2.3 (GUI) UP.Link/5.1.1a
MOT-D8/4.1.8 UP/4.1.16s
MOT-D8/4.1.9 UP.Browser/4.1.23
MOT-D8/4.1.9 UP/4.1.19i
MOT-DC/4.1.9 UP/4.1.19i
MOT-DD/0.0.22 UP/4.0.5n
MOT-DF/0.0.22 UP/4.0.5n
MOT-E380/0A.03.29R MIB/2.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
MOT-E380/0A.04.02I MIB/2.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-F0/4.1.8 UP.Browser/4.1.23
MOT-F0/4.1.8 UP.Browser/4.1.23 UP.Link/4.2.2.1
MOT-F0/4.1.8 UP.Browser/4.1.23 UP.Link/5.1.1a
MOT-F0/4.1.8 UP/4.1.16s
MOT-F0/4.1.9 UP.Browser/4.1.23
MOT-F0/4.1.9 UP.Browser/4.1.23 UP.Link/4.2.2.1
MOT-F4/4.1.7 UP/4.1.16p
MOT-F5 4.1.9 UP.Browser
MOT-F5/4.1.9 UP.Browser/4.1.23c
MOT-F5/4.1.9 UP.Browser/4.1.23c UP.Link/5.1.0.2
MOT-F5/4.1.9 UP.Browser/4.1.23c UP.Link/5.1.1.4
MOT-F6/10.36.32 UP.Browser/4.1.23d
MOT-F6/10.36.32 UP.Browser/4.1.23d UP.Link/4.2.2.1
MOT-F6/10.36.32 UP.Browser/4.1.23i
MOT-F6/10.36.32 UP.Browser/4.1.23i UP.Link/4.2.0.1
MOT-FE/20.16.13 UP.Browser/4.1.23i
MOT-P2K-C/10.01 UP/4.1.21b
MOT-P2K-T/13.02 UP.Browser/4.1.25i UP.Link/5.1.2.1
MOT-P2K-T/14.02 UP.Browser/4.1.25i UP.Link/5.1.2.1
MOT-PAN4_/11.03 UP.Browser/4.1.23c
MOT-PHX4_/11.03 UP.Browser/4.1.23c
MOT-PHX4_/11.03 UP.Browser/4.1.23c UP.Link/5.1.1.4
MOT-PHX4_/11.03 UP.Browser/4.1.23c UP.Link/5.1.1a
MOT-PHX4_/11.03 UP.Browser/4.1.23c UP.Link/5.1.2.2
MOT-PHX8/02.27.00.n1 MIB/1.2
MOT-PHX8A/11.03 UP.Browser/4.1.23c
MOT-SAP4H/11.03 UP.Browser/4.1.23c
MOT-SAP4_/11.03 UP.Browser/4.1.23c
MOT-SAP4_/11.03 UP.Browser/4.1.23c UP.Link/4.2.2.1
MOT-SAP4_/11.03 UP.Browser/4.1.23c UP.Link/5.1.1.4
MOT-SAP4_/11.03 UP.Browser/4.1.23c UP.Link/5.1.2.2
MOT-SAP4_/11.03 UP.Browser/4.1.23c UP.Link/5.1.2.5
MOT-SAP8A/11.03 UP.Browser/4.1.23c
MOT-SAP8A/11.03 UP.Browser/4.1.23c UP.Link/4.2.2.1
MOT-T280M/02.12.00I MIB/1.2
MOT-T280M/02.27.00I MIB/1.2
MOT-T720/05.05.1DI MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/05.05.21R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/05.05.21R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.0.2
MOT-T720/05.06.04I MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
MOT-T720/05.06.12R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.2.1
MOT-T720/05.06.18R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/05.06.18R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
MOT-T720/05.08.00R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/05.08.00R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2.4
MOT-T720/05.08.00R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
MOT-T720/05.08.00R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
MOT-T720/05.08.00R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
MOT-T720/05.08.00R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0-WG
MOT-T720/05.08.10R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/05.08.21R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.1a
MOT-T720/05.08.22R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/05.08.40R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/05.08.41R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.2a
MOT-T720/3.1ER MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.2
MOT-T720/A_G_05.06.22R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.01.43R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.01.48R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.01.65R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.01.66R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.07.1DR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.07.23R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.07.41R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.08.40R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.08.52R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.08.80R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.08.81R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
MOT-T720/G_05.20.09R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.20.09R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
MOT-T720/G_05.20.0BR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.20.0BR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.2a
MOT-T720/G_05.20.0BR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
MOT-T720/G_05.20.0CR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/G_05.31.05R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/PMHA_G_05.31.09R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/PMHA_G_05.31.1CR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/PM_G_05.31.09R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/PM_G_05.31.09R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
MOT-T720/PM_G_05.31.18R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
MOT-T720/PM_G_05.31.1CR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
MOT-T720/PM_G_05.40.0CR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.2a
MOT-T720/PM_G_05.40.0CR MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
MOT-T720/PM_G_05.40.45R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/PM_G_05.40.52R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
MOT-T720/PM_G_05.40.52R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
MOT-T720/PM_G_05.41.54R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-T720/PM_G_05.41.54R MIB/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
MOT-T725E/08.03.30I MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-TA02/06.03.1FR MIB/1.2.1
MOT-TA02/06.03.23BR MIB/1.2.1
MOT-TA02/06.03.23BR MIB/1.2.1 UP.Link/5.1.0.2
MOT-TA02/06.03.23BR MIB/1.2.1 UP.Link/5.1.1.5a
MOT-TA02/06.03.23BR MIB/1.2.1,MOT-TA02/06.03.23BR
MOT-TA02/06.03.23BR MIB/1.2.1,MOT-TA02/06.03.23BR MIB/1.2.1
MOT-TA02/06.03.23CR MIB/1.2.1
MOT-TA02/06.03.23R MIB/1.2.1
MOT-TA02/06.03.25BR MIB/1.2.1
MOT-TA02/06.03.25BR MIB/1.2.1,MOT-TA02/06.03.25BR
MOT-TA02/06.03.25BR MIB/1.2.1,MOT-TA02/06.03.25BR MIB/1.2.1
MOT-TA02/06.03.25CR MIB/1.2.1 UP.Link/5.1.2.1
MOT-TA02/06.03.28R MIB/1.2.1
MOT-TA02/06.03.28R MIB/1.2.1 UP.Link/5.1.2.2
MOT-TA02/06.03.2EAR MIB/1.2.1
MOT-TA02/06.03.2ER MIB/1.2.1
MOT-TA02/06.04.14R MIB/1.2.1
MOT-TA02/06.04.1AAR MIB/1.2.1
MOT-TA02/06.04.1FR MIB/1.2.1
MOT-TA02/06.04.1FR MIB/1.2.1 UP.Link/5.1.2.3
MOT-TA02/06.04.2BR MIB/1.2.1
MOT-TA02/06.04.2BR MIB/1.2.1 UP.Link/5.1.1.4
MOT-TA02/06.04.2DR MIB/1.2.1
MOT-TA02/06.04.2ER MIB/1.2.1
MOT-TA02/06.04.2FR MIB/1.2.1
MOT-TA02/06.04.31R MIB/1.2.1
MOT-TA02/06.04.34R MIB/1.2.1
MOT-TA02/06.04.34R MIB/1.2.1,MOT-TA02/06.04.34R MIB/1.2.1
MOT-TA02/06.04.36R MIB/1.2.1
MOT-V3/0E.40.3ER MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V300/0B.08.85R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V300/0B.08.86R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V300/0B.08.8BR MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V300/0B.08.8DR MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V300/0B.08.8F5 MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
MOT-V500/0B.08.74R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V500/0B.08.82R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
MOT-V500/0B.08.8DR MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V500/0B.08.8ER MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V500/0B.08.8F5 MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Link/1.1
MOT-V525M/0B.09.38R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V525M/0B.09.38R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Link/1.1
MOT-V600/0B.08.29I MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.08.61I MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.08.62R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.08.72R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.08.86R MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.08.8CR MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.08.8DR MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.08.8DR MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Link/5.1.1.1a
MOT-V600/0B.08.8ER MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.08.8FR MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0
MOT-V600/0B.09.1DR MIB/2.2 Profile/MIDP-2.0 Configuration/CLDC-1.0.
MOT-V60M/03.07.24I MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V60M/03.09.0BR MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V60M/03.09.0DR MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V60M/03.09.14R MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V60M/03.11.11R MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V60M/G_03.00.05R MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
MOT-V66M/02.27.00I MIB/1.2
MOT-V66M/03.08.09R MIB/1.2.1
MOT-V66M/03.09.0BR MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V66M/03.09.0BR MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
MOT-V66M/03.09.0DR MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V66M/03.09.14R MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V66M/03.12.03R MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V66M/03.12.03R MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0,MOT-V66M/03.12.03R MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V66M/05.05.13I MIB/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
MOT-V708_/11.03 UP.Browser/4.1.23c
MOT-V708_/11.03 UP.Browser/4.1.23c UP.Link/4.2.2.1
MOT-V708_/11.03 UP.Browser/4.1.23c UP.Link/5.1.1.4
MOT-V708_/11.03 UP.Browser/4.1.25i
MOT-V708_/11.03 UP.Browser/4.1.25i UP.Link/4.2.2.1
MOT-V708_/11.03+UP.Browser/4.1.23c
MOT-c350/G_09.04.70R MIB/2.0
MOT-c350/G_09.04.74R MIB/2.0
MOT-c350/G_09.04.75R MIB/2.0
MOT-c350M/AS_G_09.04.24R MIB/2.0
MOT-c350M/AS_G_09.04.37R MIB/2.0
MOT-c350M/A_G_09.04.37R MIB/2.0
MOT-c350M/G_09.04.26R MIB/2.0
MOT-c350M/G_09.04.34R MIB/2.0
MOT-c350M/G_09.04.35R MIB/2.0
MOT-c350M/G_09.04.35R MIB/2.0 UP.Link/1.1
MOT-c350M/G_09.04.35R MIB/2.0 UP.Link/5.1.1.3
MOT-c350M/G_09.04.35R MIB/2.0 UP.Link/5.1.1.5a
MOT-c350M/G_09.04.37R MIB/2.0
MOT-c350M/G_09.04.66R MIB/2.0 UP.Link/5.1.1.4
MOT-c350M/G_09.04.74R MIB/2.0
MOT-c350M/G_09.04.74R MIB/2.0 UP.Link/5.1.1.5a
MOT-c350M/G_09.04.75R MIB/2.0
MOT-c350M/ULS_G_09.10.1AR MIB/2.0
MOT-c350M/g_09.04.61i MIB/2.0
MOT-c350M/g_09.05.01i MIB/2.0
MOT-v200./10.01 UP/4.1.21b UP.Browser/4.1.21b-XXXX
Motorola-E365 UP.Browser/6.1.0.7 (GUI) MMP/1.0
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-J5)
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-J5) UP.Link/4.2.2.1
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-J7/J70)
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-J7/J70) UP.Link/4.2.2.1
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-J7/J70) UP.Link/4.3.2.4
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-J7/J70) UP.Link/5.1.1.3
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5)
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5) UP.Link/4.2.2.1
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5) UP.Link/4.3.2.4
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5) UP.Link/5.1.1.4
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5;Pj020e)
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5;Pj020e) UP.Link/5.1.1.2a
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5;Pz060e+wt16)
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5;Pz060e+wt16) UP.Link/5.1.1.4
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5;Pz063e+wt16)
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z5;Pz063e+wt16) UP.Link/4.2.2.1
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z7)
Mozilla/1.22 (compatible; MMEF20; Cellphone; Sony CMD-Z7) UP.Link/4.2.2.1
Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; 240x320; PPC)
Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; PPC; 240x320)
Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; Smartphone; 176x220)
Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; Smartphone; 176x220; 240x320)
Mozilla/2.0 (compatible; MSIE 4.02; Windows CE; Smartphone; 176x220)
Mozilla/2.0(compatible; MSIE 3.02; Windows CE; Smartphone; 176x220)
Mozilla/4.0 (MobilePhone PM-8200/US/1.0) NetFront/3.1 MMP/2.0
Mozilla/4.0 (MobilePhone SCP-4900/1.0) NetFront/3.0 MMP/2.0
Mozilla/4.0 (MobilePhone SCP-5300/1.0) NetFront/3.0 MMP/2.0
Mozilla/4.0 (MobilePhone SCP-8100/US/1.0) NetFront/3.0 MMP/2.0
Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320)
Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; SmartPhone; 176x220)
Mozilla/SMB3(Z105)/Samsung
Mozilla/SMB3(Z105)/Samsung UP.Link/5.1.1.5
NEC-525/1.0 up.Browser/6.1.0.6.1 (GUI) MMP/1.0
NEC-525/1.0 up.Browser/6.1.0.6.1 (GUI) MMP/1.0 UP.Link/5.1.1.5a
NEC-525/1.0 up.Browser/6.1.0.6.1 (GUI) MMP/1.0 UP.Link/5.1.2.3
NEC-530/1.0 UP.Browser/6.1.0.7 (GUI) MMP/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
NEC-DB7000/1.0 UP.Browser/4.1.23c
NEC-DB7000/1.0 UP.Browser/4.1.23c UP.Link/5.1.1.4
NEC-N8/1.0 UP.Browser/6.1.0.4.128 (GUI) MMP/1.0
NEC-N8/1.0 UP.Browser/6.1.0.5 (GUI) MMP/1.0
NEC-N8000/1.0 UP.Browser/5.0.2.1.103 (GUI)
NEC-N8000/1.0 UP.Browser/5.0.3.2 (GUI)
Nokia 9210/Symbian Crystal 6.0 (1.00)
Nokia Mobile Browser 3.01
Nokia Mobile Browser 4.0
Nokia Mobile Browser 4.0,Sony EricssonT610: SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia-MIT-Browser/3.0
Nokia-MIT-Browser/3.0 (via IBM Transcoding Publisher 3.5)
Nokia3100/1.0 (03.10) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3100/1.0 (03.10) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia3100/1.0 (03.12) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3100/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3100/1.0 (05.02) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3100/1.0 (05.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia3200/1.0 (4.16) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3220/2.0 (03.30) Profile/MIDP-2.0 Configuration/CLDC-1.1
Nokia3300/1.0 (4.05) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3300/1.0 (4.05) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia3300/1.0 (4.07) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3300/1.0 (4.25) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3320/1.2.1 (03.04)
Nokia3320/1.2.1 (2.06)
Nokia3320/1.2.1 (2.06) UP.Link/5.1.1.4
Nokia3330/1.0
Nokia3330/1.0 (03.05)
Nokia3330/1.0 (03.05) UP.Link/4.2.2.1
Nokia3330/1.0 (03.05) UP.Link/5.0.1.1
Nokia3330/1.0 (03.05) UP.Link/5.1.1.3
Nokia3330/1.0 (03.05) UP.Link/5.1.1a
Nokia3330/1.0 (03.10)
Nokia3330/1.0 (03.12)
Nokia3330/1.0 (03.12) UP.Link/5.1.1.5a
Nokia3330/1.0 (03.12) UP.Link/5.1.1a
Nokia3330/1.0 (04.12)
Nokia3330/1.0 (04.16)
Nokia3330/1.0 (04.16) UP.Link/4.2.2.1
Nokia3330/1.0 (04.16) UP.Link/4.2.2.9
Nokia3330/1.0 (04.16) UP.Link/5.1.1.4
Nokia3330/1.0 (04.16) UP.Link/5.1.1a
Nokia3330/1.0 (04.30)
Nokia3330/1.0 (04.30) UP.Link/4.2.2.1
Nokia3330/1.0 (04.30) UP.Link/5.1.1.4
Nokia3330/1.0 (04.30) UP.Link/5.1.1a
Nokia3330/1.0 (04.50)
Nokia3330/1.0 (04.50) UP.Link/4.2.2.1
Nokia3330/1.0 (04.50) UP.Link/4.2.2.9
Nokia3330/1.0 (04.50) UP.Link/4.3.2.4
Nokia3330/1.0 (04.50) UP.Link/5.0.2.3e
Nokia3330/1.0 (04.50) UP.Link/5.1.0.2
Nokia3330/1.0 (04.50) UP.Link/5.1.1.2a
Nokia3330/1.0 (04.50) UP.Link/5.1.1.3
Nokia3330/1.0 (04.50) UP.Link/5.1.1.5
Nokia3330/1.0 (04.50) UP.Link/5.1.1a
Nokia3330/1.0 (05.06)
Nokia3350/1.0 (05.11)
Nokia3350/1.0 (05.15)
Nokia3360/1.2.1 (03.04) UP.Link/5.1.2.1
Nokia3360/1.2.1 (1.04)
Nokia3360/1.2.1 (2.06) UP.Link/5.1.2.1
Nokia3395/1.0 (04.02) UP.Link/5.1.2.1
Nokia3410/1.0 (03.06)
Nokia3410/1.0 (03.06) UP.Link/4.3.2
Nokia3410/1.0 (03.06) UP.Link/5.1.1.4
Nokia3410/1.0 (03.09)
Nokia3410/1.0 (03.09) UP.Link/5.1.1a
Nokia3410/1.0 (04.08)
Nokia3410/1.0 (04.09)
Nokia3410/1.0 (04.09) (Google WAP Proxy/1.0)
Nokia3410/1.0 (04.09) UP.Link/4.2.2.1
Nokia3410/1.0 (04.09) UP.Link/5.1.1.2a
Nokia3410/1.0 (04.09) UP.Link/5.1.1.3
Nokia3410/1.0 (04.09) UP.Link/5.1.1.5c
Nokia3410/1.0 (04.09) UP.Link/5.1.1a
Nokia3410/1.0 (04.11)
Nokia3410/1.0 (04.26)
Nokia3410/1.0 (04.26) UP.Link/5.1.1.3
Nokia3410/1.0 (04.26) UP.Link/5.1.1a
Nokia3410/1.0 (05.06)
Nokia3410/1.0 (05.06) UP.Link/5.1.1a
Nokia3410/1.0 (05.30)
Nokia3410/1.0 (05.30) (Google WAP Proxy/1.0)
Nokia3410/1.0 (05.42)
Nokia3510/1.0 (3.02)
Nokia3510/1.0 (3.02) UP.Link/1.1
Nokia3510/1.0 (3.02) UP.Link/4.2.2.1
Nokia3510/1.0 (3.02) UP.Link/4.3.2.4
Nokia3510/1.0 (3.02) UP.Link/5.0.1.1
Nokia3510/1.0 (3.02) UP.Link/5.1.1.2a
Nokia3510/1.0 (3.02) UP.Link/5.1.1.4
Nokia3510/1.0 (3.02) UP.Link/5.1.1.5a
Nokia3510/1.0 (3.02) UP.Link/5.1.1a
Nokia3510/1.0 (3.02) UP.Link/5.1.2.3
Nokia3510/1.0 (3.11)
Nokia3510/1.0 (3.11) UP.Link/4.3.2.4
Nokia3510/1.0 (3.11) UP.Link/5.1.1.3
Nokia3510/1.0 (3.11) UP.Link/5.1.1.5a
Nokia3510/1.0 (3.11) UP.Link/5.1.2.4
Nokia3510/1.0 (3.34)
Nokia3510/1.0 (3.34) UP.Link/5.1.1
Nokia3510/1.0 (3.34) UP.Link/5.1.1.5a
Nokia3510/1.0 (3.36)
Nokia3510/1.0 (3.37)
Nokia3510/1.0 (3.37)  UP.Link/1.1
Nokia3510/1.0 (3.37) UP.Link/4.2.0.1
Nokia3510/1.0 (3.37) UP.Link/5.1.0.2
Nokia3510/1.0 (3.37) UP.Link/5.1.1.5a
Nokia3510/1.0 (3.37) UP.Link/5.1.1a
Nokia3510/1.0 (3.37) UP.Link/5.1.2.1
Nokia3510/1.0 (3.37) UP.Link/5.1.2.3
Nokia3510/1.0 (4.24)
Nokia3510/1.0 (4.24) UP.Link/5.1.1.4
Nokia3510/1.0 (4.24) UP.Link/5.1.1.5a
Nokia3510/1.0 (5.00)
Nokia3510/1.0 (5.00) UP.Link/5.1.1.5a
Nokia3510/1.0 (5.00) UP.Link/5.1.2.3
Nokia3510/1.0 (5.02)
Nokia3510i/1.0 (03.25) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3510i/1.0 (03.40) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3510i/1.0 (03.40) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia3510i/1.0 (03.40) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia3510i/1.0 (03.40) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia3510i/1.0 (03.40) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia3510i/1.0 (03.51) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3510i/1.0 (03.51) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia3510i/1.0 (03.51) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia3510i/1.0 (03.51) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia3510i/1.0 (03.51) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia3510i/1.0 (03.51) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia3510i/1.0 (03.54) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3510i/1.0 (03.54) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
Nokia3510i/1.0 (03.54) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.1.8
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.2a
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia3510i/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia3510i/1.0 (04.42) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3510i/1.0 (04.42) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia3510i/1.0 (04.42) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 (Google WAP Proxy/1.0)
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.0
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.1.8
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
Nokia3510i/1.0 (04.44) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia3560/1.0 (02.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia3590/1.0(7.14) UP.Link/5.1.2.1
Nokia3590/1.0(7.58) UP.Link/5.1.2.2
Nokia3595/1.0 (7.00) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia3595/1.0 (7.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.1a
Nokia3595/1.0 (7.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.1a
Nokia3595/1.0 (7.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.2
Nokia3595/1.0 (7.20) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3595/1.0 (7.20) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia3610/1.0 (05.11)
Nokia3650
Nokia3650/1.0 (4.13) SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia3650/1.0 (4.13) SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia3650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia3650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0-WG
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.0.1
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.1.8
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.1a
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia3650/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.1 Configuration/CLDC-1.0Nokia 3650 (;; ;; ;; ;)
Nokia3660/1.0 (4.57) SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia5100/1.0 (3.02) Profile/MIDP 1.0 Configuration/CLDC-1.0
Nokia5100/1.0 (3.02) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia5100/1.0 (3.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia5100/1.0 (3.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.2.5
Nokia5100/1.0 (3.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia5100/1.0 (3.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia5100/1.0 (3.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia5100/1.0 (3.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia5100/1.0 (4.05) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia5100/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia5210/1.0 ()
Nokia5210/1.0 () UP.Link/4.2.2.1
Nokia5210/1.0 () UP.Link/4.3.2.4
Nokia5210/1.0 () UP.Link/5.0.1.1
Nokia5210/1.0 () UP.Link/5.1.1.3
Nokia5210/1.0 () UP.Link/5.1.1.4
Nokia5210/1.0 () UP.Link/5.1.1.5a
Nokia5210/1.0 () UP.Link/5.1.1a
Nokia5510/1.0 (03.25)
Nokia5510/1.0 (03.42)
Nokia5510/1.0 (03.43)
Nokia5510/1.0 (03.45)
Nokia5510/1.0 (03.45) UP.Link/5.1.1.3
Nokia5510/1.0 (03.47)
Nokia5510/1.0 (03.48)
Nokia5510/1.0 (03.50)
Nokia5510/1.0 (03.50) UP.Link/4.2.2.1
Nokia5510/1.0 (03.53)
Nokia5510/1.0 (03.53) UP.Link/4.2.2.1
Nokia6100/1.0 (03.22) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6100/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6100/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia6100/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2.1
Nokia6100/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia6100/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
Nokia6100/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6100/1.0 (04.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia6100/1.0 (04.70) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6100/1.0 (04.70) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia6100/1.0 (04.70) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia6100/1.0 (04.70) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
Nokia6100/1.0 (04.70) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6100/1.0 (04.70) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia6100/1.0 (04.70) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia6100/1.0 (04.70) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia6100/1.0 (04.98) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6100/1.0 (05.16) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6108/1.0 (03.20) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6200/1.0 (3.05) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6210/1.0 (0)
Nokia6210/1.0 (03.01)
Nokia6210/1.0 (03.01) UP.Link/4.2.2.1
Nokia6210/1.0 (03.01) UP.Link/4.3.2.4
Nokia6210/1.0 (03.04)
Nokia6210/1.0 (03.60)
Nokia6210/1.0 (04.08)
Nokia6210/1.0 (04.08) UP.Link/4.2.2.1
Nokia6210/1.0 (04.08) UP.Link/5.1.1.5a
Nokia6210/1.0 (04.27)
Nokia6210/1.0 (04.27) UP.Link/4.2.2.1
Nokia6210/1.0 (04.27) UP.Link/5.01
Nokia6210/1.0 (04.27) UP.Link/5.02
Nokia6210/1.0 (04.27) UP.Link/5.1.0.1
Nokia6210/1.0 (04.27) UP.Link/5.1.1.3
Nokia6210/1.0 (04.36)
Nokia6210/1.0 (04.36) UP.Link/4.2.2.1
Nokia6210/1.0 (04.36) UP.Link/5.0.0.4
Nokia6210/1.0 (05.01)
Nokia6210/1.0 (05.02)
Nokia6210/1.0 (05.02) UP.Link/4.2.2.1
Nokia6210/1.0 (05.02) UP.Link/5.1.1.4
Nokia6210/1.0 (05.02) UP.Link/5.1.1.5a
Nokia6210/1.0 (05.17)
Nokia6210/1.0 (05.17) UP.Link/4.2.2.1
Nokia6210/1.0 (05.17) UP.Link/5.1.1.3
Nokia6210/1.0 (05.17) UP.Link/5.1.1.5a
Nokia6210/1.0 (05.17) UP.Link/5.1.1a
Nokia6210/1.0 (05.27)
Nokia6210/1.0 (05.27) UP.Link/4.2.2.1
Nokia6210/1.0 (05.27) UP.Link/5.1.1.3
Nokia6210/1.0 (05.36)
Nokia6210/1.0 (05.36) UP.Link/5.1.1.4
Nokia6210/1.0 (05.44)
Nokia6210/1.0 (05.56)
Nokia6210/1.0 (05.56) UP.Link/4.2.2.1
Nokia6210/1.0 (05.56) UP.Link/5.1.1.5a
Nokia6210/1.0 (ccWAP-Browser)
Nokia6220/2.0 (5.15) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6220/2.0 Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6230/2.0 (03.14) Profile/MIDP-2.0 Configuration/CLDC-1.1
Nokia6230/2.0 (03.15) Profile/MIDP-2.0 Configuration/CLDC-1.1
Nokia6230/2.0 (04.28) Profile/MIDP-2.0 Configuration/CLDC-1.1
Nokia6230/2.0 (04.44) Profile/MIDP-2.0 Configuration/CLDC-1.1
Nokia6250/1.0
Nokia6250/1.0 (03.00)
Nokia6250/1.0 (03.12)
Nokia6250/1.0 (04.01)
Nokia6250/1.0 (05.02)
Nokia6310/1.0 ()
Nokia6310/1.0 (03.03)
Nokia6310/1.0 (04.03)
Nokia6310/1.0 (04.10)
Nokia6310/1.0 (04.10) UP.Link/4.2.2.1
Nokia6310/1.0 (04.10) UP.Link/4.3.2.1
Nokia6310/1.0 (04.10) UP.Link/4.3.2.4
Nokia6310/1.0 (04.10) UP.Link/5.02
Nokia6310/1.0 (04.10) UP.Link/5.1.1.4
Nokia6310/1.0 (04.15)
Nokia6310/1.0 (04.15) UP.Link/4.2.2.1
Nokia6310/1.0 (04.15) UP.Link/5.1.1.5a
Nokia6310/1.0 (04.20)
Nokia6310/1.0 (04.20) UP.Link/4.2.2.1
Nokia6310/1.0 (04.20) UP.Link/4.3.2.1
Nokia6310/1.0 (04.20) UP.Link/5.1.1.2a
Nokia6310/1.0 (04.20) UP.Link/5.1.1.3
Nokia6310/1.0 (04.20) UP.Link/5.1.1.3 (Google WAP
Nokia6310/1.0 (04.20) UP.Link/5.1.1.3 (Google WAP Proxy/1.0)
Nokia6310/1.0 (04.20) UP.Link/5.1.1.4
Nokia6310/1.0 (04.20) UP.Link/5.1.1.5a
Nokia6310/1.0 (04.20) UP.Link/5.1.1a
Nokia6310/1.0 (04.31)
Nokia6310/1.0 (05.01)
Nokia6310i/1.0 (4.06) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6310i/1.0 (4.07) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6310i/1.0 (4.07) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.2.1
Nokia6310i/1.0 (4.07) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2.1
Nokia6310i/1.0 (4.07) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.0.2.3d
Nokia6310i/1.0 (4.07) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1
Nokia6310i/1.0 (4.07) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia6310i/1.0 (4.07) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia6310i/1.0 (4.50) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6310i/1.0 (4.80) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6310i/1.0 (4.80) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.2.1
Nokia6310i/1.0 (4.80) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2.1
Nokia6310i/1.0 (4.80) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.1
Nokia6310i/1.0 (4.80) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6310i/1.0 (5.10) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6310i/1.0 (5.10) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.2a
Nokia6310i/1.0 (5.10) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6310i/1.0 (5.10) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia6310i/1.0 (5.22) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6310i/1.0 (5.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6310i/1.0 (5.50) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6310i/1.0 (5.50) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia6310i/1.0 (5.51) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6310i/1.0 (5.52) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6340i/1.2.1 (8.03.1) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia6340i/1.2.1 (8.04.1) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia6340i/1.2.1 (8.05.3) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia6500/1.0 (05.57)
Nokia6510/1.0 (02.40)
Nokia6510/1.0 (02.50)
Nokia6510/1.0 (03.21)
Nokia6510/1.0 (03.22)
Nokia6510/1.0 (03.22) UP.Link/4.2.2.1
Nokia6510/1.0 (03.22) UP.Link/5.1.1.3
Nokia6510/1.0 (03.22) UP.Link/5.1.1a
Nokia6510/1.0 (03.30)
Nokia6510/1.0 (03.30) UP.Link/4.2.2.1
Nokia6510/1.0 (03.35)
Nokia6510/1.0 (03.35) UP.Link/4.2.2.1
Nokia6510/1.0 (03.35) UP.Link/4.3.2.4
Nokia6510/1.0 (03.35) UP.Link/5.1.1.4
Nokia6510/1.0 (04.00)
Nokia6510/1.0 (04.00) UP.Link/4.2.2.1
Nokia6510/1.0 (04.00) UP.Link/4.3.2.1
Nokia6510/1.0 (04.00) UP.Link/5.1.1.2a
Nokia6510/1.0 (04.00) UP.Link/5.1.2.3
Nokia6510/1.0 (04.00) UP.Link/5.1.2.4
Nokia6510/1.0 (04.05)
Nokia6510/1.0 (04.05) UP.Link/4.3.2.1
Nokia6510/1.0 (04.06)
Nokia6510/1.0 (04.06) UP.Link/4.2.2.1
Nokia6510/1.0 (04.06) UP.Link/4.3.2.4
Nokia6510/1.0 (04.06) UP.Link/5.1.1.2a
Nokia6510/1.0 (04.06) UP.Link/5.1.1.4
Nokia6510/1.0 (04.06) UP.Link/5.1.1.5a
Nokia6510/1.0 (04.06) UP.Link/5.1.2.4
Nokia6510/1.0 (04.12)
Nokia6510/1.0 (04.12) UP.Link/4.3.2.4
Nokia6510/1.0 (04.12) UP.Link/5.1.1.4
Nokia6510/1.0 (04.12) UP.Link/5.1.1.5a
Nokia6510/1.0 (04.12) UP.Link/5.1.1a
Nokia6510/1.0 (04.12) UP.Link/5.1.2.3
Nokia6510/1.0 (04.12) UP.Link/5.1.2.4
Nokia6510/1.0 (04.12) UP.Link/5.1.2.5
Nokia6510/1.0 (04.21) UP.Link/5.1.1a
Nokia6590/1.0(40.44)
Nokia6600/1.0 (3.42.1) SymbianOS/7.0s Series60/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.0
Nokia6600/1.0 (4.09.1) SymbianOS/7.0s Series60/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.0
Nokia6600/1.0 (5.27.0) SymbianOS/7.0s Series60/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 (Google W
Nokia6610/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6610/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2.1
Nokia6610/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.0.2
Nokia6610/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia6610/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6610/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia6610/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia6610/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.0
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.0.1
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2.1
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.0.2
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.2a
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia6610/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia6610/1.0 (4.28) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6610/1.0 (4.28) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.0
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.1.8
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.2
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia6610/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia6610/1.0 (5.52) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6610I/1.0 (3.10) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6610I/1.0 (3.10) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
Nokia6650/1.0 (1.101) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6650/1.0 (12.89) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6650/1.0 (13.88) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6650/1.0 (13.88) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.1
Nokia6650/1.0 (13.89) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6650/1.0 (13.89) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6800/1.0 (3.14) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6800/1.0 (3.14) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia6800/1.0 (3.14) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia6800/1.0 (3.14) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia6800/1.0(2.81)Profile/MIDP-1.0Configuration/CLDC-1.0
Nokia6800/2.0 (4.16) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia6800/2.0 (4.17) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6820/2.0 (3.19) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6820/2.0 (3.21) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6820/2.0 (3.70) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6820/2.0 (4.22) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia6820/2.0 (4.25) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7110
Nokia7110 (DeckIt/1.2.1)
Nokia7110 (DeckIt/1.2.3)
Nokia7110 (compatible; NG/1.0)
Nokia7110 CES
Nokia7110/1.0
Nokia7110/1.0 (04.67)
Nokia7110/1.0 (04.70)
Nokia7110/1.0 (04.73)
Nokia7110/1.0 (04.76)
Nokia7110/1.0 (04.76) UP.Link/4.1.0.7
Nokia7110/1.0 (04.76) aplpi.com v0.5
Nokia7110/1.0 (04.77)
Nokia7110/1.0 (04.77) UP.Link/4.2.2.1
Nokia7110/1.0 (04.77) UP.Link/5.0.1.1
Nokia7110/1.0 (04.77) UP.Link/5.0.2.3d
Nokia7110/1.0 (04.78)
Nokia7110/1.0 (04.80)
Nokia7110/1.0 (04.84)
Nokia7110/1.0 (04.84) UP.Link/4.1.0.6
Nokia7110/1.0 (04.84) UP.Link/4.2.2.1
Nokia7110/1.0 (04.84) UP.Link/5.1.0.1
Nokia7110/1.0 (04.84; mostly compatible; Mobone 1.05)
Nokia7110/1.0 (04.88)
Nokia7110/1.0 (04.88) UP.Link/5.1.1.3
Nokia7110/1.0 (04.94)
Nokia7110/1.0 (05.00)
Nokia7110/1.0 (05.01)
Nokia7110/1.0 (05.01) UP.Link/5.1.0.1
Nokia7110/1.0 (05.01) UP.Link/5.1.1a
Nokia7110/1.0 (4.80)
Nokia7110/1.0 (WAPTOO)
Nokia7110/1.0 (Waptoo DT)
Nokia7110/1.0 1551.1
Nokia7110/1.0+(04.73);
Nokia7110/1.0+(04.77)
Nokia7110/1.0+(Waptoo+DT)
Nokia7160/1.1 (01.05)
Nokia7160/1.1 (01.07)
Nokia7160/1.1 (01.07) UP.Link/5.1.2.1
Nokia7210/1.0 (2.01) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7210/1.0 (3.08) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7210/1.0 (3.08) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2.1
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia7210/1.0 (3.09) Profile/MIDP-1.0 Configuration/CLDC-1.0-WG
Nokia7210/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7210/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.1a
Nokia7210/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia7210/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia7210/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia7210/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
Nokia7210/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia7210/1.0 (4.18) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia7210/1.0 (4.24) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7210/1.0 (4.24) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
Nokia7210/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7210/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia7210/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia7210/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia7210/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia7210/1.0 (4.74) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia7210/1.0 (5.52) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7210/1.0 (81.73)
Nokia7250/1.0
Nokia7250/1.0 (2.15) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.0.1
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a (Google WAP Proxy/1.0)
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia7250/1.0 (3.12) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia7250/1.0 (3.14) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7250/1.0 (3.14) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
Nokia7250/1.0 (3.62) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia7250I/1.0 (3.22) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia7250I/1.0 (4.22) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7250I/1.0 (4.63) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7610/2.0 (4.0421.4) SymbianOS/7.0s Series60/2.1 Profile/MIDP-2.0 Configuration/CLDC-1.0
Nokia7650
Nokia7650 [XIDRIS WML Browser 2.2]
Nokia7650/1.0
Nokia7650/1.0 RPT-HTTPClient/0.3-3E
Nokia7650/1.0 Symbian-QP/6.1 Nokia/2.1
Nokia7650/1.0 Symbian-QP/6.1 Nokia/2.1 (;; ;; ;; ;)
Nokia7650/1.0 Symbian-QP/6.1 Nokia/2.1 (;; ;; ;; ;; 240x320)
Nokia7650/1.0 SymbianOS/6.1 (compatible; YOSPACE SmartPhone Emulator Website Edition 1.11)
Nokia7650/1.0 SymbianOS/6.1 (compatible; YOSPACE SmartPhone Emulator Website Edition 1.14)
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 (Google WAP Proxy/1.0)
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.0.1
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.2.1
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.2.1-WG
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.3.2.1
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.0.1
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.0.2
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.2a
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
Nokia7650/1.0 SymbianOS/6.1 Series60/0.9 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
Nokia7650/4.0 UQ.Browser/6.2.0.1.185 (GUI) MMP/2.0
Nokia7650_Laurence (via IBM Transcoding Publisher
Nokia7650_blb
Nokia8310/1.0 (03.05)
Nokia8310/1.0 (03.05) UP.Link/5.1.1.4
Nokia8310/1.0 (03.07)
Nokia8310/1.0 (03.07) UP.Link/4.2.2.1
Nokia8310/1.0 (03.07) UP.Link/4.3.2.1
Nokia8310/1.0 (04.04)
Nokia8310/1.0 (04.04) UP.Link/4.2.2.1
Nokia8310/1.0 (04.04) UP.Link/4.2.2.5
Nokia8310/1.0 (04.04) UP.Link/4.3.2.1
Nokia8310/1.0 (04.04) UP.Link/4.3.2.4
Nokia8310/1.0 (04.04) UP.Link/5.0
Nokia8310/1.0 (04.04) UP.Link/5.1.1.4
Nokia8310/1.0 (04.53)
Nokia8310/1.0 (04.53) UP.Link/4.2.2.1
Nokia8310/1.0 (04.53) UP.Link/4.3.2.1
Nokia8310/1.0 (04.53) UP.Link/4.3.2.4
Nokia8310/1.0 (04.53) UP.Link/4.3.4.3
Nokia8310/1.0 (04.53) UP.Link/5.0.1.1
Nokia8310/1.0 (04.53) UP.Link/5.1.1.2a
Nokia8310/1.0 (05.05)
Nokia8310/1.0 (05.06)
Nokia8310/1.0 (05.06) UP.Link/4.2.0.1
Nokia8310/1.0 (05.06) UP.Link/4.2.2.1
Nokia8310/1.0 (05.06) UP.Link/4.3.2.1
Nokia8310/1.0 (05.06) UP.Link/4.3.2.4
Nokia8310/1.0 (05.06) UP.Link/5.1.1.3
Nokia8310/1.0 (05.06) UP.Link/5.1.1.4
Nokia8310/1.0 (05.06) UP.Link/5.1.1a
Nokia8310/1.0 (05.06) UP.Link/5.1.2.3
Nokia8310/1.0 (05.06) UP.Link/5.1.2.4
Nokia8310/1.0 (05.11)
Nokia8310/1.0 (05.11) UP.Link/4.2.2.1
Nokia8310/1.0 (05.11) UP.Link/4.3.2.4
Nokia8310/1.0 (05.11) UP.Link/5.1.1.4
Nokia8310/1.0 (05.11) UP.Link/5.1.1a
Nokia8310/1.0 (05.11) UP.Link/5.1.2.3
Nokia8310/1.0 (05.34)
Nokia8310/1.0 (05.54)
Nokia8310/1.0 (05.54) UP.Link/4.2.2.1
Nokia8310/1.0 (05.54) UP.Link/5.1.1.4
Nokia8310/1.0 (05.55)
Nokia8310/1.0 (05.57)
Nokia8310/1.0 (05.57) (Google WAP Proxy/1.0)
Nokia8310/1.0 (05.57) UP.Link/4.2.2.1
Nokia8310/1.0 (05.57) UP.Link/5.1.1.4
Nokia8310/1.0 (05.57) UP.Link/5.1.2.3
Nokia8310/1.0 (05.80)
Nokia8310/1.0 (05.80) UP.Link/5.1.2.4
Nokia8310/1.0 (05.80) UP.Link/5.1.2.5
Nokia8310/1.0 (06.01)
Nokia8310/1.0 (06.04)
Nokia8310/1.0 (06.04) UP.Link/5.1.1.4
Nokia8310/1.0 (06.04) UP.Link/5.1.1a
Nokia8310/1.0 (06.04) UP.Link/5.1.2
Nokia8310/1.0 (06.04) UP.Link/5.1.2.3
Nokia8310/1.0 (06.04) UP.Link/5.1.2.4
Nokia8310/1.0 (06.20)
Nokia8310/1.0 (06.20) UP.Link/1.1
Nokia8390/1.0 (7.00) UP.Link/5.1.2.2
Nokia8910/1.0 (03.04)
Nokia8910/1.0 (03.04) UP.Link/4.2.2.1
Nokia8910/1.0 (03.06)
Nokia8910/1.0 (03.57)
Nokia8910/1.0 (04.02)
Nokia8910i/1.0 (02.61) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia8910i/1.0 (03.01) Profile/MIDP-1.0 Configuration/CLDC-1.0
Nokia8910i/1.0 (03.01) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
Nokia8910i/1.0 (03.02) Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
Nokia9110/1.0
Nokia9110/1.0 UP.Link/4.2.2.1
Nokia9210/1.0 Symbian-Crystal/6.0
Nokia9210/1.0 Symbian-Crystal/6.0 UP.Link/4.2.2.5
Nokia9210/1.0 Symbian-Crystal/6.0 UP.Link/4.3.2.1
Nokia9210/1.0 Symbian-Crystal/6.0 UP.Link/5.1.1.4
Nokia9210/1.0 Symbian-Crystal/6.0 UP.Link/5.1.1.5a
Nokia9210/1.0 Symbian-Crystal/6.0 UP.Link/5.1.1a
Nokia9210/2.0 Symbian-Crystal/6.1 Nokia/2.1
Nokia9210i/1.0 Symbian-Crystal/6.0
Nokia9210i/1.0 Symbian-Crystal/6.0 UP.Link/4.2.2.5
NokiaN-Gage/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
NokiaN-Gage/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
PHILIPS 530 / Obigo Internet Browser 2.0
PHILIPS 535/Obigo Internet Browser 2.0
PHILIPS-Az@lis288 UP/4.1.19l
PHILIPS-Az@lis288 UP/4.1.19m
PHILIPS-Az@lis288/2.1 UP/4.1.19m
PHILIPS-FISIO 318 UP/4.1.19m
PHILIPS-FISIO 318/3.8 UP.Browser/5.0.1.235
PHILIPS-FISIO 318/3.8 UP.Browser/5.0.1.3.101
PHILIPS-FISIO 330/3.14 UP.Browser/5.0.3.5 (GUI)
PHILIPS-FISIO 620 UP/4.1.19m
PHILIPS-FISIO 620/3.14 UP.Browser/5.0.1.10
PHILIPS-FISIO 620/3.14 UP.Browser/5.0.1.11
PHILIPS-FISIO 620/3.14 UP.Browser/5.0.1.11 (Google WAP Proxy/1.0)
PHILIPS-FISIO 620/3.14 UP.Browser/5.0.1.11 UP.Link/4.2.2.1
PHILIPS-FISIO 620/3.14 UP.Browser/5.0.1.6
PHILIPS-FISIO 620/3.14 UP.Browser/5.0.1.8
PHILIPS-FISIO 620/3.14 UP.Browser/5.0.3
PHILIPS-FISIO 620/3.8 UP.Browser/5.0.1.3.101
PHILIPS-FISIO 625/3.14 UP.Browser/5.0.3.5 (GUI)
PHILIPS-FISIO 820/3.14 UP.Browser/5.0.1.10
PHILIPS-FISIO 820/3.14 UP.Browser/5.0.1.10 UP.Link/4.2.2.1
PHILIPS-FISIO 820/3.14 UP.Browser/5.0.1.11
PHILIPS-FISIO 820/3.14 UP.Browser/5.0.1.11 UP.Link/4.2.2.1
PHILIPS-FISIO 820/3.14 UP.Browser/5.0.1.8
PHILIPS-FISIO 822/3.14 UP.Browser/5.0.3.5 (GUI)
PHILIPS-FISIO 822/3.14 UP.Browser/5.0.3.5 (GUI) (Google WAP Proxy/1.0)
PHILIPS-FISIO 825/3.14 UP.Browser/5.0.3.5 (GUI)
PHILIPS-FISIO 825/3.14 UP.Browser/5.0.3.5 (GUI) (Google WAP Proxy/1.0)
PHILIPS-FISIO 825/3.14 UP.Browser/5.0.3.5 (GUI) UP.Link/5.1.1.3
PHILIPS-FISIO 826/3.14 UP.Browser/5.0.3.5 (GUI)
PHILIPS-Fisio 121/2.1 UP/4.1.19m
PHILIPS-Fisio 121/2.1 UP/4.1.19m UP.Browser/4.1.19m-XXXX UP.Link/4.2.2.1
PHILIPS-Fisio311/2.1 UP/4.1.19m
PHILIPS-Fisio311/316 /2.1 UP/4.1.19m
PHILIPS-GPRS/3.8 UP.Browser/5.0.1.3.101
PHILIPS-Ozeo UP/4.1.16r
PHILIPS-Ozeo UP/4.1.16r UP.Browser/4.1.16r-XXXX UP.Link/4.2.2.1
PHILIPS-SYSOL2/3.11 UP.Browser/5.0.1.11
PHILIPS-SYSOL2/3.11 UP.Browser/5.0.1.6.101
PHILIPS-V21WAP UP/4.1.16g
PHILIPS-V21WAP UP/4.1.16r
PHILIPS-V21WAPCHN UP/4.1.16f
PHILIPS-VTHIN_WAP UP/4.1.16r
PHILIPS-W@B/3.13 UP/5.0.1.232
PHILIPS-W@B/3.14 UP.Browser/5.0.1.6
PHILIPS-W@B/3.14 UP.Browser/5.0.1.8
PHILIPS-W@B/3.14.01 UP.Browser/5.0.1.6
PHILIPS-X38 UP/4.1.16g
PHILIPS-XENIUM 9660/2.1 UP/4.1.19m
PHILIPS-XENIUM 9@9/2.1 UP/4.1.19m
PHILIPS-Xenium 9@9++/3.14 UP.Browser/5.0.3.5 (GUI)
PHILIPS-Xenium9@9 UP/4.1.16f
PHILIPS-Xenium9@9 UP/4.1.16g
PHILIPS-Xenium9@9 UP/4.1.16r
PHILIPS-Xenium9@9 UP/4.1.19l
PHILIPS-Xenium9@9 UP/4.1.19m
PHILIPS-az@lis238 UP/4.1.16r
PHILIPS-az@lis268 UP/4.1.16r
PHILIPS-az@lis268 UP/4.1.16r UP.Browser/4.1.16r-XXXX UP.Link/4.2.2.1
PHILIPS-az@lis288_4 UP/4.1.19l
Panasonic WAP
Panasonic WAP UP.Link/4.2.2.1
Panasonic WAP UP.Link/5.1.1.4
Panasonic-G50/1.0 UP.Browser/6.1.0.6.d.2.100 (GUI) MMP/1.0
Panasonic-G60/1.0 UP.Browser/6.1.0.7 MMP/1.0 UP.Browser/6.1.0.7 (GUI) MMP/1.0
Panasonic-GAD35/1.0 UP.Browser/4.1.22j
Panasonic-GAD35/1.1 UP.Browser/4.1.24d
Panasonic-GAD35/1.1 UP.Browser/4.1.24g
Panasonic-GAD6*/1.0 UP.Browser/5.0.3.5 (GUI)
Panasonic-GAD67 (SimulateurWAPVizzavi)
Panasonic-GAD67/1.0 UP.Browser/5.0.3.5 (GUI)
Panasonic-GAD67/1.0 UP.Browser/5.0.3.5 (GUI) UP.Link/4.2.1.8
Panasonic-GAD67/1.0 UP.Browser/5.0.3.5 (GUI) UP.Link/5.1.1.4
Panasonic-GAD67/1.0 UP.Browser/5.0.3.5 (GUI) UP.Link/5.1.1.5a
Panasonic-GAD67/1.0 UP.Browser/5.0.3.5 (GUI) UP.Link/5.1.1a
Panasonic-GAD67/1.0 UP.Browser/5.0.3.5 (GUI) UP.Link/5.1.2.3
Panasonic-GAD75
Panasonic-GAD75 UP.Link/4.2.2.1
Panasonic-GAD75 UP.Link/5.1.1.4
Panasonic-GAD75 UP.Link/5.1.1.5
Panasonic-GAD87
Panasonic-GAD87 (Google WAP Proxy/1.0)
Panasonic-GAD87 UP.Link/5.1.0.2
Panasonic-GAD87 UP.Link/5.1.1.4
Panasonic-GAD87 UP.Link/5.1.1.5a
Panasonic-GAD87 UP.Link/5.1.2.3
Panasonic-GAD87/A19
Panasonic-GAD87/A19 UP.Link/5.1.1.4
Panasonic-GAD87/A19 UP.Link/5.1.2.3
Panasonic-GAD87/A20
Panasonic-GAD87/A21
Panasonic-GAD87/A21 UP.Link/1.1
Panasonic-GAD87/A21 UP.Link/5.1.1.4
Panasonic-GAD87/A21 UP.Link/5.1.2.1
Panasonic-GAD87/A22
Panasonic-GAD87/A22 UP.Link/5.1.1.4
Panasonic-GAD87/A22 UP.Link/5.1.1.5a
Panasonic-GAD87/A22 UP.Link/5.1.2.3
Panasonic-GAD87/A37
Panasonic-GAD87/A38
Panasonic-GAD87/A38 UP.Link/5.1.1.1a
Panasonic-GAD87/A38 UP.Link/5.1.1.4
Panasonic-GAD87/A38 UP.Link/5.1.1a
Panasonic-GAD87/A39
Panasonic-GAD87/A39 UP.Link/5.1.1.4
Panasonic-GAD87/A39 UP.Link/5.1.1.5a
Panasonic-GAD87/A39 UP.Link/5.1.2.4
Panasonic-GAD87/A51
Panasonic-GAD87/A51 UP.Link/1.1
Panasonic-GAD87/A51 UP.Link/5.1.1.3
Panasonic-GAD87/A51 UP.Link/5.1.2.3
Panasonic-GAD87/A53
Panasonic-GAD95
Panasonic-GAD95 UP.Link/4.2.2.1
Panasonic-GAD96
Panasonic-GAD96 UP.Link/5.1.1
Panasonic-GAD96 UP.Link/5.1.2.3
Panasonic-X60/R01 Profile/MIDP-1.0 Configuration/CLDC-1.0
Panasonic-X60/R01 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
QCI-23/1.0 UP.Browser/5.0.2.5 (GUI)
QCI-24/1.0 UP.Browser/5.0.2.5 (GUI)
QCI-31/1.0 UP.Browser/6.1.0.6.d.2.100 (GUI) MMP/1.0
SAGEM myX-5m
SAGEM-3XXX/0.0 UP/4.1.16r
SAGEM-3XXX/0.0 UP/4.1.16r UP.Browser/4.1.16r-XXXX UP.Link/4.2.2.1
SAGEM-3XXX/0.0 UP/4.1.19i
SAGEM-3XXX/0.0 UP/4.1.19is
SAGEM-3XXX/0.0 UP/4.1.19is UP.Browser/4.1.19is-XXXX UP.Link/4.2.2.1
SAGEM-3XXX/0.0 UP/4.1.19is UP.Browser/4.1.19is-XXXX UP.Link/5.1.0.2
SAGEM-3XXX/0.0 UP/4.1.19is UP.Browser/4.1.19is-XXXX UP.Link/5.1.1.3
SAGEM-3XXX/0.0 UP/4.1.19is UP.Browser/4.1.19is-XXXX UP.Link/5.1.1a
SAGEM-3XXX/1.0 UP.Browser/5.0.1.12 (GUI) UP.Link/5.1.2.5
SAGEM-3XXX/1.0 UP.Browser/5.0.1.5 (GUI)
SAGEM-3XXX/1.0 UP.Browser/5.0.1.7 (GUI)
SAGEM-3XXX/1.0 UP.Browser/5.0.1.7 (GUI) UP.Link/5.1.2.3
SAGEM-3XXX/1.0 UP.Browser/5.0.2.1 (GUI)
SAGEM-9XX/0.0 UP/4.1.16g
SAGEM-9XX/0.0 UP/4.1.16q
SAGEM-9XX/0.0 UP/4.1.19i
SAGEM-9XX/0.0 UP/4.1.19is
SAGEM-9XX/0.0 UP/4.1.19is UP.Browser/4.1.19is-XXXX UP.Link/4.2.2.1
SAGEM-myV-55/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.6.d.3 (GUI) MMP/1.0 UP.Lin
SAGEM-myV-55/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.6.d.3.100 (GUI) MMP/1.0
SAGEM-myV-65/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.3.e.1 (GUI) MMP/1.0
SAGEM-myV-65/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.3.e.2 (GUI) MMP/1.0
SAGEM-myV-65/1.0 UP.Browser/6.2.2.3 (GUI) MMP/1.0
SAGEM-myV-65/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.3.e.2 (GUI) MMP/1.0
SAGEM-myV-75/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.5.d.2 (GUI) MMP/1.0 UP.Lin
SAGEM-myX-
SAGEM-myX-2/1.0 UP.Browser/5.0.5.3.100 (GUI)
SAGEM-myX-2/1.0 UP.Browser/5.0.5.5 (GUI)
SAGEM-myX-2/1.0 UP.Browser/5.0.5.5.100 (GUI)
SAGEM-myX-2G/1.0
SAGEM-myX-2m/1.0 UP.Browser/6.1.0.6.1.c.4 (GUI) MMP/1.0
SAGEM-myX-3/1.0 UP.Browser/5.0.1.12.c.1 (GUI)
SAGEM-myX-3/1.0 UP.Browser/5.0.1.12.c.1 (GUI) (Google WAP Proxy/1.0)
SAGEM-myX-3/1.0 UP.Browser/5.0.1.12.c.1 (GUI) UP.Link/5.1.1.3
SAGEM-myX-3/2.0 UP.Browser/5.0.5.1 (GUI)
SAGEM-myX-3/2.0 UP.Browser/5.0.5.1 (GUI) (Google WAP Proxy/1.0)
SAGEM-myX-5/2.0 UP.Browser/5.0.1.7 (GUI)
SAGEM-myX-5/2.0 UP.Browser/5.0.2.1 (GUI)
SAGEM-myX-5/2.0 UP.Browser/5.0.3 (GUI)
SAGEM-myX-5/2.0 UP.Browser/5.0.3.1 (GUI)
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.1.c.1 (GUI)
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.1.c.1 (GUI) UP.Link/4.3.2.1
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.1.c.1 (GUI) UP.Link/5.1.1.5a
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.1.c.1 (GUI)-WG
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.100 (GUI)
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.100 (GUI) UP.Link/4.2.2.1
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.100 (GUI) UP.Link/5.1.1.3
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.100 (GUI) UP.Link/5.1.1.4
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.100 (GUI) UP.Link/5.1.1a
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.100 (GUI) UP.Link/5.1.2.3
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.100 (GUI)-WG
SAGEM-myX-5/2.0 UP.Browser/5.0.3.3.100(GUI)-WG
SAGEM-myX-5e/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0
SAGEM-myX-5m/1.0 UP.Browser/6.1.0.6.1.103 (GUI) MMP/1.0
SAGEM-myX-5m/1.0 UP.Browser/6.1.0.6.1.103 (GUI) MMP/1.0 (Google WAP Proxy/1.0)
SAGEM-myX-5m/1.0 UP.Browser/6.1.0.6.1.c.1 (GUI) MMP/1.0
SAGEM-myX-5m/1.0 UP.Browser/6.1.0.6.1.c.1 (GUI) MMP/1.0 UP.Link/5.1.1.5a
SAGEM-myX-5m/1.0 UP.Browser/6.1.0.6.1.c.1 (GUI) MMP/1.0 UP.Link/5.1.2.4
SAGEM-myX-5m/1.0 UP.Browser/6.1.0.6.1.c.1 (GUI) MMP/1.0 UP.Link/5.1.2.5
SAGEM-myX-5m/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0
SAGEM-myX-5m/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0 UP.Link/5.1.1a
SAGEM-myX-5m/1.0 UP.Browser/6.1/0.6.1.103 (GUI) MMP/1.0
SAGEM-myX-5m/1.0 UP.Browser/6.1/0.6.1.103 (GUI) MMP/1.0-WG
SAGEM-myX-5m/1.1 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0
SAGEM-myX-5m/1.1 UP.Browser/6.1.0.6.1.c.4 (GUI) MMP/1.0
SAGEM-myX-5m/1.1 UP.Browser/6.1.0.6.1.c.4 (GUI) MMP/1.0 (Google WAP Proxy/1.0)
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.1 (GUI) MMP/1.0
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0 UP.Link/1.1
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0 UP.Link/5.1.1.5a
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.3 (GUI) MMP/1.0 UP.Link/5.1.2.3
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.4 (GUI) MMP/1.0
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.4 (GUI) MMP/1.0 UP.Link/5.1.1.4
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.4 (GUI) MMP/1.0 UP.Link/5.1.2.4
SAGEM-myX-6/1.0 UP.Browser/6.1.0.6.1.c.4 (GUI) MMP/1.0 UP.Link/5.1.2.5
SAGEM-myX-6/1.0 UP.Browser/6.2.2.1 (GUI) MMP/1.0
SAGEM-myX-6/1.0 UP.Browser/6.2.2.3 (GUI) MMP/1.0
SAGEM-myX-6/1.0UP.Browser/6.1.0.6.1.c.1(GUI) MMP/1.0
SAGEM-myX-6/2.0 UP.Browser/6.2.2.4.105 (GUI) MMP/1.0
SAMSUNG-SGH-A110/1.0 UP/4.1.19j
SAMSUNG-SGH-A110/1.0 UP/4.1.19k
SAMSUNG-SGH-A110/1.0 UP/4.1.20a
SAMSUNG-SGH-A200/1.0 UP/4.1.19k
SAMSUNG-SGH-A288/1.0 UP/4.1.19k
SAMSUNG-SGH-A300/1.0 UP/4.1.19k
SAMSUNG-SGH-A300/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-A300/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.0.2
SAMSUNG-SGH-A400/1.0 UP/4.1.19k
SAMSUNG-SGH-A400/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-A800/1.0 UP.Browser/5.0.3.3 (GUI)
SAMSUNG-SGH-A800/1.0 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.5a
SAMSUNG-SGH-A800/1.0 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1a
SAMSUNG-SGH-E330/1.0 UP.Browser/6.2.2.6 (GUI) MMP/1.0
SAMSUNG-SGH-E700/BSI UP.Browser/6.1.0.6 (GUI) MMP/1.0
SAMSUNG-SGH-E700/BSI UP.Browser/6.1.0.6 (GUI) MMP/1.0 UP.Link/1.1
SAMSUNG-SGH-E700/BSI UP.Browser/6.1.0.6 (GUI) MMP/1.0 UP.Link/5.1.2.5
SAMSUNG-SGH-E700/BSI2.0 UP.Browser/6.1.0.6 (GUI) MMP/1.0
SAMSUNG-SGH-E700/BSI2.0 UP.Browser/6.1.0.6 (GUI) MMP/1.0 UP.Link/5.1.2.10
SAMSUNG-SGH-E800/1.0 UP.Browser/6.2.2.6 (GUI) MMP/1.0
SAMSUNG-SGH-E800/1.0 UP.Browser/6.2.2.6 (GUI) MMP/1.0 (Google WAP Proxy/1.0)
SAMSUNG-SGH-E820/1.0 UP.Browser/6.2.2.6 (GUI) MMP/1.0
SAMSUNG-SGH-N100/1.0 UP/4.1.19k
SAMSUNG-SGH-N100/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-N100/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.0.0.4
SAMSUNG-SGH-N188/1.0 UP/4.1.19k
SAMSUNG-SGH-N300 UP/4.1.19k
SAMSUNG-SGH-N400 UP/4.1.19k
SAMSUNG-SGH-N400 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-N500/1.0 UP/4.1.19k
SAMSUNG-SGH-N500/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-N500/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.1a
SAMSUNG-SGH-N600/1.0 UP.Browser/4.1.26b
SAMSUNG-SGH-N600/1.0 UP.Browser/4.1.26c4
SAMSUNG-SGH-N600/1.0 UP/4.1.19k
SAMSUNG-SGH-N620/1.0 UP/4.1.19k
SAMSUNG-SGH-N620/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-N620/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.1.4
SAMSUNG-SGH-N620/1.1 UP/4.1.19k
SAMSUNG-SGH-Q100/1.0 UP/4.1.19k
SAMSUNG-SGH-R200/1.0 UP/4.1.19k
SAMSUNG-SGH-R200/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-R200S/1.0 UP/4.1.19k
SAMSUNG-SGH-R200S/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-R210S/1.0 UP/4.1.19k
SAMSUNG-SGH-R210S/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.2.2.1
SAMSUNG-SGH-R210S/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.1.1
SAMSUNG-SGH-R210S/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.1.3
SAMSUNG-SGH-R210S/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.1.4
SAMSUNG-SGH-R210S/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.1.5
SAMSUNG-SGH-R220/1.0 UP/4.1.19k
SAMSUNG-SGH-R220/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/4.3.2.1
SAMSUNG-SGH-S500/SHARK UP.Browser/5.0.4.2 (GUI)
SAMSUNG-SGH-S500/SHARK UP.Browser/5.0.5.1 (GUI)
SAMSUNG-SGH-T100/1.0 UP.Browser/4.1.26c4
SAMSUNG-SGH-T100/1.0 UP.Browser/4.1.26c4 UP.Link/4.2.2.1
SAMSUNG-SGH-T100/1.0 UP.Browser/4.1.26c4 UP.Link/4.3.2
SAMSUNG-SGH-T100/1.0 UP.Browser/4.1.26c4 UP.Link/5.1.0.2
SAMSUNG-SGH-T100/1.0 UP.Browser/4.1.26c4 UP.Link/5.1.1.3
SAMSUNG-SGH-T100/1.0 UP.Browser/4.1.26c4 UP.Link/5.1.1.5a
SAMSUNG-SGH-T100/1.0 UP.Browser/4.1.26c4 UP.Link/5.1.1a
SAMSUNG-SGH-T100/1.0 UP.Browser/5.0.3.1 (GUI)
SAMSUNG-SGH-T100/1.0 UP/4.1.19k
SAMSUNG-SGH-T100/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.1.3
SAMSUNG-SGH-T100/1.0 UP/4.1.19k UP.Browser/4.1.19k-XXXX UP.Link/5.1.2
SAMSUNG-SGH-T200/1.0 UP.Browser/5.0.4.3 (GUI)
SAMSUNG-SGH-T400/1.0 UP.Browser/5.0.4.3 (GUI)
SAMSUNG-SGH-T410/1.0 UP.Browser/5.0.4 (GUI)
SAMSUNG-SGH-T500/1.0 UP.Browser/5.0.5.2.c.1.100 (GUI)
SAMSUNG-SGH-X600/K3 UP.Browser/6.1.0.6 (GUI) MMP/1.0
SAMSUNG-SGH-Z100
SAMSUNG-SGHT100/1.0 UP.Browser/4.1.26b
SAMSUNG-SGHT100/1.0 UP/4.1.19k
SAMSUNG-SGHT108/1.0 UP/4.1.19k
SEC-SGHC100/1.0 UP.Browser/5.0.5.1 (GUI)
SEC-SGHC100/1.0 UP.Browser/5.0.5.1 (GUI) UP.Link/5.1.1.4
SEC-SGHC100/1.0 UP.Browser/5.0.5.1 (GUI) UP.Link/5.1.1.5a
SEC-SGHC100G/1.0 UP.Browser/5.0.5.1 (GUI)
SEC-SGHC100G/1.0 UP.Browser/5.0.5.1 (GUI) (Google
SEC-SGHC100G/1.0 UP.Browser/5.0.5.1 (GUI) (Google WAP Proxy/1.0)
SEC-SGHC100G/1.0 UP.Browser/5.0.5.1 (GUI) UP.Link/5.1.1.5a
SEC-SGHC100G/1.0 UP.Browser/5.0.5.1 (GUI) UP.Link/5.1.2.5
SEC-SGHD100
SEC-SGHE600
SEC-SGHE600 UP.Link/1.1
SEC-SGHE710
SEC-SGHE710/1.0
SEC-SGHE810
SEC-SGHN350/1.0 UP.Browser/5.0.1 (GUI)
SEC-SGHP400
SEC-SGHP400 UP.Link/5.1.2.10
SEC-SGHP400 UP.Link/5.1.2.3
SEC-SGHP510/1.0 UP.Browser/6.2.2.6 (GUI) MMP/1.0
SEC-SGHQ200/1.0 UP.Browser/4.1.24c
SEC-SGHQ200/1.0 UP.Browser/4.1.24i
SEC-SGHQ300/1.0 UP.Browser/5.0.3.2 (GUI)
SEC-SGHS100
SEC-SGHS105 NW.Browser3.01
SEC-SGHS208*MzUxNDEwODkwNjgzNzcw
SEC-SGHS300
SEC-SGHS300 UP.Link/1.1
SEC-SGHS300 UP.Link/5.1.1.4
SEC-SGHS300 UP.Link/5.1.1.5a
SEC-SGHS300 UP.Link/5.1.2.4
SEC-SGHS300M
SEC-SGHS300M UP.Link/5.1.1.4
SEC-SGHS307 UP.Link/5.1.2.1
SEC-SGHT208/1.0 UP.Browser/5.0.3.3 (GUI)
SEC-SGHV200
SEC-SGHV200 UP.Link/1.1
SEC-SGHV200 UP.Link/5.1.0.2
SEC-SGHV200 UP.Link/5.1.1.3
SEC-SGHV200 UP.Link/5.1.1.4
SEC-SGHV200 UP.Link/5.1.1.5a
SEC-SGHV200 UP.Link/5.1.1a
SEC-SGHV200 UP.Link/5.1.2.3
SEC-SGHV200 UP.Link/5.1.2.4
SEC-SGHV200 UP.Link/5.1.2.5
SEC-SGHV205 NW.Browser3.01
SEC-SGHX105 NW.Browser3.01
SEC-SGHX450
SEC-SPHA540 UP.Browser/4.1.26l UP.Link/4.3.3.4a
SEC-SPHN300 UP.Browser/4.1.22b1 UP.Link/5.0.2.8
SEC-scha310 UP.Browser/4.1.26c3
SEC-scha310 UP.Browser/4.1.26c3 UP.Link/5.1.2.3
SEC-schn195 UP.Browser/4.1.26l UP.Link/4.3.4.1
SEC-schn370_WAP_DL UP.Browser/4.1.26b UP.Link/5.0.2.7a
SEC-spha460 UP.Browser/4.1.26c4 UP.Link/5.0.2.8
SEC-spha500 UP.Browser/4.1.26l UP.Link/5.0.2.7a
SEC02 UP.Browser/4.1.22b
SEC02 UP.Browser/4.1.22b1 UP.Link/5.0.2.8
SEC03 UP.Browser/4.1.22c1
SEC07 UP.Browser/4.1.22b
SEC09 UP.Browser/4.1.22b
SEC09 UP.Browser/4.1.22b UP.Link/4.3.3.4
SEC09 UP.Browser/4.1.22b UP.Link/4.3.3.4a
SEC13/n150 UP.Browser/4.1.22b UP.Link/4.3.3.4
SHARP-TM-100/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.6.c.2.101 (GUI) MMP/1.0 UP
SHARP-TQ-GX1/1.0 UP.Browser/6.1.0.5.102 (GUI) MMP/1.0
SHARP-TQ-GX1/1.0 UP.Browser/6.1.0.5.102 (GUI) MMP/1.0 UP.Link/5.1.1a
SHARP-TQ-GX10/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.3.121c (GUI) MMP/1.0 UP.Link/5.1.1.4
SHARP-TQ-GX10/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.3.121c (GUI) MMP/1.0 UP.Link/5.1.2.3
SHARP-TQ-GX10/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.4.128 (GUI) MMP/1.0
SHARP-TQ-GX10/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.4.128 (GUI) MMP/1.0 UP.Link/1.1
SHARP-TQ-GX10/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.4.128 (GUI) MMP/1.0 UP.Link/5.1.1.4
SHARP-TQ-GX10/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.4.128 (GUI) MMP/1.0 UP.Link/5.1.1.5a
SHARP-TQ-GX10/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.4.128 (GUI) MMP/1.0 UP.Link/5.1.1a
SHARP-TQ-GX10/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.4.128 (GUI) MMP/1.0 UP.Link/5.1.2.3
SHARP-TQ-GX10/1.1 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.105 (GUI) MMP/1.0
SHARP-TQ-GX10/1.1 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.105 (GUI) MMP/1.0 UP.Link/5.1.1a
SHARP-TQ-GX10/1.1 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.105 (GUI) MMP/1.0 UP.Link/5.1.2.1
SHARP-TQ-GX10/1.1 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.105 (GUI) MMP/1.0 UP.Link/5.1.2.4
SHARP-TQ-GX10i/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.d.1 (GUI) MMP/1.0
SHARP-TQ-GX10i/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.d.1 (GUI) MMP/1.0 UP
SHARP-TQ-GX10i/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.d.1 (GUI) MMP/1.0 UP.Link/1.1
SHARP-TQ-GX10i/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.d.1 (GUI) MMP/1.0 UP.Link/5.1.2.3
SHARP-TQ-GX10i/1.1 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.d.2 (GUI) MMP/1.0 UP
SHARP-TQ-GX10m/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.d.1 (GUI) MMP/1.0
SHARP-TQ-GX10m/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.6.1.d.1 (GUI) MMP/1.0 UP.Link/5.1.1a
SHARP-TQ-GX12/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.5.119 (GUI) MMP/1.0
SHARP-TQ-GX20/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.2.107 (GUI) MMP/1.0
SHARP-TQ-GX20/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.2.107 (GUI) MMP/1.0 UP.Li
SHARP-TQ-GX20/1.0 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.2.107 (GUI) MMP/1.0 UP.Link/5.1.2.4
SHARP-TQ-GX20/1.0f Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.2.2.2.107 (GUI) MMP/1.0
SIE-2128/17 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.5c
SIE-3618/01 UP.Browser/5.0.1.1.102 (GUI)
SIE-3618/24 UP.Browser/5.0.2.3.100 (GUI)
SIE-6618/01 UP.Browser/5.0.1.1.102 (GUI)
SIE-6618/24 UP.Browser/5.0.2.3.100 (GUI)
SIE-6688/3.1 UP/4.1.19i
SIE-A50/00 UP.Browser/5.0.2.3.100
SIE-A50/01 UP.Browser/5.0.2.3.100 (GUI)
SIE-A50/02 UP.Browser/5.0.2.3.100 (GUI)
SIE-A50/03 UP.Browser/5.0.2.3.100 (GUI)
SIE-A50/03 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1a
SIE-A50/04 UP.Browser/5.0.2.3.100 (GUI)
SIE-A50/07 UP.Browser/5.0.2.3.100 (GUI)
SIE-A55/05 UP.Browser/5.0.3.3.1.e.4 (GUI)
SIE-A55/05 UP.Browser/5.0.3.3.1.e.4 (GUI) UP.Link/5.1.1.4
SIE-A55/05 UP.Browser/5.0.3.3.1.e.4 (GUI) UP.Link/5.1.1a
SIE-A55/07 UP.Browser/5.0.3.3.1.e.4 (GUI)
SIE-C3I/1.0 UP/4.1.8b
SIE-C3I/1.0 UP/4.1.8c
SIE-C3I/1.0 UP/4.1.8c UP.Browser/4.1.8c-XXXX (compatible; YOSPACE SmartPhone Emulator Website Edition 1.9)
SIE-C3I/2.0 UP/4.1.9
SIE-C3I/3.0 UP/4.1.16m
SIE-C3I/3.0 UP/4.1.16m UP.Browser/4.1.16m-XXXX UP.Link/4.2.2.1
SIE-C3I/3.0 UP/4.1.16m UP.Browser/4.1.16m-XXXX UP.Link/5.1.1.3
SIE-C3I/3.0 UP/4.1.16m UP.Browser/4.1.16m-XXXX UP.Link/5.1.1.4
SIE-C45/02 UP.Browser/5.0.1.1.102 (GUI)
SIE-C45/03 UP.Browser/5.0.1.1.102 (GUI)
SIE-C45/06 UP.Browser/5.0.1.1.102 (GUI)
SIE-C45/06 UP.Browser/5.0.1.1.102 (GUI) UP.Link/4.2.2.1
SIE-C45/08 UP.Browser/5.0.1.1.102 (GUI)
SIE-C45/08 UP.Browser/5.0.1.1.102 (GUI) UP.Link/4.2.2.1
SIE-C45/13 UP.Browser/5.0.1.1.102 (GUI)
SIE-C45/14 UP.Browser/5.0.1.1.102 (GUI)
SIE-C45/14 UP.Browser/5.0.1.1.102 (GUI) UP.Link/5.1.1a
SIE-C45/16 UP.Browser/5.0.1.1.102 (GUI)
SIE-C45/16 UP.Browser/5.0.1.1.102 (GUI) UP.Link/4.2.2.1
SIE-C45/16 UP.Browser/5.0.1.1.102 (GUI) UP.Link/5.1.1.3
SIE-C45/17 UP.Browser/5.0.1.1.102 (GUI)
SIE-C45/18 UP.Browser/5.0.1.1.102 (GUI) UP.Link/5.1.0.2
SIE-C45/31 UP.Browser/5.0.2.2 (GUI)
SIE-C45/31 UP.Browser/5.0.2.2 (GUI) UP.Link/5.1.1.3
SIE-C45/33 UP.Browser/5.0.2.3.100 (GUI)
SIE-C45/35 UP.Browser/5.0.2.3.100 (GUI)
SIE-C45/35 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.0.2
SIE-C45/36 UP.Browser/5.0.2.3.100 (GUI)
SIE-C45/38 UP.Browser/5.0.2.3.100 (GUI)
SIE-C55/07 UP.Browser/5.0.3.3 (GUI)
SIE-C55/09 UP.Browser/5.0.3.3 (GUI)
SIE-C55/10 UP.Browser/5.0.2.3.3 (GUI) UP.Link/5.1.1.1
SIE-C55/10 UP.Browser/5.0.3.3 (GUI)
SIE-C55/10 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.2.4
SIE-C55/11 UP.Browser/5.0.3.3 (GUI)
SIE-C55/12 UP.Browser/5.0.3.3 (GUI)
SIE-C55/12 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.5a
SIE-C55/12 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.2.4
SIE-C55/14 UP.Browser/5.0.3.3 (GUI)
SIE-C55/14 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.5a
SIE-C55/14 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.2.5
SIE-C55/18 UP.Browser/5.0.3.3 (GUI)
SIE-C55/18 UP.Browser/5.0.3.3 (GUI) UP.Link/4.2.0.1
SIE-C55/18 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.4
SIE-C55/18 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.5a
SIE-C55/18 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1a
SIE-C55/19 UP.Browser/5.0.3.3 (GUI)
SIE-C55/21 UP.Browser/5.0.3.3 (GUI)
SIE-C55/21 UP.Browser/5.0.3.3 (GUI) UP.Link/4.2.0.1
SIE-C55/21 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.4
SIE-C55/21 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.5
SIE-C55/21 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.1.5a
SIE-C55/21 UP.Browser/5.0.3.3 (GUI) UP.Link/5.1.2.3
SIE-C55/24 UP.Browser/5.0.3.3 (GUI)
SIE-C56/14 UP.Browser/5.0.3.3.1.e.2 (GUI) UP.Link/5.1.2.1
SIE-C56/14 UP.Browser/5.0.3.3.1.e.2 (GUI) UP.Link/5.1.2.1 (Google WAP Proxy/1.0)
SIE-C60/23 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.7.3 (GUI) MMP/1.0
SIE-C62/83 UP.Link/5.1.2.10
SIE-C65/08 UP.Browser/7.0.0.1.181 (GUI) MMP/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.1
SIE-CX65/08 UP.Browser/7.0.0.1.181 (GUI) MMP/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.1
SIE-IC35/1.0
SIE-M46/52 UP.Browser/5.0.2.3.100 (GUI)
SIE-M50/07 UP.Browser/5.0.2.2 (GUI)
SIE-M50/09 UP.Browser/5.0.2.3.100 (GUI)
SIE-M50/09 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1a
SIE-M50/14 UP.Browser/5.0.2.3.100 (GUI)
SIE-M50/16 UP.Browser/5.0.2.3.100 (GUI)
SIE-M50/17 UP.Browser/5.0.2.3.100 (GUI)
SIE-M50/17 UP.Browser/5.0.2.3.100 (GUI) (Google WAP Proxy/1.0)
SIE-M50/17 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.5a
SIE-M50I/81 UP.Browser/5.0.2.3.100 (GUI)
SIE-M50I/81 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.5a
SIE-M55/04 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0
SIE-M55/04 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0 UP.Link/5.1.1.4
SIE-M55/04 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0 UP.Link/5.1.1.5a
SIE-M55/07 UP.Browser/6.1.0.5.c.5 (GUI) MMP/1.0
SIE-M55/07 UP.Browser/6.1.0.5.c.5 (GUI) MMP/1.0 UP.Link/5.1.1.5a
SIE-M55/10 UP.Browser/6.1.0.5.c.6 (GUI) MMP/1.0
SIE-M65/06 UP.Browser/7.0.0.1.181 (GUI) MMP/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 UP.Link/5.1.
SIE-MC60/04 UP.Browser/6.1.0.5.c.6 (GUI) MMP/1.0
SIE-MC60/04 UP.Browser/6.1.0.5.c.6 (GUI) MMP/1.0 UP.Link/5.1.2.5
SIE-MC60/10 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Browser/6.1.0.7.3 (GUI) MMP/1.0
SIE-ME45/04 UP.Browser/5.0.3.1.105 (GUI)
SIE-ME45/05 UP.Browser/5.0.1.1.102 (GUI)
SIE-ME45/06 UP.Browser/5.0.1.1.102 (GUI)
SIE-ME45/07 UP.Browser/5.0.1.1.102 (GUI)
SIE-ME45/09 UP.Browser/5.0.1.1.102 (GUI)
SIE-ME45/09 UP.Browser/5.0.1.1.102 (GUI) UP.Link/4.2.2.1
SIE-ME45/10 UP.Browser/5.0.1.1.102 (GUI)
SIE-ME45/10 UP.Browser/5.0.1.1.102 (GUI) UP.Link/1.1
SIE-ME45/14 UP.Browser/5.0.1.1.102 (GUI)
SIE-ME45/21 UP.Browser/5.0.2.1.103 (GUI)
SIE-ME45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/4.2.2.1
SIE-ME45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/4.3.2.4
SIE-ME45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/5.0.1.1
SIE-ME45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/5.1.1
SIE-ME45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/5.1.1.4
SIE-ME45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/5.1.1.5a
SIE-ME45/23 UP.Browser/5.0.2.2 (GUI)
SIE-ME45/23 UP.Browser/5.0.2.2 (GUI) UP.Link/4.2.2.1
SIE-ME45/23 UP.Browser/5.0.2.2 (GUI) UP.Link/5.1.1.2a
SIE-ME45/24 UP.Browser/5.0.2.3.100 (GUI)
SIE-ME45/24 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.2a
SIE-ME45/24 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.4
SIE-ME45/26 UP.Browser/5.0.2.3.100 (GUI)
SIE-ME45/28 UP.Browser/5.0.2.3.100 (GUI)
SIE-ME45/30 UP.Browser/5.0.2.3.100 (GUI)
SIE-MT50/07 UP.Browser/5.0.2.2 (GUI)
SIE-MT50/09 UP.Browser/5.0.2.3.100 (GUI)
SIE-MT50/09 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.0.2
SIE-MT50/09 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.2a
SIE-MT50/09 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.3
SIE-MT50/09 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.5a
SIE-MT50/09 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.2.5
SIE-MT50/14 UP.Browser/5.0.2.3.100 (GUI)
SIE-MT50/14 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.3
SIE-MT50/17 UP.Browser/5.0.2.3.100 (GUI)
SIE-P35/1.0
SIE-S35/1.0 UP/4.1.8
SIE-S35/1.0 UP/4.1.8c
SIE-S35/1.0 UP/4.1.8c UP.Browser/4.1.8c-XXXX UP.Link/4.2.2.1
SIE-S35/1.0_UP/4.1.8c_UP.Browser/4.1.8c-UP.Link/4.1.0.4_Yahoo
SIE-S35/2.0 UP/4.1.9
SIE-S35/2.0+UP/4.1.9
SIE-S35/3.0 UP/4.1.16m
SIE-S35/3.0 UP/4.1.16m UP.Browser/4.1.16m-XXXX UP.Link/4.2.2.1
SIE-S35/3.0 UP/4.1.16m UP.Browser/4.1.16m-XXXX UP.Link/5.1.0.2
SIE-S35/3.0 UP/4.1.16m UP.Browser/4.1.16m-XXXX UP.Link/5.1.2.4
SIE-S40/2.3 UP/4.1.16r
SIE-S40/2.6 UP/4.1.16r
SIE-S40/2.9 UP/4.1.16r
SIE-S40/3.2 UP/4.1.16r
SIE-S40/4.0 UP/4.1.16u
SIE-S40/5.0 UP/4.1.16u
SIE-S40/9.0 UP/4.1.16u
SIE-S45/00 UP.Browser/5.0.1.1.102 (GUI)
SIE-S45/05 UP.Browser/5.0.1.1.102 (GUI)
SIE-S45/06 UP.Browser/5.0.1.1.102 (GUI)
SIE-S45/06 UP.Browser/5.0.1.1.102 (GUI) UP.Link/4.2.2.1
SIE-S45/06 UP.Browser/5.0.1.1.102 (GUI) UP.Link/4.3.2.4
SIE-S45/09 UP.Browser/5.0.1.1.102 (GUI) UP.Link/4.2.2.1
SIE-S45/09 UP.Browser/5.0.1.1.102 (GUI) UP.Link/5.1.1.4
SIE-S45/10 UP.Browser/5.0.1.1.102 (GUI)
SIE-S45/10 UP.Browser/5.0.1.1.102 (GUI) UP.Link/4.2.2.1
SIE-S45/11 UP.Browser/5.0.1.1.102 (GUI)
SIE-S45/14 UP.Browser/5.0.1.1.102 (GUI)
SIE-S45/14 UP.Browser/5.0.1.1.102 (GUI) UP.Link/5.1.1.2a
SIE-S45/14 UP.Browser/5.0.1.1.102 (GUI) UP.Link/5.1.1.5
SIE-S45/14 UP.Browser/5.0.1.1.102 (GUI) UP.Link/5.1.1.5a
SIE-S45/20 UP.Browser/5.0.2.1.103 (GUI)
SIE-S45/21 UP.Browser/5.0.2.1.103 (GUI)
SIE-S45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/4.2.2.1
SIE-S45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/5.0.1.1
SIE-S45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/5.1
SIE-S45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/5.1.1.2a
SIE-S45/21 UP.Browser/5.0.2.1.103 (GUI) UP.Link/5.1.1.5a
SIE-S45/23 UP.Browser/5.0.2.2 (GUI)
SIE-S45/23 UP.Browser/5.0.2.2 (GUI) UP.Link/4.2.2.1
SIE-S45/23 UP.Browser/5.0.2.2 (GUI) UP.Link/5.1.1.4
SIE-S45/23 UP.Browser/5.0.2.2 (GUI) UP.Link/5.1.1.5
SIE-S45/23 UP.Browser/5.0.2.2 (GUI) UP.Link/5.1.1.5a
SIE-S45/23 UP.Browser/5.0.2.2 (GUI) UP.Link/5.1.1a
SIE-S45/24 UP.Browser/5.0.2.3.100 (GUI)
SIE-S45/24 UP.Browser/5.0.2.3.100 (GUI) UP.Link/4.2.2.1
SIE-S45/26 UP.Browser/5.0.2.3.100 (GUI)
SIE-S45/28 UP.Browser/5.0.2.3.100 (GUI)
SIE-S45/28 UP.Browser/5.0.2.3.100 (GUI) (Google WAP Proxy/1.0)
SIE-S45/28 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.1.5a
SIE-S45/30 UP.Browser/5.0.2.3.100 (GUI)
SIE-S45/30 UP.Browser/5.0.2.3.100 (GUI) UP.Link/5.1.2.5
SIE-S45/4.0 UP.Browser/5.0.1.2 (GUI)
SIE-S45/4.0 UP.Browser/5.0.1.2 (GUI) UP.Link/5.0.2.1
SIE-S45/4.0 UP.Browser/5.0.1.2 (GUI) UP.Link/5.1
SIE-S45/4.0 UP/5.0.1.2 (GUI) UP.Browser/5.0.1.2 (GUI)-XXXX UP.Link/5.0.HTTP-DIRECT
SIE-S45i/02 UP.Browser/5.0.3.1.105 (GUI)
SIE-S45i/02 UP.Browser/5.0.3.1.105 (GUI) UP.Link/5.1.0.2
SIE-S45i/03 UP.Browser/5.0.3.1.105 (GUI)
SIE-S45i/04 UP.Browser/5.0.3.1.105 (GUI)
SIE-S45i/04 UP.Browser/5.0.3.1.105 (GUI) UP.Link/5.1.1a
SIE-S55/04 UP.Browser/6.1.0.5.119 (GUI) MMP/1.0
SIE-S55/04 UP.Browser/6.1.0.5.119 (GUI) MMP/1.0 UP.Link/5.1.0.2
SIE-S55/04 UP.Browser/6.1.0.5.119 (GUI) MMP/1.0 UP.Link/5.1.1.4
SIE-S55/04 UP.Browser/6.1.0.5.119 (GUI) MMP/1.0 UP.Link/5.1.1a
SIE-S55/04 UP.Browser/6.1.0.5.119 (GUI) MMP/1.0 UP.Link/5.1.2.4
SIE-S55/05 UP.Browser/6.1.0.5.121 (GUI) MMP/1.0
SIE-S55/05 UP.Browser/6.1.0.5.121 (GUI) MMP/1.0 UP.Link/5.1.1.4
SIE-S55/05 UP.Browser/6.1.0.5.121 (GUI) MMP/1.0 UP.Link/5.1.1.5a
SIE-S55/05 UP.Browser/6.1.0.5.121 (GUI) MMP/1.0 UP.Link/5.1.2.5
SIE-S55/08 UP.Browser/6.1.0.5.c.1 (GUI) MMP/1.0
SIE-S55/09 UP.Browser/6.1.0.5.c.1 (GUI) MMP/1.0
SIE-S55/10 UP.Browser/6.1.0.5.c.2 (GUI) MMP/1.0
SIE-S55/11 UP.Browser/6.1.0.5.c.2 (GUI) MMP/1.0
SIE-S55/11 UP.Browser/6.1.0.5.c.2 (GUI) MMP/1.0 UP.Link/5.1.1.5a
SIE-S55/12 UP.Browser/6.1.0.5.c.2 (GUI) MMP/1.0
SIE-S55/12 UP.Browser/6.1.0.5.c.2 (GUI) MMP/1.0 UP.Link/5.1.2.5
SIE-S55/16 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0
SIE-S55/16 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0 (Google WAP Proxy/1.0)
SIE-S55/16 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0 UP.Link/5.1.1.5a
SIE-S55/16 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0 UP.Link/5.1.1a
SIE-S55/20 UP.Browser/6.1.0.5.c.6 (GUI) MMP/1.0
SIE-S55/20 UP.Browser/6.1.0.5.c.6 (GUI) MMP/1.0 UP.Link/1.1
SIE-S55/20 UP.Browser/6.1.0.5.c.6 (GUI) MMP/1.0 UP.Link/5.1.1.4
SIE-S57/05 UP.Browser/6.1.0.5.121 (GUI) MMP/1.0
SIE-S57/05 UP.Browser/6.1.0.5.121 (GUI) MMP/1.0 UP.Link/5.1.2.5
SIE-SL45/1.0 (ccWAP-Browser)
SIE-SL45/3.1 UP/4.1.19i
SIE-SL45/3.1 UP/4.1.19i UP.Browser/4.1.19i-XXXX UP.Link/4.2.2.1
SIE-SL45/3.1 UP/4.1.19i UP.Browser/4.1.19i-XXXX UP.Link/4.2.2.9
SIE-SL45/3.1 UP/4.1.19i UP.Browser/4.1.19i-XXXX UP.Link/4.3.2.4
SIE-SL55/00 UP.Browser/6.1.0.5.c.1 (GUI) MMP/1.0
SIE-SL55/05 UP.Browser/6.1.0.5.c.2 (GUI) MMP/1.0
SIE-SL55/07 UP.Browser/6.1.0.5.c.2 (GUI) MMP/1.0
SIE-SL55/09 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0
SIE-SL55/09 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0 UP.Link/5.1.1.4
SIE-SL55/09 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0 UP.Link/5.1.2.3
SIE-SL55/09 UP.Browser/6.1.0.5.c.4 (GUI) MMP/1.0 UP.Link/5.1.2.5
SIE-SL55/12 UP.Browser/6.1.0.5.c.5 (GUI) MMP/1.0
SIE-SL55/14 UP.Browser/6.1.0.5.c.5 (GUI) MMP/1.0
SIE-SL55/14 UP.Browser/6.1.0.5.c.5 (GUI) MMP/1.0 UP.Link/5.1.2.10
SIE-SLIK/3.1 UP/4.1.19i
SIE-SLIN/3.1 UP/4.1.19i UP.Browser/4.1.19i-XXXX UP.Link/5.1.0.2
SIE-ST60/1.0 UP.Browser/6.1.0.7.4 (GUI) MMP/1.0 UP.Link/5.1.2.10
SIE-SX1/1.1 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
Sanyo-C304SA/2.0 UP/4.1.20e
Sanyo-SCP5000/1.1b UP.Browser/4.1.23a
Sanyo-SCP6200/1.1 UP.Browser/4.1.26c UP.Link/5.0.2.7
SendoM550/226-E-09
SendoM550/226-E-10
SendoS330/14A-G-02
SendoS600/03
SendoX/1.0 SymbianOS/6.1 Series60/1.2 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonK700i/R2A SEMC-Browser/4.0 Profile/MIDP-1.0 MIDP-2.0 Configuration/CLDC-1.1
SonyEricssonP800
SonyEricssonP800/P201 Profile/MIDP-2.0 Configuration/CLDC-1.0
SonyEricssonP800/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonP800/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
SonyEricssonP800/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
SonyEricssonP800/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
SonyEricssonP800/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
SonyEricssonP800/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
SonyEricssonP800/R102 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonP800/R102 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonP900/R101 Profile/MIDP-2.0 Configuration/CLDC-1.0
SonyEricssonP900/R102 Profile/MIDP-2.0 Configuration/CLDC-1.0
SonyEricssonT100/R101
SonyEricssonT200/R101
SonyEricssonT200/R101 UP.Link/1.1
SonyEricssonT200/R101 UP.Link/4.2.0.1
SonyEricssonT200/R101 UP.Link/5.1.0.2
SonyEricssonT200/R101 UP.Link/5.1.1.4
SonyEricssonT200/R101 UP.Link/5.1.1.5a
SonyEricssonT200/R101 UP.Link/5.1.2.4
SonyEricssonT230/R101
SonyEricssonT300/R101
SonyEricssonT300/R101 UP.Link/5.1.1.2a
SonyEricssonT300/R101 UP.Link/5.1.1.3
SonyEricssonT300/R101 UP.Link/5.1.1.4
SonyEricssonT300/R101 UP.Link/5.1.1.5
SonyEricssonT300/R101 UP.Link/5.1.1.5a
SonyEricssonT300/R101 UP.Link/5.1.1a
SonyEricssonT300/R101 UP.Link/5.1.2.5
SonyEricssonT300/R101-WG
SonyEricssonT300/R201
SonyEricssonT300/R201 UP.Link/5.1.1.4
SonyEricssonT300/R201 UP.Link/5.1.1.5
SonyEricssonT300/R201 UP.Link/5.1.1.5a
SonyEricssonT300/R201 UP.Link/5.1.2.3
SonyEricssonT300/R201 UP.Link/5.1.2.4
SonyEricssonT300/R201 UP.Link/5.1.2.5
SonyEricssonT306/R101 UP.Link/5.1.1.1a
SonyEricssonT306/R101 UP.Link/5.1.2.1
SonyEricssonT310/R201
SonyEricssonT310/R201 UP.Link/5.1.1.5a
SonyEricssonT310/R201 UP.Link/5.1.1a
SonyEricssonT312/R201
SonyEricssonT316/R101
SonyEricssonT316/R101 UP.Link/5.1.2.1
SonyEricssonT600
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/4.2.0.1
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.0.2
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.3
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5a
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.1
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.3
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.4
SonyEricssonT610/R101 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.5
SonyEricssonT610/R201 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonT610/R201 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonT610/R201 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.4
SonyEricssonT610/R201 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1a
SonyEricssonT610/R201 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.2.10
SonyEricssonT610/R301 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonT610/R301 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonT610/R401 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonT610/R401 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonT610/R601 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonT610/R601 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonT630/R401 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonT630/R401 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonT630/R601 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonT630/R601 Profile/MIDP-1.0 Configuration/CLDC-1.0 (Google WAP Proxy/1.0)
SonyEricssonT68
SonyEricssonT68/R201A
SonyEricssonT68/R201A (compatible; YOSPACE SmartPhone Emulator Website Edition 1.11)
SonyEricssonT68/R201A (compatible; YOSPACE SmartPhone Emulator Website Edition 1.14)
SonyEricssonT68/R201A Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonT68/R201A UP.Link/4.1.0.9b
SonyEricssonT68/R201A UP.Link/4.2.0.1
SonyEricssonT68/R201A UP.Link/4.2.2.1
SonyEricssonT68/R201A UP.Link/4.3.2
SonyEricssonT68/R201A UP.Link/4.3.2.4
SonyEricssonT68/R201A UP.Link/5.0.2.3d
SonyEricssonT68/R201A UP.Link/5.01
SonyEricssonT68/R201A UP.Link/5.1.0.2
SonyEricssonT68/R201A UP.Link/5.1.1.4
SonyEricssonT68/R201A UP.Link/5.1.1.5a
SonyEricssonT68/R201A UP.Link/5.1.1.5c
SonyEricssonT68/R201A UP.Link/5.1.1a
SonyEricssonT68/R201A UP.Link/5.1.2.3
SonyEricssonT68/R201A UP.Link/5.1.2.4
SonyEricssonT68/R201A-WG
SonyEricssonT68/R301A
SonyEricssonT68/R301A UP.Link/5.1.1.1a
SonyEricssonT68/R301A UP.Link/5.1.2.1
SonyEricssonT68/R401
SonyEricssonT68/R401 UP.Link/5.1.1.5a
SonyEricssonT68/R401A
SonyEricssonT68/R501
SonyEricssonT68/R501 (Google WAP Proxy/1.0)
SonyEricssonT68/R501 UP.Link/1.1
SonyEricssonT68/R501 UP.Link/5.1.1.4
SonyEricssonT68/R501 UP.Link/5.1.1.5a
SonyEricssonT68/R501 UP.Link/5.1.1a
SonyEricssonT68/R501 UP.Link/5.1.2.3
SonyEricssonT68/R501 UP.Link/5.1.2.4
SonyEricssonT68/R502
SonyEricssonT68/R502 UP.Link/1.1
SonyEricssonT68/R502 UP.Link/5.1.1.2a
SonyEricssonT68/R502 UP.Link/5.1.1.4
SonyEricssonT68/R502 UP.Link/5.1.1.5a
SonyEricssonT68/R502 UP.Link/5.1.1a
SonyEricssonT68/R502 UP.Link/5.1.2.4
SonyEricssonT68/R502 UP.Link/5.1.2.5
SonyEricssonT68i/R101
SonyEricssonZ1010/R1A Profile/MIDP-1.0 MIDP2.0 Configurationn/CLDC-1.1 UP.Link/5.1.1.5
SonyEricssonZ1010/R1E SEMC-Browser/4.0 Profile/MIDP-1.0 MIDP-2.0 Configuration/CLDC-1.1
SonyEricssonZ1010/R1G SEMC-Browser/4.0 Profile/MIDP-2.0 Configuration/CLDC-1.1
SonyEricssonZ200/R101
SonyEricssonZ600/R301 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonZ600/R301 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonZ600/R401 Profile/MIDP-1.0 Configuration/CLDC-1.0
SonyEricssonZ600/R401 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/1.1
SonyEricssonZ600/R601 Profile/MIDP-1.0 Configuration/CLDC-1.0
TSM-100
TSM-100/141053B7 Browser/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
TSM-100/141053B9 Browser/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
TSM-100/141053BB Browser/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
TSM-100/141053BB Browser/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.1.5
TSM-100v/40100012 Browser/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
TSM-5/2.2 UP.Browser/5.0.2.2 (GUI)
TSM-5m/1.3.8.5 UP.Browser/6.2.2.4.g.1.100 (GUI)
TSM-6/7.12.2 Teleca/1.1.13.4 Profile/MIDP-1.0 Configuration/CLDC-1.0 UP.Link/5.1.15
TSM100v/40100012 Browser/1.2.1 Profile/MIDP-1.0 Configuration/CLDC-1.0
Telit-G80/2.01 UP.Browser/6.1.0.6 (GUI) MMP/1.0
Telit_Mobile_Terminals-GM882/1.02 UP.Browser/5.0.3.3 (GUI)
Vitelcom-Feature Phone1.0 UP.Browser/5.0.2.2(GUI)
mozilla/4.0 (compatible;MSIE 4.01; Windows CE;PPC;240X320) UP.Link/5.1.1.5
portalmmm/1.0 TS21i-10(;ser123456789012345;icc1234567890123456789F)
portalmmm/1.0 TS21i-10(c10)
portalmmm/1.0 m21i-10(c10)
portalmmm/1.0 n21i-10(;ser123456789012345;icc1234567890123456789F)
portalmmm/1.0 n21i-10(c10)
portalmmm/1.0 n21i-10(c10) (;; ;; ;; ;)
portalmmm/1.0 n21i-10(c10) (;; ;; ;; ;; 240x320)
portalmmm/1.0 n21i-20(c10)
portalmmm/1.0 n22i-10(;ser123456789012345;icc1234567890123456789F)
portalmmm/1.0 n22i-10(c10)
portalmmm/2.0 M341i(c10;TB)
portalmmm/2.0 N223i(c10;TB)
portalmmm/2.0 N341i(c10;TB)
portalmmm/2.0 N400i(c20;TB)
portalmmm/2.0 N410i(c20;TB)
portalmmm/2.0 P341i(c10;TB)
portalmmm/2.0 S341i(c10;TB)
portalmmm/1.0 m21i-10(c10)
portalmmm/2.0 TS21i-10(c10)
portalmmm/2.0 N401i (c20;TB)
portalmmm/1.0 n22i-10(c10)
portalmmm/1.0 n21i-xx(c10)
portalmmm/2.0 SG341i(c10;TB)
portalmmm/2.0 L341i(c10;TB)
portalmmm/2.0 SI400i(c10;TB)