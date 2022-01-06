package OPM::Maker::Command::dependencies;
$OPM::Maker::Command::dependencies::VERSION = '1.12';
# ABSTRACT: List dependencies of OTRS packages

use strict;
use warnings;

use Carp qw(croak);
use XML::LibXML;

use OPM::Maker -command;
use OPM::Maker::Utils qw(reformat_size check_args_sopm);

sub abstract {
    return "list dependencies for OPM packages";
}

sub usage_desc {
    return "opmbuild dependencies <path_to_sopm_or_opm>";
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $sopm = check_args_sopm( $args, 1 );
    $self->usage_error( 'need path to .sopm or .opm' ) if
        !$sopm;
}

sub execute {
    my ($self, $opt, $args) = @_;
    
    my $file = check_args_sopm( $args, 1 );

    my %opts;
    if ( !$ENV{OPM_UNSECURE} ) {
        %opts = (
            no_network      => 1,
            expand_entities => 0,
        );
    }

    my $size = -s $file;

    # if file is big, but not "too big"
    my $max_size = 31_457_280;
    if ( $ENV{OPM_MAX_SIZE} ) {
        $max_size = reformat_size( $ENV{OPM_MAX_SIZE} );
    }

    if ( $size > $max_size ) {
        croak "$file too big (max size: $max_size bytes)";
    }

    if ( $size > 10_000_000 ) {
        $opts{huge} = 1;
    }

    my $parser = XML::LibXML->new( %opts );
    my $tree   = $parser->parse_file( $file );
        
    my $root_elem = $tree->getDocumentElement;

    # retrieve file information
    my @package_req = $root_elem->findnodes( 'PackageRequired' );
    my @modules_req = $root_elem->findnodes( 'ModuleRequired' );
    
    my %labels = (
        PackageRequired => 'OPM package',
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

OPM::Maker::Command::dependencies - List dependencies of OTRS packages

=head1 VERSION

version 1.12

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
