#!/usr/bin/perl

# PODNAME: de_opm.pl
# ABSTRACT: create the files listed in the .opm (unpack it)

use strict;
use warnings;

use LWP::Simple qw(getstore);
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use FindBin;

use lib $FindBin::Bin . '/../lib';
use OTRS::OPM::Parser;

my $location = $ARGV[0];
my $out_dir  = $ARGV[1];

if ( $location =~ m{ \A (?:f|ht)tp:// } ) {
    my  ($fh,$file) = File::Temp::tempfile();
    close $fh;
    
    getstore( $location, $file );
    
    $location = $file;
}

if ( !-f $location ) {
    die "Usage: $0 <location> <output_directory>";
}

my $object = OTRS::OPM::Parser->new(
    opm_file => $location,
);

$object->parse;

for my $file ( @{ $object->files } ) {
    print "create $file->{filename}...\n";
    my $full_path = File::Spec->catfile( $out_dir, $file->{filename} );
    my $dir       = dirname( $full_path );
    
    make_path( $dir ) if !-e $dir;
    
    open my $fh, '>', $full_path or next;
    print $fh $file->{content};
    close $fh;
}

print "create ", $object->name, ".sopm...\n";
my $sopm_file = File::Spec->catfile(
    $out_dir,
    $object->name . '.sopm',
);

open my $fh, '>', $sopm_file or exit 1;
print $fh $object->as_sopm;
close $fh;

print "done\n";

__END__

=pod

=encoding UTF-8

=head1 NAME

de_opm.pl - create the files listed in the .opm (unpack it)

=head1 VERSION

version 1.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
