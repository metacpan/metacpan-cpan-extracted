package Smartcat::App::Utils;

use strict;
use warnings;

use File::Basename;
use File::Spec::Functions qw(catfile splitpath splitdir);

use Smartcat::App::Constants qw(
  PATH_SEPARATOR
);
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

sub _get_path_items {
    my ($project_workdir, $path) = @_;

    my ($project_workdir_volume, $project_workdir_dirs, $project_workdir_name) = splitpath($project_workdir);
    my ($volume, $dirs, $name) = splitpath($path);

    my @project_workdir_dirs = grep {$_ ne ""} splitdir($project_workdir_dirs);
    push @project_workdir_dirs, $project_workdir_name if $project_workdir_name ne "";

    my @result = grep {$_ ne ""} splitdir($dirs);
    foreach (@project_workdir_dirs) {
        shift @result if $_ eq $result[0];
    }
    push @result, $name;

    return @result;
}

sub get_language_from_ts_filepath {
    my ($project_workdir, $path) = @_;

    my @path_items = _get_path_items($project_workdir, $path);

    return shift @path_items;
}


sub get_ts_file_key {
    my ($project_workdir, $path) = @_;

    my @path_items = _get_path_items($project_workdir, $path);

    my $language = shift @path_items;
    my $filepath = join(PATH_SEPARATOR, @path_items);

    return "$filepath ($language)";
}


sub get_document_key {
    my ( $name, $target_language ) = @_;

    my $key = $name;
    $key =~ s/_($target_language)$//i;
    return $key . ' (' . $target_language . ')';
}


sub prepare_document_name {
    my ( $project_workdir, $path, $filetype, $target_language ) = @_;

    $path = join(PATH_SEPARATOR, _get_path_items($project_workdir, $path));
    my ( $filename, $dirs, $ext ) = fileparse( $path, $filetype );
    my @path_items = grep { $_ ne '' } splitdir($dirs);
    shift @path_items;
    push @path_items, $filename;
    my $filepath = join(PATH_SEPARATOR, @path_items);

    return $filepath . '_' . $target_language . $ext;
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
    my $empty = 1;

    for my $filepath (@$filepaths) {
        open(my $fh, $filepath) or die "Can't read $filepath: $!\n";
        binmode($fh, ':utf8');
        my $text = join('', <$fh>);
        close $fh;

        # join multi-line entries
        $text =~ s/"\r?\n"//sg;

        if ($text =~ m/msgid "[^"]/s) {
            $empty = undef;
            last;
        }
    }
    return $empty;
}


1;
