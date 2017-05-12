#!/bin/sh

# Convert SVG to EPS
inkscape -E design1.eps design1.svg
inkscape -E design2.eps design2.svg

# eg1.pdf: Only one design, filling up the page
pslabelsheet --rows=10 --columns=5 --eps=design1.eps | ps2pdf - eg1.pdf

# eg2.pdf: 8 × design1, 10 × design2
pslabelsheet --no-fill-last-page --rows=8 --columns=3 \
    --skip=4 --no-grid \
    --eps=design1.eps --count=8 \
    --eps=design2.eps --count=10 | ps2pdf - eg2.pdf
