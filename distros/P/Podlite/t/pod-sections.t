#!perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use lib "$FindBin::Bin/lib";
use PodliteRun qw(run_perl);

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $file = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, 'lib', 'Podlite.pm' );
open my $fh, '<:encoding(UTF-8)', $file or die "Cannot read $file: $!";
my $pod = do { local $/; <$fh> };
close $fh;
$pod =~ s/\A.*?^__END__\n//ms;

# Text of a section up to the next heading of the same or a higher level...
sub section {
    my ($title) = @_;
    $pod =~ /^=head(\d) \Q$title\E\n/m or return '';
    my ( $level, $rest ) = ( $1, substr( $pod, $+[0] ) );
    $rest =~ s/^=head[1-$level] .*//ms;
    return $rest;
}

sub covers {
    my ( $title, @words ) = @_;
    my $text = section($title);
    ok( index( $text, $_ ) >= 0, "$title mentions $_" ) for @words;
}

covers( 'SYNOPSIS',    '=begin data', '<DATA>' );
covers( 'DESCRIPTION', 'no Podlite;', '__END__', 'main::DATA', '=data-table', 'compile-time error' );

covers( 'General syntactic structure', 'first non-blank character', 'indented directive', 'whitespace',
    '=set', '=include', '=boundary' );

covers( 'Standard configuration options', 'hidden until the reader opens it', 'lower-level content', ':masked',
    'GE<lt>E<gt>' );

covers( 'Block types', '=data-table', ':src', 'recovery', 'no longer a block' );

covers( 'Markup codes', 'GE<lt>E<gt>', 'WE<lt>E<gt>', 'AE<lt>E<gt>', ':download', ':new :title' );

covers( 'Version 2.0 Features', '=boundary', '=set', '=data-table', 'header=present', 'directive', 'Introduced in 1.0' );

covers( 'EXAMPLES', '=set', 'data-table :src', 'header=present' );

# Every example runs through the filter...
{
    my $examples = section('EXAMPLES');
    my @parts = split /^=head2 (.*)\n/m, $examples;
    shift @parts;
    while ( my ( $title, $body ) = splice @parts, 0, 2 ) {
        my $code = join '', grep { /^    / || /^\s*$/ } split /^/, $body;
        $code =~ s/^    //mg;
        $code = "use Podlite;\n$code" unless $code =~ /^use Podlite;/m;
        my $run = run_perl($code);
        ok( $run->{exit} == 0 && $run->{stderr} eq '', "example runs: $title" ) or diag( $run->{stderr} );
    }
}

covers( 'VERSION',      '2.00', 'specification 2.0' );
covers( 'DIAGNOSTICS',  'unclosed =begin', 'without =begin', 'does not close', 'malformed =' );
covers( 'DEPENDENCIES', 'Filter::Util::Call', '5.10.1' );
covers( 'LIMITATIONS',  'package C<main>', 'heredoc', 'C<:key>', 'C<=cut>' );
covers( 'SEE ALSO',     'https://podlite.org/v2.0/specification', '/blob/v2.0.1/Specification.pod6' );

# Both kinds of specification links point at version 2.0 in every published text...
for my $name ( 'lib/Podlite.pm', 'README', 'README.md' ) {
    my $path = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, split m{/}, $name );
    open my $in, '<', $path or die "Cannot read $path: $!";
    my $text = do { local $/; <$in> };
    close $in;
    ok( $text =~ m{podlite\.org/v2\.0/specification}, "$name links the 2.0 page" );
    ok( $text =~ m{podlite-specs/blob/v2\.0\.1/}, "$name links the 2.0.1 source" );
    ok( $text !~ m{podlite\.org/specification}, "$name has no unversioned page link" );
    ok( $text !~ m{Filter::Simple|Makefile\.PL}, "$name names neither Filter::Simple nor Makefile.PL" );
}

done_testing();
