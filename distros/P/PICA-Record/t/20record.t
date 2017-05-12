use strict;
use utf8;

use Test::More qw(no_plan);

use PICA::Field;
use PICA::Record qw(:all);
use IO::File;

my $files = "t/files";

# PICA::Record constructor
my $testrecord = PICA::Record->new(
    '009P/03', '0' => 'http',
    '010@', 'a' => 'eng',
    '037A', 'a' => '1st note',
    '037A', 'a' => '2nd note',
    '111@', 'x' => 'foo'
);
isa_ok( $testrecord, 'PICA::Record');

# create a field for appending
my $field = PICA::Field->new("028A","9" => "117060275", "d" => "Martin", "a" => "Schrettinger");
isa_ok( $field, 'PICA::Field');

# this is how the record with the field should look like
my $normalized = "\x1D\x0A\x1E028A \x1F9117060275\x1FdMartin\x1FaSchrettinger\x0A";

# create a new record (empty)
my $record = new PICA::Record();
isa_ok( $record, 'PICA::Record');
ok( $record->empty, 'empty record' );
ok( !$record, 'empty record (overload)' );
is( $record->size, 0, "size 0");

# append a field
$record->append($field);
is( $record->normalized(), $normalized, 'Record->normalized()');
ok( !$record->empty, 'not empty record' );
ok( $record, 'not empty record (overload)' );
is( $record->size, 1, "size 1");

# do not append empty fields
is( $record->append( PICA::Field->new('123A') ), 0, "ignore empty fields");
is( $record->normalized(), $normalized, "ignore empty fields");

# directly pass a field to new()
$record = PICA::Record->new($field);
is( $record->normalized(), $normalized, 'Record->normalized()');

# directly pass data to new() for parsing
$record = PICA::Record->new( $normalized );
is( $record->normalized(), $normalized, 'Record->normalized()');

# directly pass data to new()
$record = PICA::Record->new("028A","9" => "117060275", "d" => "Martin", "a" => "Schrettinger");
is( $record->normalized(), $normalized, 'Record->normalized()');

# use append to add fields
$record = PICA::Record->new();
$record->append("028A","9" => "117060275", "d" => "Martin", "a" => "Schrettinger");
is( $record->normalized(), $normalized, 'Record->normalized()');

$record = PICA::Record->new();
$record->append($field, '037A','a' => 'First note');
is( scalar $record->fields(), 2 , "Record->append()" );

$record = PICA::Record->new();
$record->append(
        $field,
        '037A','a' => 'First note',
        PICA::Field->new('037A','a' => 'Second note'),
        '037A','a' => 'Third note',
);
is( scalar $record->fields(), 4 , "Record->append()" );
is( $record->size, 4, "size 4");

is( $record->ppn(), undef, "ppn() not existing" );
is( $record->epn(), undef, "epn() not existing" );

my @missing = $record->epn();
is_deeply( \@missing, [], "epn() not existing" );

# use the same object of provided
is( $record->subfield('028A','9'), '117060275', "Field value" );
$field->update('9'=>'12345');
is( $record->subfield('028A','9'), '12345', "Field value modified" );

# appendif
$record = PICA::Record->new();
$record->appendif('037A','a' => undef);
is( scalar $record->fields(), 0 , "Record->appendif()" );
$record->appendif('037A','a' => 123);
is( scalar $record->fields(), 1 , "Record->appendif()" );
$record->appendif('028A','9' => undef, 'd'=>'Max');
is( scalar $record->fields(), 2 , "Record->appendif()" );
is( $record->string, "037A \$a123\n028A \$dMax\n" , "Record->appendif()" );

$record = PICA::Record->new();
$record->append(
    '037A', 'a' => '1st note',
    '037A', 'a' => '2nd note',
);
is( scalar $record->fields(), 2 , "Record->append()" );

# values
is_deeply( [ $record->values('037A$a') ], [ '1st note', '2nd note' ], 'values' );
is_deeply( [ $record->values('037A_a') ], [ '1st note', '2nd note' ], 'values' );

# clone constructor
my $recordclone = PICA::Record->new($record);
is( scalar $recordclone->fields(), 2 , "PICA::Record clone constructor" );
$record->remove('037A');
is( scalar $recordclone->fields(), 2 , "PICA::Record cloned a new object" );

# remove fields via update
$record->update( '037A', undef );
is( $record->size, 0, 'removed both' );

# occurrence
$record = PICA::Record->new( '233A/03', 'x' => 'foo' );
is( $record->occ, '03', 'occurrence' );

