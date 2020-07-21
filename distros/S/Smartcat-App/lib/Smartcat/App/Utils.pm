package Smartcat::App::Utils;

use strict;
use warnings;

use File::Basename;
use File::Spec::Functions qw(catfile);

our @ISA = qw(Exporter);

our @EXPORT = qw(
  prepare_document_name
  prepare_file_name
  save_file
  get_language_from_ts_filepath
  get_ts_file_key
  get_document_key
  format_error_message
  get_file_path
  are_po_files_empty
);


sub get_language_from_ts_filepath {
    $_ = shift;
    return basename( dirname($_) );
}


sub get_ts_file_key {
    $_ = shift;
    return basename($_) . ' (' . get_language_from_ts_filepath($_) . ')';
}


sub get_document_key {
    my ( $name, $target_language ) = @_;

    my $key = $name;
    $key =~ s/_($target_language)$//i;
    return $key . ' (' . $target_language . ')';
}


sub prepare_document_name {
    my ( $path, $filetype, $target_language ) = @_;

    my ( $filename, $_dirs, $ext ) = fileparse( $path, $filetype );

    return $filename . '_' . $target_language . $ext;
}


sub prepare_file_name {
    my ( $document_name, $document_target_language, $ext ) = @_;

    my $regexp = qr/_$document_target_language/;
    $document_name =~ s/(.*)$regexp/$1/;

    return $document_name . $ext;
}


sub get_file_path {
  my ( $project_workdir, $document_target_language, $document_name, $ext ) = @_;
  my $filename =
        prepare_file_name( $document_name, $document_target_language, $ext );

  return catfile( $project_workdir, $document_target_language, $filename );
}


sub format_error_message {
    my $s = shift;

    $s = "  " . $s;
    $s =~ s/\\r//;
    $s =~ s/\\n/\n/;
    $s =~ s/\n/\n  /;

    return $s;
}


sub save_file {
    my ( $filepath, $content ) = @_;
    open( my $fh, '>', $filepath ) or die "Could not open file '$filepath' $!";
    binmode($fh);
    print $fh $content;
    close $fh;
}


sub are_po_files_empty {
    my $filepaths = shift;
    my $res = 1;

    for my $filepath (@$filepaths) {
      open(my $fh, $filepath) or die "Can't read $filepath: $!\n";
      binmode($fh);
      while (my $line = <$fh>) {
        $res = ($1 eq "") if $line =~ m/msgid "(.*)"/;
        last if !$res;
      }
      close $fh;
      last if !$res;
    }

    return $res;
}


1;
