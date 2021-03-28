REM this should be simple enough to convert to a bash script
echo off
echo === do not erase examples/ PDF files yet... they are used here

echo == combine_pdfs.pl
contrib\combine_pdfs.pl examples\011_open_update.BASE.pdf examples\012_pages.pdf examples\011_open_update.UPDATED.pdf ./combined.pdf
echo === output to combined.pdf 15 pages: Hello World, sequence i ii iii 1 9 2..8 pages,
echo ===                                  Hello World and Hello World (2)
echo === note different page sizes used

echo == pdf-debug.pl
contrib\pdf-debug.pl combined.pdf
echo === lists version, some other information
contrib\pdf-debug.pl combined.pdf obj 2
echo === describes a Pages type object
contrib\pdf-debug.pl combined.pdf xref
echo === lists the cross reference

echo == pdf-deoptimize.pl
contrib\pdf-deoptimize.pl combined.pdf combined.deopt.pdf
echo === outputs combined.deopt.pdf, PDF v1.2 and smaller than original
echo === no idea what "de-optimize" does, only that it produces a working PDF

echo == pdf-optimize.pl
contrib\pdf-optimize.pl combined.pdf combined.opt.pdf
echo === outputs combined.opt.pdf, PDF v1.2 and same size as original
echo === no idea what "optimize" does, only that it produces a working PDF

echo == text2pdf.pl
contrib\text2pdf.pl contrib\text2pdf.pl
echo === output to text2pdf.pl.pdf  paginated listing of program

echo === now you can erase the examples/ output files
