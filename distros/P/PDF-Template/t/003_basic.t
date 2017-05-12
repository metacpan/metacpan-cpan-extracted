# -*- perl -*-

# t/003_basic.t - check handling of basic templates

use Test::More tests => 1;

use lib qw(
    t
    blib/lib
);

use File::Spec;
use IO::File;

use PDF::Template;

my @tests = (
    '003_1',
);

my %File = (
    XML => 'xml.txt',
    CMP => 'buffer.txt',
    VAR => 'vars.txt',
);

my $DEBUG = 0;

my $dir = File::Spec->catfile('t', 'templates');

foreach my $test (@tests)
{
    my $pdf = PDF::Template->new(
        filename => File::Spec->catfile($dir, $test, $File{XML}),
    );

    %params = ();
    do File::Spec->catfile($dir, $test, $File{VAR});
    $pdf->param(%params) if keys %params;

    my $buffer = $pdf->get_buffer;
    my $compare = read_file(File::Spec->catfile($dir, $test, $File{CMP}));

#GGG Remove when possible
    if ($DEBUG)
    {
        print "$buffer\n";
        my @x = split $/, $buffer;
        my @y = split $/, $compare;

        print("Not equal in size\n"), next unless @x == @y;
        foreach my $i (0 .. $#x)
        {
            print "$x[$i] is not equal to $y[$i]\n"
                unless $x[$i] eq $y[$i];
        }
    }

    ok($buffer eq $compare, "$test built");
}

sub read_file
{
    my $fh = IO::File->new($_[0]) || die "Cannot open '$_[0]' for reading: $!\n";
    join '', <$fh>;
}