### field()
$record = $testrecord;
my @fields = $record->field("009P/03","a"=>"http://example.com");
is( scalar @fields, 1 , "Record->field()" );
@fields = $record->f("037A");
is( scalar @fields, 2 , "Record->field()" );
@fields = $record->field("009P/03");
is( scalar @fields, 1 , "Record->field()" );
@fields = $record->field("0...(/..)?");
is( scalar @fields, 4 , "Record->field()" );
@fields = $record->field( qr/^0...(\/..)?$/ );
is( scalar @fields, 4 , "Record->field(qr)" );
@fields = $record->fields();
is( scalar @fields, 5 , "Record->field()" );
@fields = $record->field(2, "0...(/..)?");
is( scalar @fields, 2, "Record->field() with limit" );
@fields = $record->field(0, "0...(/..)?");
is( scalar @fields, 4 , "Record->field() with limit zero" );
@fields = $record->f(1, "037A");
is( scalar @fields, 1 , "Record->field() with limit one" );
@fields = $record->f(99, "037A");
is( scalar @fields, 2 , "Record->field() with limit high" );

@fields = $record->f( "037A", sub { return $_[0] if $_[0]->sf('a'); } );
is( scalar @fields, 2 , "Record->field() with filter" );

@fields = $record->f( ".*", sub { return unless $_->sf('a'); $_; } );
is( scalar @fields, 3 , "Record->field() with filter" );

my $r2 = PICA::Record->new($record);
@fields = $r2->f( "0.*", sub { return unless $_->sf('a'); $_->update('a'=>'xx'); $_; } );
is_deeply( [ map { $_->sf('a'); } @fields ], ['xx','xx','xx'], "Record->field() with filter" );

@fields = $r2->f( sub { return unless $_->sf('a'); $_->update('a'=>'xx'); $_; } );
is_deeply( [ map { $_->sf('a'); } @fields ], ['xx','xx','xx'], "Record->field() with filter" );

### subfield()
is( $record->subfield('009P/03$0'), "http", "subfield() \$");
is( $record->subfield('009P/03_0'), "http", "subfield() _");
my @s = $record->subfield(0,'....$a');
is( scalar @s, 3, "subfield() with limit zero");
@s = $record->subfield(2,'...._a');
is( scalar @s, 2, "subfield() with limit");
is( $record->subfield('123$x'), undef, "subfield() not exist" );

### values
# my @titles = $pica->values( '021A$a', '025@$a', '026C$a');
my @v = $record->values( '0[01]..(/..)?', '0a' );
is_deeply( \@v, [ 'http', 'eng' ], 'values (1)' );
@v = $record->values( 2, '010@_a', '111@', 'x', '037A_a' );
is_deeply( \@v, [ 'eng', 'foo' ], 'values (2)' );
@v = $record->values( 3, '010@_a', '111@', 'x', '037A_a' );
is_deeply( \@v, [ 'eng', 'foo', '1st note' ], 'values (3)' );
@v = $record->values( '010@', 'a', '111@', 'x' );
is_deeply( \@v, [ 'eng', 'foo' ], 'values (4)' );
@v = $record->values( '010@', 'a', '111@$x' );
is_deeply( \@v, [ 'eng', 'foo' ], 'values (5)' );

### remove
my $r = PICA::Record->new($record);
$r->remove("037A");
is( scalar $r->fields(), 3 , "delete()" );

$r = PICA::Record->new($record);
$r->remove("0...");
is( scalar $r->fields(), 2 , "delete()" );

$r = PICA::Record->new($record);
$r->remove(qr/0..@/,"111@");
is( scalar $r->fields(), 3 , "delete()" );

### replace fields
$record = $testrecord;
$record->update('010@', PICA::Field->new('010@', 'a' => 'ger'));
is( $record->subfield('010@$a'), 'ger', "update field");

$record->update('010@', 'a' => 'fra');
is( $record->subfield('010@$a'), 'fra', "update field");

$record->update('037A', sub { 
    return unless $_[0]->sf('a') =~ /^2nd/;
    PICA::Field->new('037A','a' => 'xxx');
} );

is_deeply( [ $record->sf('037A$a') ], [ '1st note', 'xxx' ], 'update by code' );

$record->update('037A');
ok( $record->field('037A'), "ignore update without value" );

# $record->update( '037A', undef );
# $record->update( '009P/03', undef );
# print $record . "\n";
# remove fields via update
# ok( $record->empty, 'removed both' );

### parse normalized by autodetection
open PICA, "$files/bib.pica"; # TODO: bib.pica is bytestream, not character-stream!
$normalized = join( "", <PICA> );
close PICA;

$r = PICA::Record->new( $normalized );
is( $r->fields(), 24, "detect and read normalized pica" );

my $file = IO::File->new("$files/minimal.pica");
$record = PICA::Record->new( $file );
$file->seek(0,0);
my $minimal = join('',$file->getlines());
is( $record->string, $minimal, "string()" );
#is( $record, $minimal, "stringify" );

