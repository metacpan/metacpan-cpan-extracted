#!/bin/bash

name="$1"
shift;

file="$2"
shift;

if [ -z "$name" ]; then
  echo "Usage: $0 <base_name>"
  exit 1;
fi
if [ -z "$file" ]; then
  file=-
fi

if [ -f "${name}.tex" ]; then
  mv "${name}.tex" "${name}.tex.orig"
else
  rm "${name}.tex.orig";
fi

cat <<'EOF' > "${name}.tex"
\documentclass{article}
\pdfoutput=1
\usepackage{bold-extra}
\usepackage{color}
\usepackage{rail}
\usepackage{pict2e}
\usepackage[scaled]{helvet}
\renewcommand*\familydefault{\sfdefault}
\railoptions{-h}
\def\~{\char'176}
\railtoken{DOLLAR}{\$}
\railtoken{TILDA}{\lower 3pt\hbox{\large\~}}
\railtoken{TILDASTAR}{\lower 3pt\hbox{\large\~{}}*}
\railtoken{LEFTBRACE}{\{}
\railtoken{RIGHTBRACE}{\}}
\railtoken{AMP}{\&}
\railtermfont{\ttfamily\upshape\bfseries}
\railnontermfont{\sffamily\upshape} 
\railannotatefont{\rmfamily\itshape}
\railnamefont{\sffamily\itshape} 
\railindexfont{\sffamily\itshape}
\pagestyle{empty}
\textwidth=60cm
\textheight=60cm
\setlength{\pdfpagewidth}{\textwidth}
\setlength{\pdfpageheight}{\textheight}
\begin{document}
\begin{rail}
EOF

cat "$file" >> "${name}.tex"
echo '\end{rail}' >> "${name}.tex"
echo '\end{document}' >> "${name}.tex"

if [ -f "${name}.tex.orig" ] && cmp "${name}.tex" "${name}.tex.orig"; then
    echo "${name}.tex is up to date"
    rm "${name}.tex.orig"
    exit 0;
else 
    rm "${name}.tex.orig";
fi

pdflatex "${name}" && \
rail "${name}" && \
pdflatex "${name}" && \
pdfcrop "${name}.pdf" "${name}_crop.pdf" && \
mv "${name}_crop.pdf" "${name}.pdf" &&
convert -density 100 "${name}.pdf" "${name}.png"
