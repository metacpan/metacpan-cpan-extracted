# compute average flux and count number of observations in each bin with GMT
#
# you need the Generic Mapping Tools (GMT) to be installed on your system for
# this script: http://gmt.soest.hawaii.edu

# you may not need this
PATH=/usr/lib/gmt/bin:$PATH
export PATH

# -F: force pixel node registration
perl -wlna -e 'print "$F[0] $F[1] $F[3]"' ??.txt | xyz2grd -R-60/60/-60/60 -Gex03avg.nc -I40 -F
perl -wlna -e 'print "$F[0] $F[1] $F[3]"' ??.txt | xyz2grd -R-60/60/-60/60 -Gex03cnt.nc -I40 -F -An
echo "Average:"
ncdump ex03avg.nc
echo
echo "Count:"
ncdump ex03cnt.nc
rm .gmt*
