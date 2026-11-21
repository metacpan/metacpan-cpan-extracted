#!/usr/bin/env python3
# Generator for the frozen values in t/write_table.oracle.R.python.t.
#
# Run from the worktree root, after `make`, with openpyxl, pandas, R (Rscript)
# and LibreOffice (soffice) installed:
#
#   python3 -I t/write_table.oracle.R.python.py > /tmp/oracle.pl
#
# then replace the block between "# BEGIN GENERATED" and "# END GENERATED" in
# the .t with /tmp/oracle.pl, and review every key of %read the diff adds: each
# needs an entry in the test's %why before the test passes.  The test never
# runs this script, and needs none of these readers.
#
# What it does:
#   1. runs `perl -Iblib/lib -Iblib/arch t/write_table.oracle.R.python.t
#      (the perl on PATH, or $PERL; it must be the one blib was built with)
#      --write-corpus DIR`, which writes every case of the test's @case with
#      this tree's write_table() as DIR/<i>.csv, <i>.tsv and <i>.xlsx (columns
#      v and w, one row: the case in v, 'z' in w), and DIR/manifest.tsv
#      (index, label, kind s or n, the value's UTF-8 in hex);
#   2. records what write_table wrote: each .csv and .tsv whole, and the
#      <c r="A2"> element of each workbook's sheet1.xml (%golden);
#   3. reads every file back with
#        csv.reader (Python's stdlib), on the .csv and .tsv;
#        pandas.read_csv(dtype=str, keep_default_na=False), on both;
#        R's read.csv / read.delim(colClasses = "character",
#          na.strings = character(0), encoding = "UTF-8"), on both;
#        openpyxl.load_workbook(), on the .xlsx (value and data_type);
#        LibreOffice's csv export of the .xlsx, quoting every text cell so
#          that a string cell can be told from a number cell;
#      decoding UTF-8 with errors='replace' wherever a reader lets one choose,
#      so bytes that are not UTF-8 show as U+FFFD rather than stop the run;
#   4. prints %golden, and %read: every reading that is not the case's value
#      (for a number, perl's string of it; for a string cell of a workbook,
#      also its type), keyed "<format>/<reader>/<label>".  A reading that
#      shows the row's shape broken (not one row, or w not 'z') is recorded
#      as SHAPE: and the rows the reader saw.
import csv
import io
import os
import re
import subprocess
import sys
import tempfile
import zipfile

import openpyxl
import pandas

R_PROG = r'''
args <- commandArgs(TRUE)
dir <- args[1]
hex <- function(s) paste(as.character(charToRaw(s)), collapse = "")
for (f in list.files(dir, pattern = "\\.(csv|tsv)$")) {
	p <- file.path(dir, f)
	d <- tryCatch(
		withCallingHandlers(
			if (grepl("csv$", f))
				read.csv(p, colClasses = "character", na.strings = character(0),
					encoding = "UTF-8", check.names = FALSE)
			else
				read.delim(p, colClasses = "character", na.strings = character(0),
					encoding = "UTF-8", check.names = FALSE, quote = "\""),
			warning = function(w) invokeRestart("muffleWarning")),
		error = function(e) conditionMessage(e))
	if (is.character(d)) {
		cat(f, "ERR", hex(d), "\n", sep = "\t")
		next
	}
	cells <- unlist(lapply(seq_len(nrow(d)), function(i)
		vapply(seq_along(d), function(j) hex(d[[j]][i]), "")))
	cat(f, nrow(d), ncol(d), paste(cells, collapse = ","), "\n", sep = "\t")
}
'''


def perl_bytes(b):
	"""A perl double-quoted literal of a byte string."""
	out = []
	for c in b:
		ch = chr(c)
		if ch in '\\"$@':
			out.append('\\' + ch)
		elif 0x20 <= c < 0x7f:
			out.append(ch)
		else:
			out.append('\\x%02X' % c)
	return '"' + ''.join(out) + '"'


def perl_text(s):
	"""A perl double-quoted literal of a character string."""
	out = []
	for ch in s:
		c = ord(ch)
		if ch in '\\"$@':
			out.append('\\' + ch)
		elif 0x20 <= c < 0x7f:
			out.append(ch)
		else:
			out.append('\\x{%X}' % c)
	return '"' + ''.join(out) + '"'


def perl_reading(r):
	if r is None:
		return 'undef'
	if isinstance(r, tuple):
		kind, v = r
		if kind == 'n':
			return "['n', %s]" % repr(v)
		return "['%s', %s]" % (kind, 'undef' if v is None else perl_text(v))
	return perl_text(r)


def shape(rows):
	return 'SHAPE:' + repr(rows)


