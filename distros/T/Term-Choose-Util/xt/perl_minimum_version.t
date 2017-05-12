use 5.010000;
use warnings;
use strict;
use Perl::MinimumVersion;
use Perl::Version;
use File::Find;
use Test::More tests => 2;


my $make_minimum;
open my $fh_m, '<', 'Makefile.PL' or die $!;
while ( my $line = <$fh_m> ) {
    if ( $line =~ /^\s*MIN_PERL_VERSION\s*=>\s*'([^']+)',/ ) {
        my $version   = Perl::Version->new( $1 );
        my $numified  = $version->numify;
        $make_minimum  = $numified;
        last;
    }
}
close $fh_m or die $!;


my $pod_minimum;
open my $fh_p, '<', 'lib/Term/Choose/Util.pm' or die $!;
while ( my $line = <$fh_p> ) {
    if ( $line =~ /^=head2\s+Perl\s+version/ .. $line =~ /^=head2\s+Modules/ ) {
        if ( $line =~ /Perl\sversion\s(5\.\d\d?\.\d+)\s/ ) {
            my $version   = Perl::Version->new( $1 );
            my $numified  = $version->numify;
            $pod_minimum  = $numified;
            last;
        }
    }
}
close $fh_p or die $!;


my @files;
for my $dir ( 'lib', 't' ) {
    find( {
        wanted => sub {
            my $file = $File::Find::name;
            return if ! -f $file;
            push @files, $file;
        },
        no_chdir => 1,
    }, $dir );
}
my %explicit_minimum;
for my $file ( @files ) {
    my $object    = Perl::MinimumVersion->new( $file );
    my $min_exp_v = $object->minimum_explicit_version;
    my $version   = Perl::Version->new( $min_exp_v );
    my $numified  = $version->numify;
    $explicit_minimum{$numified}++;
}
my ( $explicit_minimum ) = keys %explicit_minimum;


cmp_ok( $make_minimum, '==', $explicit_minimum, 'perl minimum version in Makefile.PL == explicit perl minimum version' );
cmp_ok( $make_minimum, '==', $pod_minimum,      'perl minimum version in Makefile.PL == pod perl minimum version' );
