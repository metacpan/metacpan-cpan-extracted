use FindBin '$Bin';
use lib "$Bin";
use TRTest;

my $table = [
{
    monkey => 'shines',
    antic => 'banter', 
    buffoonery => 'caper', 
    foolery => 'fooling',
    frolic => 'horseplay',
    mischief => 'nonsense', 
    prank => 'tomfoolery',
},
{
    sonnet => <<EOF,
My love is as a fever longing still,
For that which longer nurseth the disease;
Feeding on that which doth preserve the ill,
The uncertain sickly appetite to please.
My reason, the physician to my love,
Angry that his prescriptions are not kept,
Hath left me, and I desperate now approve
Desire is death, which physic did except.
Past cure I am, now Reason is past care,
And frantic-mad with evermore unrest;
My thoughts and my discourse as madmen's are,
At random from the truth vainly expressed;
   For I have sworn thee fair, and thought thee bright,
   Who art as black as hell, as dark as night.
EOF
},
];
my $wfile = "$Bin/write-test.txt";
write_table ($table, $wfile);
ok (-f $wfile, "Wrote a file");
my @back = read_table ($wfile);
is_deeply ($back[0], $table->[0], "Got back hash keys and values");
my $sonnet = $table->[1]{sonnet};
$sonnet =~ s/^\s+|\s+$//g;
is ($back[1]{sonnet}, $sonnet, "Got back extended text");
unlink ($wfile) or warn "Failed to remove $wfile: $!";

my $tbl = write_table ([{a => "b\nc"}]);
like ($tbl, qr/%%a:/, "Use long format if value contains newlines");

my $file = "$Bin/temp.$$";
write_table ([{a => 'b'}], $file);
ok (-f $file, "Got file $file");
unlink $file or die $!;

{
    my $warning;
    local $SIG{__WARN__} = sub {$warning = "@_";};
    write_table ();
    like ($warning,
	  qr!First argument to 'write_table' must be array reference!,
      "Got correct warning writing non-array reference");
    write_table ([qw!a b c!]);
    like ($warning, 
	  qr!Elements of first argument to 'write_table' must be hash references!, "Got correct warning writing non-hash references");
    write_table ([{x => \my %nonsense}]);
    like ($warning, qr!Non-scalar value in key!,
	  "Got correct warning with non-scalar reference");
}

{
    my $out;
    open my $fh, ">>", \$out or die $!;
    select $fh;
    write_table ([{a => 'b'}]);
    select STDOUT;
    ok (length ($out) > 0, "Wrote to STDOUT");
    like ($out, qr!a: b!, "Got right values in STDOUT");
    note $out;
}

done_testing ();
