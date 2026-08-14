#!/usr/bin/env perl
# filter source code using Sys::OsRelease to Sys::OsRelease::Lite
# This allows Sys::OsRelease::Lite which provides support for older Perl versions to be
# directly maintained from the source code for Sys::OsRelease.
#
# Copyright 2026 by Ian Kluft
# Open Source license Perl's Artistic License 2.0: <http://www.perlfoundation.org/artistic_license_2_0>
# SPDX-License-Identifier: Artistic-2.0
use v5.10.1;
use strict;
use warnings;
use utf8;
use Carp qw(croak);
use Readonly;
use FindBin qw($Bin);
use File::Path qw(make_path);
use File::Basename qw(dirname basename);
use Config::Tiny;
use File::Slurp qw(read_file);
use Data::Dumper;
use YAML qw(LoadFile);

# constants
Readonly::Scalar my $Metafile     => dirname($Bin) . "/MYMETA.yml";
Readonly::Scalar my $Debug        => ( $ENV{SORL_DEBUG} // 0 ? 1 : 0 );
Readonly::Scalar my $Version      => version_from_meta();
Readonly::Scalar my $RecognizeMod => "Sys::OsRelease";
Readonly::Scalar my $ReplaceMod   => "Sys::OsRelease::Lite";
Readonly::Scalar my $PkgLineRE    => qr/ ^ \s* package \s+ $RecognizeMod \s* ;  /x;
Readonly::Scalar my $CodeEndRE    => qr/ ^ \s* ( __END__ | __DATA__ ) ( \s+ .* | \s* ) $ /x;
Readonly::Scalar my $PodStartRE   => qr/ \A = [a-zA-Z]+ /x;
Readonly::Scalar my $PodEndRE     => qr/ \A =cut /x;

# debugging statements when enabled
sub debug
{
    my @text = @_;
    if ($Debug) {
        say STDERR "debug: " . join( " ", @text );
    }
    return;
}

# get version number from project metadata
sub version_from_meta
{
    # read YAML data
    my $metadata = YAML::LoadFile( $Metafile )
        or croak "$0: failed to read $Metafile";
    if ( not exists $metadata->{version}) {
        print STDERR Dumper(\%ENV);
        croak "$0: Version not found in $Metafile";
    }
    my $version = $metadata->{version};

    # just the semantic version numbering - remove "v" prefix if present
    if ( substr( $version, 0, 1 ) eq "v" ) {
        substr( $version, 0, 1, "" );
    }

    return $version;
}

# print a line of output
sub do_print
{
    my ( $output, @text ) = @_;

    my ( $output_fh, $output_file ) = @$output;
    foreach my $text ( @text ) {
        print $output_fh $text
            or croak "$0: error printing to $output_file: $!";
    }

    return;
}

# POD header for module files, like what Dist::Zilla would do for us except ...::Lite can't use it
sub pod_header
{
    my $output = shift;
    my $attr = shift;

    # output module POD header
    do_print ( $output, 
        "\n",
        "=pod\n",
        "\n",
        "=encoding UTF-8",
        "\n",
        "=head1 NAME\n",
        "\n",
        "$ReplaceMod" . (( exists $attr->{ABSTRACT} ) ? " - " . $attr->{ABSTRACT} : "" ) . "\n",
        "\n",
        "=head1 VERSION\n",
        "\n",
        "version $Version\n",
        "\n"
    );

    return;
}

# POD footer for module files, like what Dist::Zilla would do for us except ...::Lite can't use it
sub pod_footer
{
    my $dist_config = shift;
    my $output = shift;
    my $attr = shift;

    # get author, copyright and license info for footer
    my $author = $dist_config->{_}{author};
    # TODO

    # output module POD header
    if ( exists $dist_config->{_}{author}) {
        do_print ( $output, 
            "\n",
            "=head1 AUTHOR\n",
            "\n",
            $dist_config->{_}{author} . "\n",
            "\n",
            # "=head1 COPYRIGHT AND LICENSE\n",
            # "\n",
            # "\n", # TODO
        );
    }
    return;
}

# filter output line by line
sub filter_content
{
    my $dist_config = shift;
    my $output = shift;
    my $lines = shift;

    # filter contents
    my $mode = "init";
    my %attr;
    my $found_pkg = 0;
    my $pod_hdr_done = 0;
    for ( my $i = 0; $i < scalar @$lines; $i++ ) {
        # reset flags each line
        $found_pkg = 0;

        # scan code lines
        if ( $mode eq "init" or $mode eq "code" ) {

            # init mode looks for attributes before first blank line, otherwise same behavior as code mode
            if ( $mode eq "init" ) {
                # collect attributes from comments in init mode
                if ( $lines->[$i] =~ / ^ \# \s* ( [A-Za-z0-9_-]+ ) \s* : \s+ ( .* ) /x ) {
                    my $key = $1;
                    my $value = $2;
                    chomp $value;
                    $attr{$key} = $value;
                }

                # end of init mode at first blank line
                if ( $lines->[$i] =~ / ^ \s* $ /x ) {
                    $mode = "code";
                }
            }

            # if package line found, set flag to add VERSION line after this line 
            if ( $lines->[$i] =~ $PkgLineRE ) {
                $found_pkg = 1;
            }

            # replace module name
            if ( $lines->[$i] =~ / $RecognizeMod /x ) {
                $lines->[$i] =~ s/ $RecognizeMod /$ReplaceMod/xg;
            }

            # check for start of POD docs
            if (( $lines->[$i] =~ $PodStartRE ) and not ( $lines->[$i] =~ $PodEndRE )) {
                $mode = "pod";
            }

            # check for end of code
            if ( $lines->[$i] =~ $CodeEndRE ) {
                $mode = "end";

                # generate module POD header at end of code, if not already done for POD section
                if ( not $pod_hdr_done ) {
                    pod_header ( $output, \%attr );
                    $pod_hdr_done = 1;
                }
            }
        } elsif ( $mode eq "pod" ) {
            # generate module POD header first time we find a POD section
            if ( not $pod_hdr_done ) {
                pod_header ( $output, \%attr );
                $pod_hdr_done = 1;
            }

            # check for end of POD docs
            if ( $lines->[$i] =~ $PodEndRE ) {
                $mode = "code";
            }
        }

        # print possibly-modified line
        do_print ( $output, $lines->[$i] );

        # add version if package line was found
        if ( $found_pkg ) {
            do_print ( $output, '$' . $ReplaceMod . "::VERSION = '" . $Version . "';" );
        }

    }
    pod_footer( $dist_config, $output, \%attr);
    return;
}

#
# program main
#
{
    # verify version number was provided by environment
    if ( not defined $Version ) {
        print STDERR Dumper(\%ENV);
        croak "VERSION expected from Makefile - not found in environment";
    }

    # get command-line options
    my $output_file = shift @ARGV;
    my $input_file  = shift @ARGV;

    # load configuration from dist.ini
    my $dist_config = Config::Tiny->read("$Bin/input/dist.ini");

    # load input source file
    my @lines = read_file( $input_file );

    # create path to destination directory if needed
    my $output_dirname = dirname( $output_file );
    if ( not -d $output_dirname ) {
        make_path( $output_dirname );
    }

    # write contents
    open( my $output_fh, ">", $output_file )
        or croak "$0: error opening $output_file for writing: $!";
    filter_content( $dist_config, [ $output_fh, $output_file ], \@lines );
    close $output_fh
        or croak "$0: error closing $output_file after write: $!";
}
