#!/bin/sh -x

# ./gs-cups-raster.sh < out/200900000042.print-duplex.pdf > dump/duplex.cups

/usr/bin/gs -dQUIET -dPARANOIDSAFER -dNOPAUSE -dBATCH -sDEVICE=cups -sstdout=%stderr -sOutputFile=%stdout -I/usr/share/cups/fonts -sMediaColor=k -sMediaType=Card -r300x300 -dDEVICEWIDTHPOINTS=243 -dDEVICEHEIGHTPOINTS=155 -dcupsBitsPerColor=8 -dcupsColorOrder=0 -dcupsColorSpace=1 -scupsPageSizeName=Card -c -f -

