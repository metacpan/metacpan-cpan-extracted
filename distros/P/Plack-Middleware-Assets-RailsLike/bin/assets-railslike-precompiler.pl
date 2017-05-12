#!perl

use utf8;
use strict;
use warnings;
use File::Basename;
use File::Slurp;
use File::Spec::Functions qw(catfile);
use Digest::SHA1 qw(sha1_hex);
use Getopt::Long;
use Plack::Middleware::Assets::RailsLike::Compiler;
use Pod::Usage;

GetOptions( \my %options,
    'version-number|n=s', 'search-path|s=s', 'verbose|v', 'help|h' )
    or pod2usage(1);

pod2usage(0) if $options{help};
pod2usage(1) if scalar @ARGV == 0;

our @SUFFIX = qw(.js .css .less .sass .cass);

my $compiler = Plack::Middleware::Assets::RailsLike::Compiler->new(
    minify      => 1,
    search_path => [ split /,/, $options{'search-path'} ],
);

for my $filename (@ARGV) {
    compile( $compiler, $filename, \%options );
}

# functions

sub compile {
    my ( $compiler, $filename, $options ) = @_;
    my $manifest = read_file( $filename, { err_mode => 'carp' } );
    next unless $manifest;

    my ( $basename, $path, $suffix ) = _fileparse( $filename, \%options );
    unless ($suffix) {
        warn "Cannot guess file type from $filename.";
    }
    my $type = guess_type($suffix);

    my $content = $compiler->compile(
        manifest => $manifest,
        type     => $type,
    );

    my $version = $options->{'version-number'} || sha1_hex($content);

    my $new_filename
        = catfile( $path, sprintf( '%s-%s.%s', $basename, $version, $type ) );

    my $is_success
        = write_file( $new_filename, { atomic => 1, err_mode => 'carp' },
        $content );

    if ( $is_success and $options->{verbose} ) {
        warn "Compiles $filename => $new_filename\n";
    }
}

sub guess_type {
    my $suffix = shift;
    $suffix =~ s/^\.//;

    my $type;
    if ( $suffix and $suffix eq 'js' ) {
        $type = 'js';
    }
    elsif ($suffix) {
        $type = 'css';
    }
    else {
        $type = 'js';
    }

    return $type;
}

sub _fileparse {
    my ( $filename, $options ) = @_;
    if ( $filename eq \*STDIN ) {
        my $suffix = $options->{type} || 'js';
        return 'tmp', '.', ".$suffix";
    }
    else {
        my ( $basename, $path, $suffix ) = fileparse( $filename, @SUFFIX );
        return $basename, $path, $suffix;
    }
}

__END__

=encoding utf-8

=head1 NAME

assets-railslike-precompiler.pl - Compiles asset files.

=head1 SYNOPSIS

assets-railslike-precompiler.pl
    [--version-number VERSION] [--search-path PATHS] [--verbose]
    [--help] FILE [FILE ...]

    --version-number | -n
        Uses specified version-number instead of sha1 string of contents.

    --search-path | -s 
        Sets search path(comma separated string).

    --verbose | -v
        Outputs more infomations.
        
    --help | -h
        Shows this message.

=head2 EXAMPLES

    > find assets -type f -name '*.js' | xargs assets-railslike-precompiler.pl -n v$(date +%Y%m%d) -s static/js,static/css -v

=head1 LICENSE

Copyright (C) 2013 Yoshihiro Sasaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki@cpan.orgE<gt>

=cut
