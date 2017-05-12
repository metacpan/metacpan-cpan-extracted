#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::File;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::File - Files and folders manager.

=head1 SYNOPSIS
    
    # get app context
    $app = $self->app;

    # get the file content as a single string.
    $content = $app->file->get($file);

    # get the file content as an array of lines.
    @lines = $app->file->get($file);
    
    # get list of specific files in a folder
    @files = $app->file->files("c:/apache/htdocs/nile/", "*.pm, *.cgi");
        
    # get list of specific files in a folder recursively
    # files_tree($dir, $match, $relative, $depth)
    @files = $app->file->files_tree("c:/apache/htdocs/nile/", "*.pm, *.cgi");

    # get list of sub folders in a folder
    #folders($dir, $match, $relative)
    @folders = $self->file->folders("c:/apache/htdocs/nile/", "", 1);
    
    # get list of sub folders in a folder recursively
    #folders_tree($dir, $match, $relative, $depth)
    @folders = $self->file->folders_tree("c:/apache/htdocs/nile/", "", 1);

=head1 DESCRIPTION

The file object provides tools for reading files, folders, and most of the functions in the modules L<File::Spec> and L<File::Basename>.

to get file content as single string or array of strings:
    
    $content = $app->file->get($file);
    @lines = $app->file->get($file);

supports options same as L<File::Slurp>.

To get list of files in a specific folder:
    
    #files($dir, $match, $relative)
    @files = $app->file->files("c:/apache/htdocs/nile/", "*.pm, *.cgi");
    
    #files_tree($dir, $match, $relative, $depth)
    @files = $app->file->files_tree("c:/apache/htdocs/nile/", "*.pm, *.cgi");

    #folders($dir, $match, $relative)
    @folders = $self->file->folders("c:/apache/htdocs/nile/", "", 1);

    #folders_tree($dir, $match, $relative, $depth)
    @folders = $self->file->folders_tree("c:/apache/htdocs/nile/", "", 1);

Nile::File - Files and folders manager.

=cut

use Nile::Base;
use File::Slurp;
use File::Find::Rule;
use File::Basename ();
use File::Temp ();
use IO::Compress::Gzip qw($GzipError);
use IO::Uncompress::Gunzip qw($GunzipError) ;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Data::Validate::URI qw(is_uri);

our ($OS, %DS, $DS);

