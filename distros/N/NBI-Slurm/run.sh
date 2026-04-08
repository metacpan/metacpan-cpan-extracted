docker run --rm \
      -v $PWD:/data \
      -u $(id -u):$(id -g) \
      pandoc/extra \
      paper/paper.md \
      --lua-filter=paper/joss-meta.lua \
      --citeproc \
      --bibliography=paper/paper.bib \
      --template=eisvogel \
      --resource-path=paper \
      -V geometry:margin=1in \
      -V titlepage=true \
      -V titlepage-color=FFFFFF \
      -V titlepage-text-color=000000 \
      -V titlepage-rule-color=AAAAAA \
      -V titlepage-rule-height=2 \
      -V mainfont="DejaVu Sans" \
      -V monofont="DejaVu Sans Mono" \
      -V fontsize=11pt \
      -o paper/paper_plain.pdf    
