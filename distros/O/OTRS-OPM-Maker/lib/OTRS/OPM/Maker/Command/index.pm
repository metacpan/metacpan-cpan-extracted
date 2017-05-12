package OTRS::OPM::Maker::Command::index;

use strict;
use warnings;

# ABSTRACT: Build index for an OPM repository

use File::Basename;
use File::Find::Rule;
use MIME::Base64 ();
use Sys::Hostname;
use Path::Class ();
use XML::LibXML;
use XML::LibXML::PrettyPrint;

use OTRS::OPM::Maker -command;

our $VERSION = 0.07;

sub abstract {
    return "build index for an OPM repository";
}

sub usage_desc {
    return "opmbuild index <path_to_directory>";
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    
    $self->usage_error( 'need path to directory that contains opm files' ) if
        !$args ||
        !$args->[0] ||
        !-d $args->[0];
}

sub execute {
    my ($self, $opt, $args) = @_;
    
    my $dir = $args->[0];
    
    my @opm_files = File::Find::Rule->file->name( '*.opm' )->in( $dir );
    
    my @packages;
    my $pp = XML::LibXML::PrettyPrint->new( 
        indent_string => '  ',
        element       => {
            compact => [qw(
                Vendor Name Description Version Framework 
                ModuleRequired PackageRequired URL License
                File
            )],
        },
    );
    
    for my $file ( @opm_files ) {
        my $parser = XML::LibXML->new;
        my $tree   = $parser->parse_file( $file );
        
        $tree->setStandalone( 0 );
        
        my $root_elem = $tree->getDocumentElement;
        $root_elem->setNodeName( 'Package' );
        $root_elem->removeAttribute( 'version' );
        
        # retrieve file information
        my @files = $root_elem->findnodes( 'Filelist/File' );
        
        FILE:
        for my $file ( @files ) {
            my $location = $file->findvalue( '@Location' );
            
            # keep only documentation in file list
            if ( $location !~ m{\A doc/}x ) {
                $file->parentNode->removeChild( $file );
            }
            else {
                my @child_nodes = $file->childNodes;
                
                # clean nodes
                $file->removeChild( $_ ) for @child_nodes;
                $file->removeAttribute( 'Encode' );
                $file->setNodeName( 'FileDoc' );
            }
        }
        
        # remove unnecessary nodes
        for my $node_name ( qw(Code Intro Database)) {
            for my $phase ( qw(Install Upgrade Reinstall Uninstall) ) {
                my @nodes = $root_elem->findnodes( $node_name . $phase );
                $_->parentNode->removeChild( $_ ) for @nodes;
            }
        }
        
        for my $node_name ( qw(BuildHost BuildDate)) {
            my @nodes = $root_elem->findnodes( $node_name );
            $_->parentNode->removeChild( $_ ) for @nodes;
        }
        
        my $file_node  = XML::LibXML::Element->new( 'File' );
        (my $file_path = $file) =~ s/\Q$dir//;
        $file_node->appendText( $file_path );
        $root_elem->addChild( $file_node );
        
        $pp->pretty_print( $tree );
        
        my $xml = $tree->toString;
        $xml =~ s{<\?xml .*? \?> \s+}{}x;
        
        push @packages, $xml;
    }
    
    print sprintf qq~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package_list version="1.0">
%s
</otrs_package_list>
~, join "", @packages;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Maker::Command::index - Build index for an OPM repository

=head1 VERSION

version 0.11

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
