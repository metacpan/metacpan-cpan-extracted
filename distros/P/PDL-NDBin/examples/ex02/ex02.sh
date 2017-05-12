# visualize the effect of the example with GMT; black dots represent the
# original data and red dots represent the averaged data
#
# you need the Generic Mapping Tools (GMT) to be installed on your system for
# this script: http://gmt.soest.hawaii.edu
#
# this script has been modified from example 14 of the GMT Cookbook

# you may not need this
PATH=/usr/lib/gmt/bin:$PATH
export PATH

ps=ex02.ps

gmtset GRID_PEN_PRIMARY thinnest,-
gmtset PAPER_MEDIA custom_5ix5i
psxy table -R0/7/0/7 -JX3i/3i -B2f1WSne -Sc0.05i -Gblack -P -K > $ps
# uncomment this statement to see elevation in black
#perl -nwae 'next if /^#/; printf "%g %g 6 0 0 LM %g\n", $F[0]+0.08, $F[1], $F[2]' table | pstext -R -J -O -K -N -Gblack >> $ps
psbasemap -R0.5/7.5/0.5/7.5 -J -B0g1 -O -K >> $ps
perl -Mblib ex02.pl
grep -v BAD mean | psxy -R0/7/0/7 -J -Sc0.05i -Gred -O >> $ps
# uncomment this statement to see interpolated elevation in red
#perl -nwae 'next if /BAD/; printf "%g %g 6 0 0 LM %g\n", $F[0]+0.08, $F[1], $F[2]' mean | pstext -R -J -O -K -N -Gred >> $ps
rm .gmt*
