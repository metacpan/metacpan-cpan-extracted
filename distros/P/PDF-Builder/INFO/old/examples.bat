echo off
echo "=== examples >logfile 2>&1    to preserve all output for inspection"
echo "=== follow along with examples.output to check output PDF files"
echo on
perl examples\011_open_update
perl examples\012_pages
perl examples\020_corefonts
perl examples\020_textrise
perl examples\020_textunderline
echo off
echo === 021_psfonts needs T1 glyph and metrics files (not included)
echo     here, assuming metrics file (.afm or .pfm) is in same directory
echo on
perl examples\021_psfonts \Users\Phil\T1fonts\URWPalladioL-Roma.pfb
perl examples\021_synfonts
perl examples\022_truefonts C:\WINDOWS\fonts\times.ttf
perl examples\022_truefonts_diacrits_utf8 C:\WINDOWS\fonts\tahoma.ttf
echo off
echo === 023 to display the PDFs, you may need to install East Asian fonts
echo ===     for your browser
echo on
perl examples\023_cjkfonts
echo off
echo === 024 needs a sample BDF font (not included with distribution)
echo on
perl examples\024_bdffonts \Users\Phil\BDFfonts\codec\codec.bdf
perl examples\025_unifonts
perl examples\026_unifont2
REM perl examples\027_winfont
perl examples\030_colorspecs
perl examples\031_color_hsv
perl examples\032_separation
perl examples\040_annotation
perl examples\041_annot_fileattach
perl examples\050_pagelabels
perl examples\055_outlines
perl examples\060_transparency
perl examples\BarCode.pl
perl examples\Boxes.pl
perl examples\Bspline.pl
perl examples\Content.pl
perl examples\ContentText.pl
REM disable next line if HarfBuzz::Shaper is not installed, 
REM and you will need to update font file paths
perl examples\HarfBuzz.pl
perl examples\RMtutorial.pl
perl examples\Rotated.pl
perl examples\ShowFont.pl Helvetica
echo off
echo === do not erase files if you are going to run "contrib.bat"
echo on
