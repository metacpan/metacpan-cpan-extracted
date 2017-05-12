package OTRS::OPM::Analyzer::Role::License;

# ABSTRACT: Check if an appropriate License is used

use Moose::Role;
use Software::License;
use Software::LicenseUtils;

with 'OTRS::OPM::Analyzer::Role::Base';

sub check {
    my ($self,$opm) = @_;
    
    my $license  = $opm->license;
    my $name     = $opm->name;
    return "Could not find any license for $name." if !$license;
    
    # software::licenseutils expect pod, so we have to fake
    # a small pod section
    my $pod = qq~
    =head1 License
    
    $license
    ~;
    
    # try to find the appropriate license
    my @licenses_found = Software::LicenseUtils->guess_license_from_pod( $pod );
    
    my $warning = '';
    if ( !@licenses_found ) {
        $warning = "Could not find the open source license in Software::License for $license.";
    }
    
    return $warning;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::License - Check if an appropriate License is used

=head1 VERSION

version 0.06

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
