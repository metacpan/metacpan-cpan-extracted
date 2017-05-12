xalan -XSL empty.xsl -IN $1 | perl -ne 'print unless /^(\w*)$/' > $$
mv $$ $(dirname $1)/$(basename $1 .xml).clean.xml
echo rm $1
