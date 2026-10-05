#!/usr/bin/env python3
# Regenerates the pandas expectations frozen in t/read_table.cr_eol.R.pandas.t.
# Run it from the distribution root with `python3 t/read_table.cr_eol.pandas.py`
# and paste what it prints over the @pandas table there; the test never runs it.
#
# The inputs are pandas 3.0.4's own: tests/io/parser/test_textreader.py,
# TestTextReader.test_cr_delimited (its six texts, delim_whitespace=True being
# sep=r"\s+"), and tests/io/parser/test_c_parser_only.py,
# test_tokenize_CR_with_quoting (header=None and the default header). Each is
# read with dtype=str and keep_default_na=False so that nothing is converted and
# an empty cell stays "", and is read twice, once as written and once with every
# CR made a CRLF, which is the comparison pandas' tests make.
import io
import pandas as pd

cases = [
    ("a,b,c\r1,2,3\r4,5,6\r7,8,9\r10,11,12", {}),
    ("a  b  c\r1  2  3\r4  5  6\r7  8  9\r10  11  12", {"sep": r"\s+"}),
    ("a,b,c\r1,2,3\r4,5,6\r,88,9\r10,11,12", {}),
    ("A,B,C,D,E,F,G,H,I,J,K,L,M,N,O\r"
     "AAAAA,BBBBB,0,0,0,0,0,0,0,0,0,0,0,0,0\r"
     ",BBBBB,0,0,0,0,0,0,0,0,0,0,0,0,0", {}),
    ("A  B  C\r  2  3\r4  5  6", {"sep": r"\s+"}),
    ("A B C\r2 3\r4 5 6", {"sep": r"\s+"}),
    (' a,b,c\r"a,b","e,d","f,f"', {"header": None}),
    (' a,b,c\r"a,b","e,d","f,f"', {}),
]

print("pandas", pd.__version__)
for text, kw in cases:
    got = []
    for t in (text, text.replace("\r", "\r\n")):
        df = pd.read_csv(io.StringIO(t), dtype=str, keep_default_na=False, **kw)
        got.append((list(df.columns), df.values.tolist()))
    same = got[0] == got[1]
    print(repr(text), kw, "CR == CRLF:", same)
    print("   ", got[0])
