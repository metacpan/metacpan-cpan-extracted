#!perl

use Test::Most;
use Mojo::Asset::File;
use Mojo::Asset::Memory;
use Mojo::File qw/path/;
use File::Temp ();

use constant CSV_FILE => 't/sample.csv';
-r CSV_FILE or die 'Failed to find ' . CSV_FILE . ' or it is not readable';

use constant CSV_TEMP => time() . '_temp.csv';
END { unlink CSV_TEMP };

{ # Init
    use_ok 'Mojo::CSV';
    can_ok 'Mojo::CSV',
        qw/new  slurp  slurp_body  row  spurt  text  trickle  in  out  flush/;
}

{   # Fluidity
    my $csv = Mojo::CSV->new;
    my $c = 'Mojo::CSV';
    isa_ok $csv,                               $c, 'isa ->new';
    isa_ok $csv->in(Mojo::Asset::Memory->new), $c, 'isa ->in';
    isa_ok $csv->out( CSV_TEMP ),              $c, 'isa ->out';
    isa_ok $csv->trickle([42]),                $c, 'isa ->trickle';
    isa_ok $csv->spurt([[42]]),                $c, 'isa ->spurt';
    isa_ok $csv->flush,                        $c, 'isa ->flush';

    unlink CSV_TEMP;
}

{ # Slurping CSV
    my $expected = sample_csv();
    my @in = (
        [ CSV_FILE, 'filename' ],
        [ do { open my $fh, '<', CSV_FILE or die $!; $fh }, 'filehandle' ],
        [
            Mojo::Asset::File->new(path => CSV_FILE),
            'Mojo::Asset::File',
        ],
        [
            Mojo::Asset::Memory->new->add_chunk( path(CSV_FILE)->slurp ),
            'Mojo::Asset::Memory',
        ],
    );

    is_deeply Mojo::CSV->new->slurp( $_->[0] )->to_array, $expected,
        "->slurp( arg ) with $_->[1] gives right results"
            for @in;

    is_deeply Mojo::CSV->new->slurp_body( $_->[0] )->to_array,
        [ @$expected[1.. $#$expected] ],
        "->slurp_body with $_->[1] gives right results"
            for @in[0,3]; # skip filehandles because SEEK position is off
}

{   # Reading line-by-line
    my $expected = sample_csv();
    my $csv = Mojo::CSV->new( in => CSV_FILE );
    is_deeply $csv->row, $expected->[$_], '->row correct on line ' . $_
        for 0 .. $#$expected;

    ok ! defined $csv->row, 'another ->row gives undef';

    throws_ok { Mojo::CSV->new->row }
        qr/You must specify what to read/,
        'croaks when nothing to read lines from was given';
}

{ # Spurting CSV
    unlink CSV_TEMP;
    Mojo::CSV->new( out => CSV_TEMP )->spurt( sample_csv() );
    ( my $csv_file = path(CSV_FILE)->slurp ) =~ s/\r\n|\r\n/\n/g;
    is path(CSV_TEMP)->slurp, $csv_file, '->spurt file matches expectations';
}

{ # Writing line-by-line
    unlink CSV_TEMP;
    my $sample = sample_csv();
    my $csv = Mojo::CSV->new( out => CSV_TEMP );
    $csv->trickle( $_ ) for @$sample;
    $csv->flush;
    ( my $csv_file = path(CSV_FILE)->slurp ) =~ s/\r\n|\r\n/\n/g;
    is path(CSV_TEMP)->slurp, $csv_file, '->trickle file matches expectations';

    throws_ok { Mojo::CSV->new->trickle( 42 ) }
        qr/You must specify where to write/,
        'croaks when nothing to write lines to was given';
}

{ # Text
    my $sample = sample_csv();
    my $csv = Mojo::CSV->new;
    chomp( my $expected = path(CSV_FILE)->slurp );
    is $csv->text($sample), $expected, '->text on rows matches expectations';

    my @lines = split m{$/}, $expected;
    is $csv->text($sample->[$_]),
        $lines[$_], '->text on single row matches expectations on row ' . $_
            for 0 .. $#$sample;
}

done_testing;

sub sample_csv {
    return [
          [
            'order date',
            'customer id',
            'customer first_name',
            'customer last_name',
            'order number',
            'item name',
            'item manufacturer',
            'item price'
          ],
          [
            '2013-02-01 12:32:00',
            '7',
            'Publius',
            'Ovidius',
            '23',
            'fountain pen',
            'acme',
            '$3.25'
          ],
          [
            '2013-02-01 12:32:00',
            '7',
            'Publius',
            'Ovidius',
            '23',
            'journal',
            'acme',
            '$5.50'
          ],
          [
            '2013-02-01 13:01:00',
            '22',
            'John',
            'Davidson ',
            '42',
            'journal',
            'acme',
            '$5.50'
          ],
          [
            '2013-02-02 10:19:53',
            '401',
            'Christina',
            'Rosetti',
            '991-2',
            'journal',
            'acme',
            '$5.50'
          ],
          [
            '2013-02-02 09:00:00',
            '19',
            'John ',
            'Davidson',
            '29',
            'journal',
            'PaperWorks',
            '$4.50'
          ],
          [
            '2013-02-05 19:23:04',
            '19',
            'John',
            'Davidson',
            '53-1',
            'pen, ball point',
            'acme',
            '$.99'
          ],
          [
            '2013-02-02 10:19:53',
            '401',
            'Christina',
            'Roseti',
            '13',
            'journal',
            'acme',
            '$5.50'
          ]
    ];
}
