package OPM::Maker::Command::build;
$OPM::Maker::Command::build::VERSION = '1.15';
use strict;
use warnings;

# ABSTRACT: Build OPM packages

use Carp qw(croak);
use MIME::Base64 ();
use Sys::Hostname;
use Path::Class ();
use XML::LibXML;

use OPM::Maker -command;
use OPM::Maker::Utils qw(reformat_size check_args_sopm);

sub abstract {
    return "build package files for Znuny, OTOBO or ((OTRS)) Community Edition";
}

sub usage_desc {
    return "opmbuild build [--version <version>] [--basedir <output_path>] [--output <output_path>] <path_to_sopm>";
}

sub opt_spec {
    return (
        [ "output=s",  "Output path for OPM file" ],
        [ "basedir=s",  "Base directory of SOPM files" ],
        [ "version=s", "Version to be used (override the one from the sopm file)" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $sopm = check_args_sopm( $args );

    $self->usage_error( 'need path to .sopm' ) if
        !$sopm;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $file = check_args_sopm( $args );

    my $hostname  = hostname;
    my @time      = localtime;
    my $timestamp = sprintf "%04d-%02d-%02d %02d:%02d:%02d", 
        $time[5]+1900, $time[4]+1, $time[3], 
        $time[2], $time[1], $time[0];

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
    
    my $sopm_path = Path::Class::File->new( $file );
    my $path      = $sopm_path->dir;
    
    my $root_elem = $tree->getDocumentElement;
    
    # retrieve file information
    my @files = $root_elem->findnodes( 'Filelist/File' );
    
    FILE:
    for my $file ( @files ) {
        my $name         = $file->findvalue( '@Location' );
        my $file_path    = Path::Class::File->new( 
            $opt->{basedir} ? $opt->{basedir} : $path, $name );
        my $file_content = $file_path->slurp;
        my $base64       = MIME::Base64::encode( $file_content );
        
        $file->setAttribute( 'Encode', 'Base64' );
        $file->appendText( $base64 );
    }
    
    my $build_date = XML::LibXML::Element->new( 'BuildDate' );
    $build_date->appendText( $timestamp );
    
    my $build_host = XML::LibXML::Element->new( 'BuildHost' );
    $build_host->appendText( $hostname );
    
    $root_elem->addChild( $build_date );
    $root_elem->addChild( $build_host );
    
    my $version = $root_elem->find( 'Version' )->[0];
    if ( $opt->{version} ) {
        $version->removeChildNodes();
        $version->appendText( $opt->{version} );
    }
    my $package_name = $root_elem->findvalue( 'Name' );
    my $file_name    = sprintf "%s-%s.opm", $package_name, $version->textContent;
    
    my $output_path = $opt->{output};
    $output_path    = $path if !$output_path;

    my $opm_path    = Path::Class::File->new( $output_path, $file_name );
    my $fh          = $opm_path->openw;
    $fh->print( $tree->toString );

    return $opm_path->stringify;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Command::build - Build OPM packages

=head1 VERSION

version 1.15

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
