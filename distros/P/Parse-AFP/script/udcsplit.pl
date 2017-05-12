#!/usr/local/bin/perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../Parse-Binary/lib";

use strict;
use Parse::AFP;
use Parse::AFP::PTX;
use Getopt::Std;
use File::Path 'rmtree';

{
package Parse::AFP::Record;
sub new {
    my ($self, $buf, $attr) = @_;
    if (substr($$buf, 3, 3) eq "\xD3\xEE\x9B") {
        return bless($buf, 'PTX');
    }
    return $self->SUPER::new($buf, $attr);
}
sub PTX::done { return }
sub PTX::callback { main::PTX($_[0], $_[0]) }
}

my %NoUDC = (
    947 => qr{
        ^
            (?:
                [\x00-\x7f]+
            |
                (?:[\xA1-\xC5\xC9-\xF9].)+
            |
                (?:\xC6[^\xA1-\xFE])+
            )*
        $
    }x,
    835 => qr{^[^\x92-\xFE]*$}x,
);

my %opts;
getopts('i:o:c:', \%opts);
my $input       = $opts{i} || shift;
my $output      = $opts{o} || shift || 'udcdir';
my $codepage    = $opts{c} || 947;

die "Usage: $0 -c [947|835] -i input.afp -o udcdir\n"
    if grep !defined, $input, $codepage, $output;

rmtree([ $output ]) if -d $output;

my $NoUDC = $NoUDC{$codepage} or die "Unknown codepage: $codepage\n";
my ($has_udc, $name, $prev, $has_BNG, $PTX_cnt);
$name = $prev = 0;

mkdir $output;
my $afp = Parse::AFP->new($input, { lazy => 1, output_file => "$output/0" });
$afp->callback_members([qw( BMO BNG BPG PTX * )]);

if ($has_udc) {
    rename("$output/$name" => "$output/$name.udc") or die $!;
}

sub BNG {
    $prev = $name; $name++;
    $has_BNG = 1;

    $afp->set_output_file("$output/$name");

    if ($has_udc) {
        print STDERR '.';
        rename("$output/$prev" => "$output/$prev.udc") or die $!;
        $has_udc = 0;
    }

    $_[0]->done;
}

BEGIN { *BMO = *BPG; }

sub BPG {
    if( !$has_BNG ) {

	$prev = $name; $name++;
	$afp->set_output_file("$output/$name");

	if ($has_udc) {
	    print STDERR '.';
	    rename("$output/$prev" => "$output/$prev.udc") or die $!;
	    $has_udc = 0;
	}
    }
    else {
	$has_BNG = 0;
    }	

    $_[0]->done;
}

sub PTX {
    my ($rec, $buf) = @_;

    return $rec->done if $has_udc;

    # Now iterate over $$buf.
    my $pos = 11;
    my $len = length($$buf);

    while ($pos < $len) {
        my ($size, $code) = unpack("x${pos}CC", $$buf);

        $size or die "Incorrect parsing: $pos\n";

        if ($code == 0xDA or $code == 0xDB) {
            if ( substr($$buf, $pos + 2, $size - 2) !~ /$NoUDC/o) {
                $has_udc = 1;
                last;
            }
        }

        $pos += $size;
    }

    $rec->done;
}

sub __ { $_[0]->done }
