package Perl::Metrics::Lite::Analysis::File::Plugin::Packages;
use strict;
use warnings;

sub init { }

sub measure {
    my ( $class, $context, $file ) = @_;
    my @unique_packages = ();
    my $found_packages  = $file->find('PPI::Statement::Package');

    return scalar @unique_packages
        if (
        !Perl::Metrics::Lite::Analysis::Util::is_ref( $found_packages, 'ARRAY' ) );

    my %seen_packages = ();

    foreach my $package ( @{$found_packages} ) {
        $seen_packages{ $package->namespace() }++;
    }

    @unique_packages = sort keys %seen_packages;

    return scalar @unique_packages;
}

1;

