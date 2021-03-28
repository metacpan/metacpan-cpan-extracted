echo off
REM This should be simple enough to convert to a bash script. Or, you can
REM run Makefile.PL to create the Makefile, and do a "make test" to run all
REM these tests (you may even be able to do this without having yet installed
REM PDF::Builder!). You can also look at ways (such as with the "prove" command)
REM to run arbitrary versions of the product. Most often, you would run the t
REM tests as a regression bucket after making any changes to PDF::Builder
REM itself (in development). To each his own!
echo "=== use  |more  filter to page through test results"
echo "===   or |grep -v \"^ok\" |more   to catch failing results. "
echo on
perl t\00-all-usable.t
perl t\01-basic.t
perl t\02-xrefstm.t
perl t\03-xrefstm-index.t
perl t\annotate.t
perl t\author-critic.t
perl t\author-pod-syntax.t
perl t\barcode.t
perl t\bbox.t
perl t\circular-references.t
perl t\cmap.t
perl t\content.t
perl t\cs-webcolor.t
perl t\deprecations.t
perl t\extgstate.t
perl t\filter-ascii85decode.t
perl t\filter-asciihexdecode.t
perl t\filter-runlengthdecode.t
perl t\font-corefont.t
perl t\font-synfont.t
perl t\font-ttf.t
perl t\font-type1.t
perl t\gd.t
perl t\gif.t
perl t\jpg.t
perl t\lite.t
perl t\outline.t
perl t\page.t
perl t\papersizes.t
perl t\pdf.t
perl t\png.t
perl t\pnm.t
perl t\rt67767.t
perl t\rt69503.t
perl t\rt120397.t
perl t\rt120450.t
perl t\rt126274.t
perl t\string.t
perl t\text.t
perl t\tiff.t
perl t\viewer-preferences.t
