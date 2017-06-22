#!/bin/bash
# tex2bitmap.sh     pajas@ufal.mff.cuni.cz     2009/02/20 14:12:46

file="$1"
job="tex2bitmap_$$"

sed 's,\(\\pagestyle{empty}\),\\textwidth=60cm\n\\textheight=10cm\n\\setlength{\\pdfpagewidth}{\\textwidth}\n\\setlength{\\pdfpageheight}{\\textheight}\n\1,;s,\(\\documentclass{article}\),\1\n\\usepackage{amsmath}\n,' \
    < "$file" > "${job}.tex" || exit 1
pdflatex "$job" || exit 2
pdfcrop "${job}.pdf" "${job}.crop.pdf" || exit 2
pdftk "${job}.crop.pdf" burst output "${job}.%03d.pdf" || exit 3

s=1;
grep 'dvi2bitmap output' < "$file" | sed 's/.*{dvi2bitmap outputfile \(.*\)}/\1/' | while read output_file; do
    d=$(printf "%03d" $s)
    pdf="${job}.${d}.pdf"
    outpdf="${output_file%.*}.pdf"
    mv "${job}.${d}.pdf" "${outpdf}"
    convert -density 110 "${outpdf}" "${output_file}"
    s=$((s+1))
done
rm "${job}".*
