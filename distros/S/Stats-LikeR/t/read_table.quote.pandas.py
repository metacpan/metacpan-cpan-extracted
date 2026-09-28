# Regenerates the pandas 3.0.4 values quoted in t/read_table.quote.R.pandas.t.
#
#   python3 t/read_table.quote.pandas.py
#
# The inputs are pandas' own (named in that test's header), read with dtype=str
# and no skiprows so that every row is compared; the test never runs this.
import io
import pandas as pd

CASES = [
	("test_skip_row_with_newline_and_quote 1",
	 "id,text,num_lines\n1,\"line \n'11' line 12\",2\n2,\"line \n'21' line 22\",2\n3,\"line \n'31' line 32\",1"),
	("test_skip_row_with_newline_and_quote 2",
	 "id,text,num_lines\n1,\"line '11\n' line 12\",2\n2,\"line '21\n' line 22\",2\n3,\"line '31\n' line 32\",1"),
	("test_skip_row_with_newline_and_quote 3",
	 "id,text,num_lines\n1,\"line '11\n' \r\tline 12\",2\n2,\"line '21\n' \r\tline 22\",2\n3,\"line '31\n' \r\tline 32\",1"),
	("test_unbalanced_quoting unbalanced", 'a,b,c\n1,2,"3'),
	("test_skiprows_infield_quote", 'a"\nb"\na\n1'),
	("write.csv", '"a","b"\n1,"x"\n2,"y"\n'),
	("mid-field", "name,height,wt\nann,5'10\",150\nbob,6'1\",180\n"),
]
for tag, data in CASES:
	try:
		print(tag, repr(pd.read_csv(io.StringIO(data), dtype=str).to_dict("records")))
	except Exception as e:
		print(tag, "ERROR:", e)