def main():
	if not os.path.exists('blib'):
		sys.exit('run from the worktree root after make')
	d = tempfile.mkdtemp()
	subprocess.run([os.environ.get('PERL', 'perl'), '-Iblib/lib', '-Iblib/arch',
		't/write_table.oracle.R.python.t', '--write-corpus', d], check=True)
	cases = []
	with open(os.path.join(d, 'manifest.tsv'), encoding='ascii') as fh:
		for line in fh:
			i, label, kind, hx = line.rstrip('\n').split('\t')
			cases.append((int(i), label, kind, bytes.fromhex(hx).decode('utf-8', 'surrogatepass')))

	golden = {}
	read = {}

	def note(fmt, reader, label, got, want):
		if got != want:
			read['%s/%s/%s' % (fmt, reader, label)] = got

	# the R readings, one Rscript for every file
	r_out = subprocess.run(['Rscript', '-e', R_PROG, d], check=True,
		capture_output=True, text=True).stdout
	r_read = {}
	for line in r_out.splitlines():
		f, *rest = line.split('\t')
		if rest[0] == 'ERR':
			r_read[f] = 'ERROR:' + bytes.fromhex(rest[1]).decode('utf-8', 'replace')
			continue
		nrow, ncol, cells = int(rest[0]), int(rest[1]), rest[2]
		vals = [bytes.fromhex(h).decode('utf-8', 'replace') for h in cells.split(',')] if cells else []
		rows = [vals[k:k + ncol] for k in range(0, len(vals), ncol)]
		r_read[f] = rows[0][0] if nrow == 1 and ncol == 2 and rows[0][1] == 'z' else shape(rows)

	# LibreOffice, one soffice for every workbook
	lo = os.path.join(d, 'lo')
	subprocess.run(['soffice', '--headless', '--convert-to',
		'csv:Text - txt - csv (StarCalc):44,34,76,1,,0,true,false,true',
		'--outdir', lo] + [os.path.join(d, '%d.xlsx' % c[0]) for c in cases],
		check=True, capture_output=True)

	for i, label, kind, value in cases:
		want = value
		gold = {}
		for fmt, sep in (('csv', ','), ('tsv', '\t')):
			p = os.path.join(d, '%d.%s' % (i, fmt))
			with open(p, 'rb') as fh:
				gold[fmt] = fh.read()
			with open(p, encoding='utf-8', errors='replace', newline='') as fh:
				rows = list(csv.reader(fh, delimiter=sep))
			got = rows[1][0] if len(rows) == 2 and len(rows[1]) == 2 and rows[1][1] == 'z' else shape(rows[1:])
			note(fmt, 'csv', label, got, want)
			try:
				df = pandas.read_csv(p, sep=sep, dtype=str, keep_default_na=False,
					encoding='utf-8', encoding_errors='replace')
				rows = df.values.tolist()
				got = rows[0][0] if len(rows) == 1 and len(rows[0]) == 2 and rows[0][1] == 'z' else shape(rows)
			except Exception as e:
				got = 'ERROR:%s: %s' % (type(e).__name__, e)
			note(fmt, 'pandas', label, got, want)
			note(fmt, 'R', label, r_read['%d.%s' % (i, fmt)], want)

		p = os.path.join(d, '%d.xlsx' % i)
		with zipfile.ZipFile(p) as z:
			xml = z.read('xl/worksheets/sheet1.xml')
		m = re.search(rb'<c r="A2".*?</c>', xml, re.S)
		gold['xlsx'] = m.group(0) if m else None
		want_x = ('n', float(value)) if kind == 'n' else ('s', None if value == '' else value)
		try:
			ws = openpyxl.load_workbook(p).active
			c, w = ws.cell(2, 1), ws.cell(2, 2).value
			# openpyxl gives a cell that is not in the sheet data_type 'n' and
			# value None; it is mapped to ('s', None) below
			got = (c.data_type, float(c.value) if c.data_type == 'n' and c.value is not None else c.value)
			if w != 'z' or ws.max_row != 2:
				got = ('s', shape([[x.value for x in r] for r in ws.iter_rows(min_row=2)]))
		except Exception as e:
			got = ('s', 'ERROR:%s: %s' % (type(e).__name__, e))
		if got == ('n', None):
			got = ('s', None)
		note('xlsx', 'openpyxl', label, got, want_x)

		with open(os.path.join(lo, '%d.csv' % i), 'rb') as fh:
			raw = fh.read().decode('utf-8', 'replace')
		nl = raw.index('\n')	# the header row, "v","w", holds no line break
		body = raw[nl + 1:]
		rows = list(csv.reader(io.StringIO(body, newline='')))
		if len(rows) == 1 and len(rows[0]) == 2 and rows[0][1] == 'z':
			v = rows[0][0]
			got = ('s', v) if body.startswith('"') else (('s', None) if v == '' else ('n', float(v)))
		else:
			got = ('s', shape(rows))
		note('xlsx', 'LibreOffice', label, got, want_x)
		golden[label] = gold

	print('# BEGIN GENERATED by t/write_table.oracle.R.python.py')
	print('my %golden = (')
	for i, label, kind, value in cases:
		g = golden[label]
		print('\t%s => {' % perl_text(label))
		for fmt in ('csv', 'tsv', 'xlsx'):
			print('\t\t%s => %s,' % (fmt, 'undef' if g[fmt] is None else perl_bytes(g[fmt])))
		print('\t},')
	print(');')
	print('my %read = (')
	for k in sorted(read):
		print('\t%s => %s,' % (perl_text(k), perl_reading(read[k])))
	print(');')
	print('# END GENERATED')


main()
