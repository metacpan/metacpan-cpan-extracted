require 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp 'tempfile';
use Stats::LikeR;

# read_table's .xlsx support is pure Perl on top of core IO::Uncompress::Unzip.
# To keep this test self-contained (no openpyxl, no committed binary fixture) we
# build a tiny-but-valid .xlsx here with core IO::Compress::Zip and read it back.
# The workbook exercises the parser's interesting paths:
#   * shared strings, including a rich-text (<r><t>..</t></r> x2) entry
#   * inline strings (t="inlineStr")
#   * numeric cells
#   * XML entity decoding (& < > ")
#   * a trailing empty cell  (row 3, no D cell)  -> undef in the last column
#   * a sparse middle cell    (row 4, no C cell)  -> undef in a middle column
#   * a second worksheet, for sheet-by-name / sheet-by-index selection

my $have_zip = eval { require IO::Compress::Zip; 1 };
plan skip_all => 'IO::Compress::Zip (core) not available' unless $have_zip;

# --- build the workbook ----------------------------------------------------
# $nsheets (default 2) controls whether the second worksheet is emitted, so the
# same builder produces both the multi-sheet and single-sheet fixtures.
sub build_xlsx {
	my ($nsheets) = @_;
	$nsheets = 2 unless defined $nsheets;
	my ($fh, $path) = tempfile( SUFFIX => '.xlsx', UNLINK => 1 );
	close $fh;

	# shared strings (workbook-global, index-based). Index 5 is rich text and
	# carries entities; index 8 carries an escaped double quote.
	my @si = (
		'<si><t>name</t></si>',
		'<si><t>mpg</t></si>',
		'<si><t>cyl</t></si>',
		'<si><t>note</t></si>',
		'<si><t>Mazda RX4</t></si>',
		'<si><r><t>A &amp; B </t></r><r><t>&lt;ok&gt;</t></r></si>',  # 5
		'<si><t>Datsun 710</t></si>',
		'<si><t>Hornet</t></si>',
		'<si><t>q&quot;x</t></si>',                                   # 8
		'<si><t>x</t></si>',
		'<si><t>y</t></si>',
	);
	my $shared =
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	  . '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
	  . 'count="18" uniqueCount="' . scalar(@si) . '">'
	  . join('', @si) . '</sst>';

	# helpers for cell XML
	my $s = sub { my ($ref, $i) = @_; qq{<c r="$ref" t="s"><v>$i</v></c>} };
	my $n = sub { my ($ref, $v) = @_; qq{<c r="$ref"><v>$v</v></c>} };
	my $inl = sub {                        # inline string
		my ($ref, $txt) = @_;
		qq{<c r="$ref" t="inlineStr"><is><t>$txt</t></is></c>};
	};

	my $sheet1 =
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	  . '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
	  . '<sheetData>'
	  . '<row r="1">' . $s->('A1',0) . $s->('B1',1) . $s->('C1',2) . $s->('D1',3) . '</row>'
	  . '<row r="2">' . $s->('A2',4) . $n->('B2','21') . $n->('C2','6') . $s->('D2',5) . '</row>'
	  . '<row r="3">' . $s->('A3',6) . $n->('B3','22.8') . $n->('C3','4') . '</row>'   # no D: trailing empty
	  . '<row r="4">' . $s->('A4',7) . $n->('B4','21.4') . $s->('D4',8) . '</row>'     # no C: sparse middle
	  . '<row r="5">' . $inl->('A5','Valiant') . $n->('B5','18.1') . $n->('C5','6') . $inl->('D5','tab&amp;end') . '</row>'
	  . '</sheetData></worksheet>';

	my $sheet2 =
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	  . '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
	  . '<sheetData>'
	  . '<row r="1">' . $s->('A1',9) . $s->('B1',10) . '</row>'
	  . '<row r="2">' . $n->('A2','1') . $n->('B2','2') . '</row>'
	  . '</sheetData></worksheet>';

	my $second_sheet_decl = $nsheets > 1
		? '<sheet name="Second" sheetId="2" r:id="rId2"/>' : '';
	my $second_sheet_rel = $nsheets > 1
		? '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>'
		: '';

	my $workbook =
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	  . '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
	  . 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
	  . '<sheets>'
	  . '<sheet name="Data" sheetId="1" r:id="rId1"/>'
	  . $second_sheet_decl
	  . '</sheets></workbook>';

	my $wbrels =
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	  . '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
	  . '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
	  . $second_sheet_rel
	  . '</Relationships>';

	my $ctypes =
		'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	  . '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
	  . '<Default Extension="xml" ContentType="application/xml"/>'
	  . '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
	  . '</Types>';

	# write each part as its own zip member (stored path uses forward slashes)
	my %parts = (
		'[Content_Types].xml'         => $ctypes,
		'xl/workbook.xml'             => $workbook,
		'xl/_rels/workbook.xml.rels'  => $wbrels,
		'xl/sharedStrings.xml'        => $shared,
		'xl/worksheets/sheet1.xml'    => $sheet1,
	);
	$parts{'xl/worksheets/sheet2.xml'} = $sheet2 if $nsheets > 1;
	my @names = sort keys %parts;
	my $z = IO::Compress::Zip->new($path, Name => $names[0])
		or die "Cannot create $path: $IO::Compress::Zip::ZipError";
	$z->print($parts{$names[0]});
	for my $name (@names[1 .. $#names]) {
		$z->newStream(Name => $name)
			or die "newStream failed: $IO::Compress::Zip::ZipError";
		$z->print($parts{$name});
	}
	$z->close;
	return $path;
}

my $xlsx = build_xlsx();

# --- multi-worksheet workbook returns a hash keyed by sheet name -----------
{
	my $book;
	lives_ok { $book = read_table($xlsx) } 'read_table reads a multi-sheet .xlsx file';
	is( ref $book, 'HASH', 'a multi-sheet workbook returns a hashref' );
	is_deeply( [ sort keys %$book ], [qw(Data Second)],
		'hash keys are the worksheet names' );
	is( ref $book->{Data},   'ARRAY', 'each value is that sheet parsed as a table' );
	is_deeply( $book->{Second}, [ { x => '1', y => '2' } ],
		'the second worksheet is parsed independently' );
}

# --- a single named sheet is returned directly (not wrapped) ---------------
{
	my $rows;
	lives_ok { $rows = read_table($xlsx, sheet => 'Data') }
		'naming a sheet returns that one table directly';
	is( ref $rows, 'ARRAY', 'an explicit sheet is not wrapped in a hash' );
	is( scalar @$rows, 4, 'four data rows (header consumed, no blank rows)' );

	is( $rows->[0]{name}, 'Mazda RX4', 'shared-string value' );
	is( $rows->[0]{mpg},  '21',        'numeric value' );
	is( $rows->[0]{note}, 'A & B <ok>',
		'rich-text runs concatenated and XML entities decoded' );

	is( $rows->[1]{name}, 'Datsun 710', 'row 2 name' );
	is( $rows->[1]{note}, undef,        'trailing empty cell -> undef' );

	is( $rows->[2]{name}, 'Hornet', 'row 3 name' );
	is( $rows->[2]{cyl},  undef,    'sparse middle cell -> undef' );
	is( $rows->[2]{note}, 'q"x',    'escaped double quote decoded' );

	is( $rows->[3]{name}, 'Valiant',  'inline string value' );
	is( $rows->[3]{note}, 'tab&end',  'inline string entity decoded' );
	is( $rows->[3]{cyl},  '6',        'inline-string row keeps its numeric cells' );

	is_deeply( [ sort keys %{ $rows->[0] } ], [qw(cyl mpg name note)],
		'all four columns present' );
}

# --- output.type => hoh ----------------------------------------------------
{
	my $h = read_table($xlsx, sheet => 'Data', 'output.type' => 'hoh', 'row.names' => 'name');
	is( $h->{'Mazda RX4'}{mpg}, '21', 'hoh keyed by the row.names column' );
	ok( !exists $h->{'Mazda RX4'}{name}, 'row.names column is not duplicated inside the row' );
	is( $h->{'Hornet'}{cyl}, undef, 'hoh preserves undef for a sparse cell' );
}

# --- filter ----------------------------------------------------------------
{
	my $rows = read_table($xlsx, sheet => 'Data', filter => { name => sub { $_ eq 'Hornet' } });
	is( scalar @$rows, 1,        'filter keeps only matching rows' );
	is( $rows->[0]{name}, 'Hornet', 'filtered row is the expected one' );
}

# --- sheet selection -------------------------------------------------------
{
	my $by_name = read_table($xlsx, sheet => 'Second');
	is_deeply( $by_name, [ { x => '1', y => '2' } ], 'sheet by name' );

	my $by_idx = read_table($xlsx, sheet => 2);
	is_deeply( $by_idx, $by_name, 'sheet by 1-based index matches sheet by name' );

	throws_ok { read_table($xlsx, sheet => 'Nope') }
		qr/sheet 'Nope' not found/, 'unknown sheet name dies with a clear message';
	throws_ok { read_table($xlsx, sheet => 9) }
		qr/sheet index 9 is out of range/, 'out-of-range sheet index dies';
}

# --- a single-worksheet workbook returns its table directly ----------------
{
	my $solo = build_xlsx(1);
	my $rows;
	lives_ok { $rows = read_table($solo) } 'read_table reads a single-sheet .xlsx file';
	is( ref $rows, 'ARRAY',
		'a single-worksheet workbook returns the table directly, not a hash' );
	is( scalar @$rows, 4, 'all data rows are read from the lone worksheet' );
}

done_testing;
