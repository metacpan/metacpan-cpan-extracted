#!/bin/sh

# gids.omroep.nl spider script; 
# proof of concept

USERAGENT="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5a) Gecko"

# get cookie
TMPFILE=`mktemp`
wget -O /dev/null -o $TMPFILE -U $USERAGENT -S http://gids.omroep.nl/
COOKIE=`egrep '\s*[0-9]+ Set-Cookie:' $TMPFILE |sed 's/^.*\(EPGSESSID=.*\);.*$/\1/'`
rm $TMPFILE

wget -q -O- -U $USERAGENT --header "Cookie: $COOKIE" http://gids.omroep.nl/core/content.php

# nu zijn de zenderoverzichten op te vragen met de volgende link:
# http://gids.omroep.nl/core/content.php?Z=&dag=0&tijd=hele+dag&genre=Alle+genres&Z1=on
#
# dag=0: vandaag, 1: morgen, 2: overmorgen, -1: gisteren, -2: eergisteren
# let op: dag start om 6:00 uur
#
# tijd=hele+dag: hele dag, ochtend: 5-12uur, middag: 12-18uur, avond:
# 18-23uur, nacht: 23-6uur
#
# genre= een van de volgende:
# Alle+genres, Amusement, Animatie, Comedy, Documentaire, Erotiek, Film,
# Informatief, Jeugd, Kunst%2FCultuur, Misdaad, Muziek, Natuur,
# Nieuws%2Factualiteiten, Religieus, Serie%2FSoap, Sport, Wetenschap, Overige
#
# zenders:
# Z1,Z2,Z3: Nederland 1, 2, 3
# Z4,Z5,Z6: RTL4, RTL5, Yorin
# Z7,Z8,Z9: SBS6, NET5, V8
# Z10,Z11,Z12: TMF, MTV, Eurosport
# Z14,Z15: AT5, BVN-TV
# Z16,Z17: VTR1,KetNet/Canvas
# Z18,Z19: BBC1,BBC2
# Z20,Z21,Z22,Z23,Z24: ARD,ZDF,NDR,WDF,Südwest
# Z25: RTL
# Z26: CNN
# Z27: Cartoon Network
# Z28,Z29: Discovery, NGC
# Z30,Z31,Z32,Z33: TVE,TV5,RaiUno,TRTint
# Z34,Z35,Z36: Canal+rood,Canal+blauw,TCM
# Z38: Animal Planet
# Z39,Z40,Z41,Z42,Z43: RTBF1,RTBF2,VTM,VT4,Kanaal2
# Z44: BBC World
# Z45,Z46,Z47: Pro7, Sat1, 3Sat
# Z67: Mezzo
# Z68: Nickelodeon
# Z69,Z70,Z71,Z72,Z73: Noord,Omrop Fryslân,Drente,Oost,TV Gelderland
# Z74,Z75: Omroep Flevoland, Regio TV Utrecht
# Z76,Z77,Z78: TV-Noordholland, TV-West, TV-Rijnmond
# Z79,Z80,Z81: Omroep Brabant, L1TV, Omroep Zeeland

