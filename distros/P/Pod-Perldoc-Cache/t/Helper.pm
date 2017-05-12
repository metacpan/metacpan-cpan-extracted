package t::Helper;

use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempfile tempdir);
use Digest::MD5 qw(md5_hex);
use Exporter qw(import);

our @EXPORT = qw(
    mk_podfile
    mk_outfile
    mk_cache_dir
    get_cache_file_path 
    read_from_fh
    read_from_file
    prepare_all
);

sub mk_podfile {
    my $pod = shift;
    my ($podfh, $podfile) = tempfile(UNLINK => 1);

    print $podfh $pod;
    seek $podfh, 0, 0;
    close $podfh;

    return $podfile;
}

sub mk_outfile {
    return tempfile(UNLINK => 1);
}

sub mk_cache_dir {
    my $cachedir = tempdir(CLEANUP => 1);
    $ENV{POD_PERLDOC_CACHE_DIR} = $cachedir;
    return $cachedir;
}

sub get_cache_file_path {
    my ($cachedir, $podfile, $parser_class) = @_;
    return Pod::Perldoc::Cache::_cache_file(
        $cachedir, $podfile, $parser_class
    );
}

sub read_from_fh {
    my $fh = shift;
    seek $fh, 0, 0;
    return do {
        local $/;
        <$fh>;
    };
}

sub read_from_file {
    my $cachefile = shift;
    open my $fh, '<', $cachefile;
    return read_from_fh($fh);
}

sub prepare_all {
    my ($pod) = @_;
    my $cachedir = mk_cache_dir();
    my $podfile = mk_podfile($pod);
    my ($out_fh) = mk_outfile();
    my $cachefile = get_cache_file_path($cachedir, $podfile, 'Pod::Text');

    return ($podfile, $out_fh, $cachefile);
}

1;
