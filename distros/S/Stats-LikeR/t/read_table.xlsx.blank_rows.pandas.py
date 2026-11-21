#!/usr/bin/env python3
# Checks that pandas reads the workbooks of t/read_table.xlsx.blank_rows.pandas.t
# as the pandas tests they are rebuilt from expect; the test never runs this.
#
# Run from the worktree root, after `make`, with pandas and openpyxl installed:
#
#   python3 -I t/read_table.xlsx.blank_rows.pandas.py
#
# It runs `perl -Iblib/lib -Iblib/arch t/read_table.xlsx.blank_rows.pandas.t
# --write-fixtures DIR` (the perl on PATH, or $PERL), reads each DIR/<i>.xlsx
# with pandas.read_excel(), and prints the case's label, the column names and
# the rows, NaN as None.  Compare them with the case's last field in the test
# (its rows) and with the pandas test named in its label.  On 2026-11-20, with
# pandas 3.0.4 and openpyxl 3.1.5, every case agreed but 'leading blank
# rows', where pandas makes the blank row 1 the header; the test says why.
import math
import os
import subprocess
import sys
import tempfile

import pandas

if not os.path.exists('blib'):
	sys.exit('run from the worktree root after make')
d = tempfile.mkdtemp()
subprocess.run([os.environ.get('PERL', 'perl'), '-Iblib/lib', '-Iblib/arch',
	't/read_table.xlsx.blank_rows.pandas.t', '--write-fixtures', d], check=True)
i = 0
while os.path.exists(os.path.join(d, '%d.xlsx' % i)):
	with open(os.path.join(d, '%d.label' % i), encoding='utf-8') as fh:
		label = fh.read()
	df = pandas.read_excel(os.path.join(d, '%d.xlsx' % i))
	rows = [[None if isinstance(v, float) and math.isnan(v) else v for v in r] for r in df.values.tolist()]
	print('%s: %s %s' % (label, list(df.columns), rows))
	i += 1
