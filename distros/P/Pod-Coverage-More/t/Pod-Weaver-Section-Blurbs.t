#!perl

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use File::Temp qw{tempdir};
use PPI;
use Pod::Elemental;
use Pod::Weaver;

# Weaves POD with [@CorePrep] and [Blurbs], for the module in FILE.
sub weave {
    my ( $pod, $file ) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    open( my $ini, '>', "$dir/weaver.ini" ) or die "weaver.ini: $!";
    print {$ini} "[\@CorePrep]\n[Blurbs]\n[Leftovers]\n";
    close($ini) or die "weaver.ini: $!";
    my $weaver = Pod::Weaver->new_from_config( { root => $dir } );
    my $woven  = $weaver->weave_document( { pod_document => Pod::Elemental->read_string($pod), ppi_document => PPI::Document->new($file), filename => $file } );
    return $woven->as_pod_string;
}

subtest a_new_section => sub {
    my $woven = weave( "=head1 NAME\n\nBlurbed\n\n=cut\n", 't/lib/Blurbed.pm' );
    like( $woven, qr/^=head1[ ]METHODS$/m,                        "the sections go under a new METHODS" );
    like( $woven, qr/^=head2[ ]double\(count\)$/m,                "with one for each sub that has a blurb" );
    like( $woven, qr/^Returns[ ]Num,[ ]twice[ ]the[ ]count[.]$/m, "as the generator writes it" );
    unlike( $woven, qr/^=head2[ ]plain/m, "and none for a sub without a blurb" );
    like( $woven, qr/^=head1[ ]NAME$/m, "and the POD that was there stays" );
};

subtest an_existing_section => sub {
    my $woven   = weave( "=head1 NAME\n\nBlurbed\n\n=head1 METHODS\n\n=head2 written\n\nBy hand.\n\n=cut\n", 't/lib/Blurbed.pm' );
    my @headers = $woven =~ m/^=head1[ ]METHODS$/mg;
    is( scalar @headers, 1, "the sections join the METHODS that the POD has" );
    like( $woven, qr/^=head2[ ]written\n.*^=head2[ ]double\(count\)$/ms, "after what is there" );
};

subtest a_script_whose_package_has_no_module_file => sub {
    my $woven = weave( "=head1 NAME\n\nscripted\n\n=cut\n", 't/script/scripted' );
    like( $woven, qr/^=head2[ ]greet\(name\)$/m,             "the script loads by its path, and its subs get sections" );
    like( $woven, qr/^Returns[ ]Str,[ ]the[ ]greeting[.]$/m, "from the blurbs of the script" );
};

subtest a_module_that_does_not_load => sub {
    my $dir = tempdir( CLEANUP => 1 );
    open( my $ini, '>', "$dir/weaver.ini" ) or die "weaver.ini: $!";
    print {$ini} "[\@CorePrep]\n[Blurbs]\n";
    close($ini) or die "weaver.ini: $!";
    my $weaver = Pod::Weaver->new_from_config( { root => $dir } );
    my $input  = { pod_document => Pod::Elemental->read_string("=head1 NAME\n\nNo::Such::Module\n\n=cut\n"), ppi_document => PPI::Document->new( \"package No::Such::Module;\n1;\n" ), filename => 't/lib/No/Such/Module.pm' };
    like( dies { $weaver->weave_document($input) }, qr/\ACannot[ ]generate[ ]the[ ]POD[ ]of[ ]No::Such::Module/, "the build stops, naming the module" );
};

done_testing;
