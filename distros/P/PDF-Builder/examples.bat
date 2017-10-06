echo === examples >logfile 2>&1    to preserve all output for inspection
echo === follow along with examples.output to check output PDF files
perl examples\011_open_update
perl examples\012_pages
perl examples\020_corefonts
perl examples\020_textrise
perl examples\020_textunderline
echo === 021_psfonts needs T1 glyph and metrics files (not included)
echo     here, assuming metrics file (.afm or .pfm) is in same directory
perl examples\021_psfonts ..\URWPalladioL-Roma.pfb
perl examples\021_synfonts
perl examples\022_truefonts C:\WINDOWS\fonts\times.ttf
perl examples\022_truefonts_diacrits_utf8 C:\WINDOWS\fonts\tahoma.ttf
perl examples\023_cjkfonts
echo === 024 needs a sample BDF font (not included with distribution)
perl examples\024_bdffonts ..\PDFAPI2-work\codec\codec.bdf
echo === 025 will fail with error messages about a bad UTF-8 character
perl examples\025_unifonts
perl examples\026_unifont2
REM perl examples\027_winfont
perl examples\030_colorspecs
perl examples\031_color_hsv
perl examples\032_separation
perl examples\040_annotation
perl examples\050_pagelabels
perl examples\060_transparency
perl examples\BarCode.pl
perl examples\Content.pl
perl examples\ContentText.pl
echo === do not erase files if you are going to run "contrib.bat"
