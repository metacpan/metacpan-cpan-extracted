use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
BEGIN { use_ok('Table::Readable') };
use Table::Readable qw/read_table/;

# Non-existent file

my $bad_file_name = "/holy/non/existent/files/batman";

die if -f $bad_file_name;

eval {
    my @f = read_table ($bad_file_name);
};

like ($@, qr/Error opening '\Q$bad_file_name\E'/i,
      "Non-existent file error test");

# Bad call with scalar return

eval {
    my $f = read_table ("$Bin/test-table-1.txt");
};

like ($@, qr/returns an array/, "Bad call with scalar return");

eval {
    read_table ("$Bin/test-table-1.txt");
};

like ($@, qr/returns an array/, "Bad call with void context");


my @g = read_table ("$Bin/test-table-1.txt");

ok (@g == 2, "test table row count is OK");
ok ($g[0]->{x} eq "y", "test table data is OK #1");
ok ($g[1]->{a} eq "c", "test table data is OK #2");

my @gg = read_table ("$Bin/test-table-whitespace.txt");

ok (@gg == 2, "Delete empty entry at end");

my @h = read_table ("$Bin/test-table-comments.txt");

ok (@h == 2, "Skip comments");

my @i = read_table ("$Bin/test-multiline.txt");

ok (@i == 1, "Read multiline table");
like ($i[0]->{c}, qr/fruit loops/, "Correctly read multiline table");
unlike ($i[0]->{c}, qr/%%/, "Did not read head of multiline entry");

eval {
my @j = read_table ("$Bin/test-duplicates.txt");
};
like ($@, qr/duplicate for key/i, "Test duplicate detection");

# Check that whitespace immediately before the colon is converted to
# an underscore.

my $t = <<EOF;
this key : value
EOF
my @t = read_table ($t, scalar => 1);
is ($t[0]{'this_key_'}, 'value', "Correct reading of value");

my $u = <<EOF;
novalue:
EOF
my @u = read_table ($u, scalar => 1);
ok (defined $u[0]{novalue}, "Defined for no value");
is ($u[0]{novalue}, '', "Empty key for no value");

my $v = <<EOF;
%%v:
# monkey
%%
EOF
my @v = read_table ($v, scalar => 1);
is ($v[0]{v}, "# monkey", "Hashes in multiline are not comments");

my $w = <<EOF;
w: walrus # eggman
EOF
my @w = read_table ($w, scalar => 1);
is ($w[0]{w}, "walrus # eggman", "Hashes not at the start of the line are not comments");

{
    my $warning;
    local $SIG{__WARN__} = sub {
	$warning = "@_";
    };
    my $badline = <<EOF;
not a valid line
EOF
    my @w = read_table ($badline, scalar => 1);
    like ($warning, qr/^1: unmatched line/, "Correct warning for bad line");
};


done_testing ();
