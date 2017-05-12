use strict;
use warnings;

use Benchmark qw( cmpthese );

my %modules = map {
    eval "require $_" if $_ ne 'Internal';
    $@ ? () : ( $_ => make_sub($_) )
} qw( File::LibMagic File::MMagic File::Type Internal );

my $filename = 'data.sample';
open my $fh, '>', $filename;
print $fh 'Some sample ASCII data for mime detecting';
close $fh;

cmpthese( 9_000, \%modules );

sub make_sub {
    ( my $module = shift ) =~ s/:://g;
    $module = "SVK::MimeDetect::$module";
    eval "require $module";
    die "Couldn't load $module\n" if $@;
    my $object = $module->new();
    return sub { $object->checktype_filename($filename) };
}
