# Regenerates the pandas 3.0.4 values quoted in t/read_table.blank_lines.R.pandas.t.
#
#   python3 t/read_table.blank_lines.pandas.py
#
# The first three inputs are pandas' own (named in that test's header); the
# rest are lines made of nothing but separators, which pandas' suite does not
# carry. Each is read with dtype=str so that no cell is converted and an empty
# cell prints as nan; the test never runs this.
import io
import pandas as pd

CASES = [
	("test_empty_lines ,", ",", "A,B,C\n1,2.,4.\n\n\n5.,NaN,10.0\n\n-70,.4,1\n"),
	("test_empty_lines \\s+", r"\s+", "A  B  C\n1  2.  4.\n\n\n5.  NaN  10.0\n\n-70  .4  1\n"),
	("test_whitespace_lines", ",", "\n\n\t  \t\t\n\t\nA,B,C\n\t    1,2.,4.\n5.,NaN,10.0\n"),
	("tab row", "\t", "a\tb\n1\t2\n\t\n3\t4\n"),
	("tab row x3", "\t", "a\tb\tc\n1\t2\t3\n\t\t\n4\t5\t6\n"),
	("tab row crlf", "\t", "a\tb\r\n1\t2\r\n\t\r\n3\t4\r\n"),
	("tab row last", "\t", "a\tb\n1\t2\n\t"),
	("comma row", ",", "a,b\n1,2\n,\n3,4\n"),
	("space row", " ", "a b\n1 2\n \n3 4\n"),
	("spaces under tab", "\t", "a\tb\n1\t2\n  \n3\t4\n"),
	("one column", "\t", "a\n1\n\n2\n"),
]
for tag, sep, data in CASES:
	try:
		print(tag, repr(pd.read_csv(io.StringIO(data), sep=sep, dtype=str).to_dict("records")))
	except Exception as e:
		print(tag, "ERROR:", e)