# parse non-existing file
$record = eval { PICA::Record->new( IO::File->new('xxx') ); };
ok( $@ && !$record, 'failed to read from not-existing file' );

# newlines in field values
$record = PICA::Record->new( '021A', 'a' => "This\nare\n\t\nlines" );
is( $record->sf('021A$a'), "This are lines", "newline in value (1, \$)" );
is( $record->sf('021A_a'), "This are lines", "newline in value (1, _)" );
is( $record->string, "021A \$aThis are lines\n", "newline in value (2)" );

# also test readpicarecord
$record = readpicarecord("$files/graveyard.pica");
is( scalar $record->fields, 62, "parsed graveyard.pica" );

# writepicarecord
use File::Temp qw(tempfile);
my ($fh, $tempfile) = tempfile(UNLINK => 1);
my $written = $record->write( $tempfile );
is( $written->counter, 1, 'write' );

my $rec2 = readpicarecord( $tempfile );
is_deeply( $rec2, $record, 'read back written record' );

$written = $record->writepicarecord( $tempfile );
is( $written->counter, 1, '::write' );

$written = writepicarecord( $record, $tempfile );
is( $written->counter, 1, 'writerecord as function' );


### PPN

my $ppn = $record->ppn();
is( $ppn, '588923168', "ppn (plain)" );

$ppn = $record->subfield('003@_0');
is( $ppn, '588923168', "ppn as subfield" );

$ppn = '123456789';
is( $record->ppn($ppn), $ppn, 'set ppn' );

$record->append('003@','0'=>'588923168');
my @ppn = $record->subfield('003@_0');
is_deeply( \@ppn, [ '588923168' ], 'only one PPN' );

$record->update('003@','0'=>'123456789');
is( $record->ppn, '123456789', 'update PPN' );


### EPN
my $epn = $record->epn();
my @epns = $record->epn();

is( $epn, 917400194, "epn() as scalar" );
is_deeply( \@epns, [917400194,923091475,923091483,923091491], "epn() as array" );


### holdings and items

$record = PICA::Record->new("003\@ \$0123\n021A \$aHello");
my @holdings = $record->holdings;
is scalar @holdings, 0;

$record = PICA::Record->new( IO::File->new("$files/bgb.example") );

@holdings = $record->holdings();
is scalar @holdings, 56, 'holdings';

my $iln = $holdings[0]->iln;
is $record->holdings($iln)->string, $holdings[0]->string, "ILN: $iln";

my @copies = $record->items();
is( scalar @copies, 353, 'items' );

is( scalar $holdings[0]->items(), 1, "items (1)");
is( scalar $holdings[4]->items(), 2, "items (2)");
is( scalar $record->holdings('21')->items, 26, "items (26)");


$record = readpicarecord( "$files/holdings.pica" );
@holdings = $record->holdings();
is( scalar @holdings, 3, 'holdings' );
@copies = $record->items();
is( scalar @copies, 3, 'items' );

### UTF8 and encodings
my $cjk = "我国民事立法的回顾与展望";
open CJK,"$files/cjk.pica";
my @f = (\*CJK, new IO::File("$files/cjk.pica"));
foreach my $fh (@f) {
    $record = new PICA::Record( $fh );
    is( $record->sf('021A_a'), $cjk, 'CJK record' );
}
close CJK;

### pgrep and pmap

@fields = ('037A', 'a' => '1st note', '037A', 'a' => '2nd note', '012A', 'x' => 'WTF' );
$record = PICA::Record->new( @fields );

$r2 = pgrep { $_ =~ /^2/ if ($_ = $_->sf('a')); } $record;
is_deeply( $r2, PICA::Record->new('037A', 'a' => '2nd note'), 'pgrep');

$r2 = pgrep { $_->tag eq '012A'; } @fields;
is_deeply( $r2, PICA::Record->new('012A', 'x' => 'WTF'), 'pgrep' );

$record = PICA::Record->new( @fields );
$r2 = pmap { PICA::Field->new( $_->tag, 'x' => $_->sf('ax') ) } $record;

$fields[1] = $fields[4] = 'x';
is_deeply( $r2, PICA::Record->new(@fields) , 'pmap' );

__END__

### TODO: parse WinIBW output : this is possible via winibw2pica (test needed)
if (1) {
  use PICA::Parser;
  PICA::Parser->parsefile( "$files/winibwsave.example", Record => sub { $record = shift; } );
  isa_ok( $record, 'PICA::Record' );
  # test bibliographic()
  my $main = $record->main();
  isa_ok( $main, 'PICA::Record' );
}
# TODO: test to_xml


