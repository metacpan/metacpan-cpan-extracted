package OTRS::OPM::Maker::Command::dependencies;
$OTRS::OPM::Maker::Command::dependencies::VERSION = '0.19';
# ABSTRACT: List dependencies of OTRS packages

use strict;
use warnings;

use XML::LibXML;

use OTRS::OPM::Maker -command;

sub abstract {
    return "list dependencies for OTRS packages";
}

sub usage_desc {
    return "opmbuild dependencies <path_to_sopm_or_opm>";
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    
    $self->usage_error( 'need path to .sopm or .opm' ) if
        !$args or
        'ARRAY' ne ref $args or
        !defined $args->[0] or
        $args->[0] !~ /\.s?opm\z/ or
        !-f $args->[0];
}

sub execute {
    my ($self, $opt, $args) = @_;
    
    my $file = $args->[0];
    my $parser = XML::LibXML->new;
    my $tree   = $parser->parse_file( $file );
        
    my $root_elem = $tree->getDocumentElement;
    
    # retrieve file information
    my @package_req = $root_elem->findnodes( 'PackageRequired' );
    my @modules_req = $root_elem->findnodes( 'ModuleRequired' );
    
    my %labels = (
        PackageRequired => 'OTRS add on',
        ModuleRequired  => 'CPAN module',
    );
        
    DEP:
    for my $dependency ( @package_req, @modules_req ) {
        my $type    = $dependency->nodeName;
        my $version = $dependency->findvalue( '@Version' );
        my $name    = $dependency->textContent;
        
        print "$name - $version (" . $labels{$type} . ")\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Maker::Command::dependencies - List dependencies of OTRS packages

=head1 VERSION

version 0.19

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
