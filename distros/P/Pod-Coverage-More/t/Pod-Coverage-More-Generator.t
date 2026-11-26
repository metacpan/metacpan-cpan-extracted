#!perl

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use File::Temp qw{tempfile};
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/elsewhere";

use Pod::Coverage::More;
use Pod::Coverage::More::Generator;

# The fixture, whose subs have blurbs and no POD, but for one.
require Blurbed;

my $generator = Pod::Coverage::More::Generator->new( package => 'Blurbed' );
my %pod       = map { $_->{name} => $_->{pod} } $generator->sections;

subtest sections => sub {
    is( [ map { $_->{name} } $generator->sections ], [qw{double hook make maybe missing port yes}], "a section for each public sub with a blurb and no POD, in order" );
    ok( !exists $pod{documented}, "a sub documented by hand gets none" );
    ok( !exists $pod{plain},      "nor does a sub without a blurb" );
    is( $generator->pod, join( q{}, map { $pod{$_} } qw{double hook make maybe missing port yes} ), "pod is the sections one after another" );
};

subtest section => sub {
    is( $pod{make}, <<'POD', "the blurb, with the keys of the named arguments, and an object of the class that the code blesses into, its invocant" );
=head2 make(size, colour)

Make a widget from named options.

=over 4

=item size - Int - how big

=item colour - Str - what colour

=back

Returns a Blurbed object.

Dies when the size is negative.

Dies with a Blurbed::Exception when the size is over 1000.

    my $widget = Blurbed->make( size => 3, colour => 'red' );

POD
    like( $pod{yes},   qr/^Returns[ ]Int[.]$/m,                                         "a literal that the code returns gives the type" );
    like( $pod{maybe}, qr/^Returns[ ]a[ ]Blurbed[ ]object[ ]or[ ]Undef[.]$/m,           "an object of a class, or undef" );
    like( $pod{hook},  qr/^=item[ ]record[ ]-[ ]HashRef[ ]-[ ]what[ ]to[ ]work[ ]on$/m, "a stub takes its arguments from its blurb" );
    unlike( $pod{hook}, qr/^Returns/m, "and a sub that returns nothing says nothing of it" );
    like( $pod{port},    qr/^Returns[ ]Int,[ ]443[ ]when[ ]nothing[ ]else[ ]is[ ]set[.]$/m, "a \@returns whose first word names no type is text, after the type that the code shows" );
    like( $pod{missing}, qr/^=head2[ ]missing\(snapshot,[ ]paths\)$/m,                      "a list parameter is named without its sigil in the heading" );
    like( $pod{missing}, qr/^=item[ ]\@paths[ ]-[ ]Str[ ]-[ ]each/m,                        "and with it in its item, as \@param wrote it, so the type is of each element" );
};

subtest inherited_blurbs => sub {
    require BlurbedChild;
    my @names = map { $_->{name} } Pod::Coverage::More::Generator->new( package => 'BlurbedChild' )->sections;
    is( \@names, [qw{documented double triple}], "an override whose blurb has a tag gets a section, whether its parent has a blurb or POD for it" );
    ok( !grep( { $_ eq 'hook' } @names ), "but an override under a comment with no tag gets none, as its parent documents it" );

    my $child = Pod::Coverage::More::Generator->new( package => 'BlurbedChild' );
    my ( $fh, $file ) = tempfile( SUFFIX => '.pod', UNLINK => 1 );
    print {$fh} "=head1 NAME\n\nBlurbedChild\n\n", $child->pod, "=cut\n";
    close($fh) or die "Cannot close $file: $!\n";
    my $report = Pod::Coverage::More->new( package => 'BlurbedChild', pod_from => $file )->coverage_report;
    is( [ grep { $report->{$_} } qw{documented double triple} ], [qw{documented double triple}], "and the checks read those sections" );
    my @failures;
    foreach my $name (qw{documented double triple}) {
        foreach my $check ( sort keys %{ $report->{$name}{failures} } ) {
            push @failures, map { "[$check] $_" } @{ $report->{$name}{failures}{$check} };
        }
    }
    is( \@failures, [], "which passes them" );

    require CommentedChild;
    @names = map { $_->{name} } Pod::Coverage::More::Generator->new( package => 'CommentedChild' )->sections;
    is( \@names, ['after_release'], "a comment above the sub in a parent class from another tree is no blurb, so the override gets a section" );
};

subtest the_checks_pass => sub {
    my ( $fh, $file ) = tempfile( SUFFIX => '.pod', UNLINK => 1 );
    print {$fh} "=head1 NAME\n\nBlurbed\n\n=head2 documented\n\nDocumented by hand.\n\n    Blurbed::documented();\n\n", $generator->pod, "=cut\n";
    close($fh) or die "Cannot close $file: $!\n";

    my $pc     = Pod::Coverage::More->new( package => 'Blurbed', pod_from => $file );
    my $report = $pc->coverage_report;
    my @failures;
    foreach my $name (qw{double hook make maybe missing port yes}) {
        foreach my $check ( sort keys %{ $report->{$name}{failures} } ) {
            push @failures, map { "[$check] $_" } @{ $report->{$name}{failures}{$check} };
        }
    }
    is( \@failures,     [],        "every generated section passes every check" );
    is( [ $pc->naked ], ['plain'], "and only the sub without a blurb is left undocumented" );
};

done_testing;
