set terminal postscript landscape enhanced  color solid "Helvetica" 14
set output "OUTPUT.ps"

LOGSCALE

#set xtics XTICS
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "LEGENDTITLE" 

set title "PLOTTITLE" "Helvetica,18"
set xlabel "XLABEL" "Helvetica,16"
set ylabel "YLABEL" "Helvetica,16"

#plot lines
plot 'RESULTSFILENAME' using ($XCOL*1):($YCOL/NORMVAR) title "LEGENDENTRY" with linespoints lw 4 ps 2
