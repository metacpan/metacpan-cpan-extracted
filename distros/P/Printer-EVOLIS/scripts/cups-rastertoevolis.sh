#!/bin/sh -x

export PPD=/etc/cups/ppd/EVOLIS_Dualys.ppd
/usr/lib/cups/filter/rastertoevolis 42 dpavlin foobar 0 Duplex=DuplexNoTumble $1
