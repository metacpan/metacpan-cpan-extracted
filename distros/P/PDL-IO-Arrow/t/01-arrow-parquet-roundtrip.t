use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use PDL;
use PDL::IO::Arrow qw(rarrow warrow rparquet wparquet);

my $cols = {
    ids    => long([10, 20, 30, 40]),
    bigids => longlong([10000000001, 10000000002, 10000000003, 10000000004]),
    scores => double([1.25, 2.5, -3.75, 4.0]),
    f32    => float([0.5, 1.5, 2.5, 3.5]),
    c64    => cfloat([1, 2, 3, 4]),
    c128   => cdouble([1.5, -2.5, 3.5, -4.5]),
};

sub _read_magic {
    my ($path, $len) = @_;
    open my $fh, '<:raw', $path or die $!;
    read($fh, my $buf, $len);
    close $fh;
    return $buf;
}

# 1. Arrow IPC round-trip
my ($afh, $arrow_file) = tempfile('pdl_arrow_XXXXXX', SUFFIX => '.arrow', UNLINK => 1);
close $afh;

ok(warrow($cols, $arrow_file), 'warrow succeeded');
is(_read_magic($arrow_file, 6), 'ARROW1', 'Arrow IPC file has ARROW1 magic header');
my $read_arrow = rarrow($arrow_file);
is_deeply([ $read_arrow->{ids}->list ],    [10, 20, 30, 40],                 'Arrow int32 round-trip');
is_deeply([ $read_arrow->{bigids}->list ], [10000000001, 10000000002, 10000000003, 10000000004], 'Arrow int64 round-trip');
is_deeply([ $read_arrow->{scores}->list ], [1.25, 2.5, -3.75, 4.0],          'Arrow float64 round-trip');
is_deeply([ $read_arrow->{f32}->list ],    [0.5, 1.5, 2.5, 3.5],             'Arrow float32 round-trip');
is($read_arrow->{c64}->type->ioname,       'cfloat',                         'Arrow cfloat type preserved');
is($read_arrow->{c128}->type->ioname,      'cdouble',                        'Arrow cdouble type preserved');

# 2. Parquet round-trip
my ($pfh, $parquet_file) = tempfile('pdl_parquet_XXXXXX', SUFFIX => '.parquet', UNLINK => 1);
close $pfh;

ok(wparquet($cols, $parquet_file), 'wparquet succeeded');
is(_read_magic($parquet_file, 4), 'PAR1', 'Parquet file has PAR1 magic header');
my $read_parquet = rparquet($parquet_file);
is_deeply([ $read_parquet->{ids}->list ],    [10, 20, 30, 40],               'Parquet int32 round-trip');
is_deeply([ $read_parquet->{bigids}->list ], [10000000001, 10000000002, 10000000003, 10000000004], 'Parquet int64 round-trip');
is_deeply([ $read_parquet->{scores}->list ], [1.25, 2.5, -3.75, 4.0],        'Parquet float64 round-trip');
is_deeply([ $read_parquet->{f32}->list ],    [0.5, 1.5, 2.5, 3.5],           'Parquet float32 round-trip');
is($read_parquet->{c64}->type->ioname,       'cfloat',                       'Parquet cfloat type preserved');
is($read_parquet->{c128}->type->ioname,      'cdouble',                      'Parquet cdouble type preserved');

done_testing();
