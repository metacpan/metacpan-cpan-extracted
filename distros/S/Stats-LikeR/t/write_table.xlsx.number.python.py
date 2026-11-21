#!/usr/bin/env python3
# Generator for the frozen values in t/write_table.xlsx.number.python.t.
#
# Run (from the worktree root, after `make`), with openpyxl 3.1.5 installed:
#
#   perl -Iblib/lib -Iblib/arch -MStats::LikeR=write_table -e \
#     'write_table([["v"], map { [$_] } @ARGV[1..$#ARGV]], $ARGV[0], quiet => 1)' \
#     /tmp/n.xlsx 6.10 1.0 ... (the texts of the test's @case, in order)
#   python3 -I t/write_table.xlsx.number.python.py /tmp/n.xlsx
#
# It prints repr(value) and openpyxl's data_type ('s' text, 'n' number) of each
# cell under the header, which the test freezes as a string or as the number.
# The LibreOffice column was made with
#   soffice --headless --convert-to csv --outdir /tmp/lo /tmp/n.xlsx
# (LibreOffice 24.2.7.2), whose csv is each cell as shown.
import sys
import openpyxl

ws = openpyxl.load_workbook(sys.argv[1]).active
for (c,) in ws.iter_rows(min_row=2, max_col=1):
    print(repr(c.value), c.data_type)
