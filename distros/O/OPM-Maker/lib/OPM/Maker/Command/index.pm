package OPM::Maker::Command::index;
$OPM::Maker::Command::index::VERSION = '1.12';
use strict;
use warnings;

# ABSTRACT: Build index for an OPM repository

use Carp qw(croak);
use File::Basename;
use File::Find::Rule;
use MIME::Base64 ();
use Sys::Hostname;
use Path::Class ();
use XML::LibXML;
use XML::LibXML::PrettyPrint;

use OPM::Maker -command;
use OPM::Maker::Utils qw(reformat_size);

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
        'ARRAY' ne ref $args ||
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

    my $root_name;
    
    for my $opm_file ( sort @opm_files ) {
        my $size = -s $opm_file;
        my %opts;

        if ( !$ENV{OPM_UNSECURE} ) {
            %opts = (
                no_network      => 1,
                expand_entities => 0,
            );
        }

        # if file is big, but not "too big"
        my $max_size = 31_457_280;
        if ( $ENV{OPM_MAX_SIZE} ) {
            $max_size = reformat_size( $ENV{OPM_MAX_SIZE} );
        }

        if ( $size > $max_size ) {
            croak "$opm_file too big (max size: $max_size bytes)";
        }

        if ( $size > 10_000_000 ) {
            $opts{huge} = 1;
        }

        my $parser = XML::LibXML->new( %opts );
        my $tree   = $parser->parse_file( $opm_file );
        
        $tree->setStandalone( 0 );
        
        my $root_elem = $tree->getDocumentElement;
        $root_name = $root_elem->nodeName();
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
        my $file_path = $opm_file;

        $file_path =~ s/\Q$dir//      if $dir ne '.';
        $file_path = '/' . $file_path if '/' ne substr $file_path, 0, 1;

        $file_node->appendText( $file_path );
        $root_elem->addChild( $file_node );
        
        $pp->pretty_print( $tree );
        
        my $xml = $tree->toString;
        $xml =~ s{<\?xml .*? \?> \s+}{}x;
        
        push @packages, $xml;
    }

    $root_name //= 'otrs';
    my $product  = $root_name =~ m{otobo} ? 'otobo' : 'otrs';
 
    my $packages_list = join '', @packages;
    
    print sprintf qq~<?xml version="1.0" encoding="utf-8" ?>
<%s_package_list version="1.0">
%s
</%s_package_list>
~, $product, $packages_list, $product;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Command::index - Build index for an OPM repository

=head1 VERSION

version 1.12

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
