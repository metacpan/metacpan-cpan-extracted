#!/bin/sh
curl 'http://www.yes24.com/24/goods/9199924?Gcode=000_031_002' | iconv -f euc-kr -t utf-8 | tidy -utf8 | perl semantic_html.pl > out1.txt
curl 'http://www.yes24.com/24/goods/9197687?Gcode=000_031_003' | iconv -f euc-kr -t utf-8 | tidy -utf8 | perl semantic_html.pl > out2.txt
diff out1.txt out2.txt > diff.txt
echo vi diff.txt      