BEGIN {  
    unless ($OS = $^O) { require Config; eval(q[$OS=$Config::Config{osname}]) }
    if ($OS =~ /^darwin/i) { $OS = 'UNIX';}
    elsif ($OS =~ /^cygwin/i) { $OS = 'CYGWIN';}
    elsif ($OS =~ /^MSWin/i)  { $OS = 'WINDOWS';}
    elsif ($OS =~ /^vms/i)    { $OS = 'VMS';}
    elsif ($OS =~ /^bsdos/i)  { $OS = 'UNIX';}
    elsif ($OS =~ /^dos/i)    { $OS = 'DOS';}
    elsif ($OS =~ /^MacOS/i)  { $OS = 'MACINTOSH';}
    elsif ($OS =~ /^epoc/)    { $OS = 'EPOC';}
    elsif ($OS =~ /^os2/i)    { $OS = 'OS2';}
    else { $OS = 'UNIX';}

    %DS = ('DOS' => '\\', 'EPOC' => '/', 'MACINTOSH' => ':',
            'OS2' => '\\', 'UNIX' => '/', 'WINDOWS'   => chr(92),
            'VMS' => '/',  'CYGWIN' => '/');
    $DS = $DS{$OS} || '/';
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get()
    
    # file($file, $options)
    $content = $app->file->get("/path/file.txt");
    @lines = $app->file->get("/path/file.txt");

    # read file from URL, file($url)
    $content = $app->file->get("http://www.domain.com/path/page.html");

    $bin = $app->file->get("/path/file.bin", binmode => ':raw');
    $utf = $app->file->get("/path/file.txt", binmode => ':utf8');

Reads file contents into a single variable or an array. It also supports reading files from URLs. If
the file name passed to the method is a valid URL, it will connect and return the URL content. 
This method is a wrapper around L<File::Slurp> read_file method when used for reading files.

=cut

sub get {

    #shift if ref ($_[0]) || $_[0] eq __PACKAGE__;
    my $self = shift;
    my $file = shift ;
    my $opts = (ref $_[0] eq 'HASH' ) ? shift : {@_};
    
    # if wantarray, default to chomp lines
    #if (defined wantarray && ! exists $opts->{chomp}) {
    #   $opts->{chomp} = 1;
    #}

    #my $bin_data = read_file( $bin_file, binmode => ':raw' );
    #my $utf_text = read_file( $bin_file, binmode => ':utf8' ); chomp=>1

    if (is_uri($file)) {
        return $self->app->ua->get($file)->{content};
    }

    return read_file($file, $opts);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 put()
    
    # put($file, $options)
    $app->file->put($file, @data);
    $app->file->put($file, {binmode => ':raw'}, $buffer);

    $app->file->put($file, \$buffer);
    # the same as
    $app->file->put($file, $buffer);

    $app->file->put($file, \@lines) ;
    # the same as
    $app->file->put($file, @lines) ;

Writes contents into a file. This method is a wrapper around L<File::Slurp> write_file method. 
The first argument is the filename. The second argument is an optional hash reference and it 
contains key/values that can modify the behavior of write_file. The rest of the argument list is the data to be written to the file.

=cut

sub put {
    my $self = shift;
    #shift if ref ($_[0]) || $_[0] eq __PACKAGE__;
    #write_file( $bin_file, {binmode => ':raw'}, @data );
    #write_file( $bin_file, {binmode => ':utf8', append => 1}, $utf_text );
    return write_file(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 File::Spec supported methods
    
    $app->file->canonpath;
    $app->file->catdir
    $app->file->catfile
    $app->file->curdir
    $app->file->rootdir
    $app->file->updir
    $app->file->no_upwards
    $app->file->file_name_is_absolute
    $app->file->path
    $app->file->devnull
    $app->file->tmpdir
    $app->file->splitpath
    $app->file->splitdir
    $app->file->catpath
    $app->file->abs2rel
    $app->file->rel2abs
    $app->file->case_tolerant

Wrapper methods around L<File::Spec> functions.

=cut

sub canonpath {shift; File::Spec->canonpath(@_);}
sub catdir {shift; File::Spec->catdir(@_);}
sub catfile {shift; File::Spec->catfile(@_);}
sub curdir {shift; File::Spec->curdir(@_);}
sub rootdir {shift; File::Spec->rootdir(@_);}
sub updir {shift; File::Spec->updir(@_);}
sub no_upwards {shift; File::Spec->no_upwards(@_);}
sub file_name_is_absolute {shift; File::Spec->file_name_is_absolute(@_);}
sub path {shift; File::Spec->path(@_);}
sub devnull {shift; File::Spec->devnull(@_);}
sub tmpdir {shift; File::Spec->tmpdir(@_);}
sub splitpath {shift; File::Spec->splitpath(@_);}
sub splitdir {shift; File::Spec->splitdir(@_);}
sub catpath {shift; File::Spec->catpath(@_);}
sub abs2rel {shift; File::Spec->abs2rel(@_);}
sub rel2abs {shift; File::Spec->rel2abs(@_);}
sub case_tolerant {shift; File::Spec->case_tolerant(@_);}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 files()
    
    # files($dir, $match, $relative)
    @files = $app->file->files("c:/apache/htdocs/nile/", "*.pm, *.cgi");

Returns a list of files in a specific folder. The first argument is the path, the second argument is the filename match
if not set will match all files, the third argument is the relative flag, if set will include the relative path of the files.

=cut

sub files {
    my ($self, $dir, $match, $relative) = @_;
    $relative += 0;
    #($dir, $match, $depth, $folders, $relative)
    return $self->scan_dir($dir, $match, 1, 0, $relative);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 files_tree()
    
    # files_tree($dir, $match, $relative, $depth)
    @files = $app->file->files_tree("c:/apache/htdocs/nile/", "*.pm, *.cgi");

Returns a list of files in a specific folder. The first argument is the path, the second argument is the filename match
if not set will match all files, the third argument is the relative flag, if set will include the relative path of the files.

=cut

sub files_tree {
    my ($self, $dir, $match, $relative, $depth) = @_;
    #($dir, $match, $depth, $folders, $relative)
    return $self->scan_dir($dir, $match, $depth, 0, $relative);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 folders()
    
    # get list of sub folders in a folder
    # folders($dir, $match, $relative)
    @folders = $self->file->folders("c:/apache/htdocs/nile/", "", 1);
    
    # get list of sub folders in a folder recursively
    #folders_tree($dir, $match, $relative, $depth)
    @folders = $self->file->$folders_tree("c:/apache/htdocs/nile/", "", 1);

Returns a list of sub folders in a folder.

=cut

sub folders {
    my ($self, $dir, $match, $relative) = @_;
    return $self->scan_dir($dir, $match, 1, 1, $relative);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 folders_tree()
    
    # get list of sub folders in a folder recursively
    #folders_tree($dir, $match, $relative, $depth)
    @folders = $self->file->folders_tree("c:/apache/htdocs/nile/", "", 1);

Returns list of sub folders in a folder recursively.

=cut

sub folders_tree {
    my ($self, $dir, $match, $relative, $depth) = @_;
    return $self->scan_dir($dir, $match, $depth, 1, $relative);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub scan_dir {
    my ($self, $dir, $match, $depth, $folders, $relative) = @_;
    my ($rule, @match);
    
    $dir ||= "";
    $match ||= "";
    $depth += 0;
    
    #$relative != $relative;
    #$relative = ($relative)? 0 : 1;
    
    #my @files = File::Find::Rule->file->name( "*.pm" )->maxdepth( $depth )->in( $dir );
    #my @subdirs = File::Find::Rule->directory->maxdepth( 1 )->relative->in( "." );

    $rule =  File::Find::Rule->new();

    if ($folders) {
            $rule->directory();
    }
    else {
        $rule->file();
    }

    if ($relative) {$rule->relative();}

    if ($match) {
        @match = split(/\s*\,\s*/, $match); # *.cgi, *.pm, *.ini, File::Find::Rule->name( '*.avi', '*.mov' ),
        $rule->name(@match);
    }
    
    # depth=0 for unlimited depth recurse
    if ($depth) {$rule->maxdepth($depth);}
    
    if (ref($dir) eq 'ARRAY' ) {
        @$dir = map {$self->catdir($_)} @$dir;
        return ($rule->in(@$dir));
    }
    else {
        return ($rule->in($self->catdir($dir)));
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 os()
    
    my $os = $app->file->os;

Returns the name of the operating system.

=cut

sub os {$OS}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 ds()
    
    my $ds = $app->file->ds;

Returns the directory separator of the operating system.

=cut

sub ds {$DS}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 fileparse()
    
    my ($filename, $dirs, $suffix) = $app->file->fileparse($path);
    my ($filename, $dirs, $suffix) = $app->file->fileparse($path, @suffixes);
    my $filename = $app->file->fileparse($path, @suffixes);

Splits a file path into its $dirs, $filename and (optionally) the filename $suffix. See L<File::Basename>

=cut

sub fileparse {
    my ($self) = shift;
    return File::Basename::fileparse(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 basename()
    
    my $filename  = $app->file->basename($path);
    my $filename  = $app->file->basename($path, @suffixes);

Returns the last level of a filepath even if the last level is clearly directory. In effect, it is acting like pop() for paths. See L<File::Basename>

=cut

sub basename {
    my ($self) = shift;
    return File::Basename::basename(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 dirname()
    
    my $ds = $app->file->dirname();

Returns the directory separator of the operating system. See L<File::Basename>

=cut

sub dirname {
    my ($self) = shift;
    return File::Basename::dirname(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 path_info()
    
    my ($name, $dir, $ext, $name_ext) = $app->file->path_info($path);

Splits a file path into its $dir, $name, filename $suffix, and name with suffix.

=cut

sub path_info {
    my ($self, $path) = @_;
    my ($name, $dir, $ext) = File::Basename::fileparse($path,  qr/\.[^.]*/); # qr/\.[^.]*/ matched against the end of the $filename.
    return ($name, $dir, $ext, $name.$ext);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 open()
    
    $fh = $app->file->open($file);
    $fh = $app->file->open($mode, $file);
    $fh = $app->file->open($mode, $file, $charset);
    $fh = $app->file->open(">", $file, "utf8");

Open file and returns a filehandle.

=cut

sub open {
    
    my $self = shift;
    my ($mode, $filename, $charset);

    if (@_ == 1) {
        ($filename) = @_;
        $charset = "";
    }
    elsif (@_ == 2) {
        ($mode, $filename) = @_;
        $charset = "";
    }
    elsif (@_ == 3) {
        ($mode, $filename, $charset) = @_;
    }
    
    $mode ||= "<";
    CORE::open(my $fh, $mode, $filename) or $self->app->abort("Error opening file $filename in mode $mode. $!");
    binmode $fh, ":encoding($charset)" if ($charset);
    return $fh;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 tempfile()
    
    #$template = "tmpdirXXXXXX";
    ($fh, $filename) = $app->file->tempfile($template);
    ($fh, $filename) = $app->file->tempfile($template, DIR => $dir);
    ($fh, $filename) = $app->file->tempfile($template, SUFFIX => '.dat');
    ($fh, $filename) = $app->file->tempfile($template, TMPDIR => 1 );

Return name and handle of a temporary file safely. This is a wrapper for the L<File::Temp> tempfile function.

=cut

sub tempfile {
    my $self = shift;
    #(TEMPLATE => 'tempXXXXX', DIR => 'mydir', SUFFIX => '.dat', TMPDIR => 1)
    my ($fh, $filename) = File::Temp::tempfile(@_);
    #binmode $fh, ":encoding($charset)";
    binmode($fh, ":utf8");
    return ($fh, $filename);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 tempdir()
    
    $tmpdir = $app->file->tempdir($template);
    $tmpdir = $app->file->tempdir($template, DIR => $dir);
    $tmpdir = $app->file->tempdir($template, TMPDIR => 1 );

Return name of a temporary directory safely. This is a wrapper for the L<File::Temp> tempdir function.

=cut

sub tempdir {
    my $self = shift;
    #(TEMPLATE => 'tempXXXXX', DIR => 'mydir', CLEANUP => 1, TMPDIR => 1)
    if (@_ == 1) {
        return File::Temp::tempdir(shift, TMPDIR => 1, CLEANUP => 1);
    }
    else {
        return File::Temp::tempdir(@_);
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 gzip()
    
    $file = "file.txt";
    $app->file->gzip($file);
    # creates file.txt.gz
    
    $input = "file.txt";
    $output = "file.gz";
    $app->file->gzip($input, $output);
    # creates file.gz
    
    # rename file in gzip header to file1.txt
    $app->file->gzip($input, $output, "file1.txt");

Compress and create gzip files from input files.

=cut

sub gzip {
    my ($self, $input, $output, $outname) = @_;
    $output ||= "$input.gz";
    my ($name, $dir, $ext, $filename) = $self->path_info($input);
    $outname ||= $filename;
    IO::Compress::Gzip::gzip $input => $output, Name => $outname or $self->app->abort("Gzip failed for $input => $output: $GzipError");
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 gunzip()
    
    $file = "file.txt";
    $app->file->gzip($file);
    # creates file.txt.gz
    
    $input = "file.txt";
    $output = "file.gz";
    $app->file->gzip($input, $output);
    # creates file.gz
    
    # rename file in gzip header to file1.txt
    $app->file->gzip($input, $output, "file1.txt");

Extract gzip files.

=cut

sub gunzip {
    my ($self, $input, $output) = @_;
    $output ||= $input;
    $output =~ s/\.gz//i ;
    IO::Uncompress::Gunzip::gunzip $input => $output or $self->app->abort("Gunzip failed for $input => $output: $GunzipError");
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 zip()
    
    $file = "file.txt";
    $app->file->zip($file);
    # creates file.zip
    
    $input = "file.txt";
    $output = "file1.zip";
    $app->file->gzip($input, $output);
    # creates file1.zip
    
    # rename file in zip header to file1.txt
    $app->file->zip($input, $output, "file1.txt");

Compress and create zip files from input files.

=cut

sub zip {
    my ($self, $input, $output, $outname) = @_;
    unless ($output) {
        $output = $input;
        $output =~ s/\.[^.]*$//;
        $output .= ".zip";
    }
    my ($name, $dir, $ext, $filename) = $self->path_info($input);
    $outname ||= $filename;
    my $zip = Archive::Zip->new();
    my $file_member = $zip->addFile($input, $outname);
    unless ($zip->writeToFileNamed($output) == AZ_OK) {
       $self->app->abort("Zip failed for $input => $output $!");
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 unzip()
    
    $file = "/path/file.zip";
    $app->file->unzip($file);
    # extracts files to /path/
    
    $app->file->unzip($file, $dest);
    # extracts files to $dest
    
Extract zip files.

=cut

sub unzip {
    my ($self, $input, $dest) = @_;
    
    my $zip = Archive::Zip->new();

    unless ($zip->read($input) == AZ_OK) {
       $self->app->abort("Unzip failed for $input $!");
    }
  	
    unless ($dest) {
        my ($name, $dir, $ext, $filename) = $self->path_info($input);
	    $dest = $dir; # =~ s/[^\\\/]+$//;
    }

	#$zip->extractTree($root, $dest, $volume);
	$zip->extractTree("", $dest, "");
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 view()
    
    my $file = $app->file->view($view, $theme);

    # get view file name in the current theme
    my $file = $app->file->view("home");
    # /app/theme/default/view/home.html

    my $file = $app->file->view("home", "Arabic");
    # /app/theme/Arabic/view/home.html

Returns the full file path for a view name.

=cut

sub view {
    my ($self, $view, $theme) = @_;
    $view .= ".html" unless ($view =~ /\.html$/i);
    $theme ||= $self->app->var->get("theme");
    $self->app->file->catfile($self->app->var->get("themes_dir"), $theme, "view", $view);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lang()
    
    my $file = $app->file->lang($filename, $lang);

    # get language file pth in the current language
    my $file = $app->file->lang("general");
    # /app/lang/en-US/general.xml

    my $file = $app->file->lang("general", "ar");
    # /app/lang/ar/general.xml

Returns the full file path for a language file name.

=cut

sub lang {
    my ($self, $file, $lang) = @_;
    $lang ||= $self->app->var->get("lang");
    $file .= ".xml" unless ($file =~ /\.xml$/i);
    $self->app->file->catfile($self->app->var->get("langs_dir"), $lang, $file);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
