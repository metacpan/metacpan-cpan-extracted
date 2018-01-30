package Test::CheckManifest;

# ABSTRACT: Check if your Manifest matches your distro

use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec;
use File::Basename;
use Test::Builder;
use File::Find;

our $VERSION = '1.33';
our $VERBOSE = 1;

my $test      = Test::Builder->new();
my $test_bool = 1;
my $plan      = 0;
my $counter   = 0;

sub import {
    my $self   = shift;
    my $caller = caller;
    my %plan   = @_;

    for my $func ( qw( ok_manifest ) ) {
        no strict 'refs';
        *{$caller."::".$func} = \&$func;
    }

    $test->exported_to($caller);
    $test->plan(%plan);
    
    $plan = 1 if(exists $plan{tests});
}

sub ok_manifest{
    my ($hashref,$msg) = @_;
    
    $test->plan(tests => 1) unless $plan;
    
    my $is_hashref = 1;
    $is_hashref = 0 unless ref($hashref);
    
    unless ( $is_hashref ) {
        $msg = $hashref;
        $hashref = {};
    }

    my $tmp_path = dirname( File::Spec->rel2abs( $0 ) );

    if ( $hashref->{file} ) {
        $tmp_path = dirname $hashref->{file};
    }
    elsif ( $hashref->{dir} ) {
        $tmp_path = $hashref->{dir};
    }
    
    my $bool = 1;
    my $home = Cwd::realpath( $tmp_path );
    my $manifest;

    my $counter = 0;
    while ( 1 ) {
        my $manifest_path = File::Spec->catfile( $home . '/MANIFEST' );
        last if -f $manifest_path;

        my $tmp_home = Cwd::realpath( File::Spec->catdir( $home, '..' ) );

        last if !$tmp_home || $tmp_home eq $home || $counter++ == 20;
        $home = $tmp_home;
    }

    eval { $manifest = Cwd::realpath( $home . '/MANIFEST' ); 1; };
    if ( !$manifest ) {
        $test->BAILOUT( 'Cannot find a MANIFEST. Please check!' );
    }
    
    my $skip;
    my $skip_path = File::Spec->catfile( $home, 'MANIFEST.SKIP' );
    eval { $skip = Cwd::realpath( $skip_path ) if -f $skip_path; 1; };

    my @dup_files     = ();
    my @missing_files = ();
    my @files_plus    = ();
    my $arref         = ['/blib' , '/_build'];
    my $filter        = $is_hashref && 
                        $hashref->{filter} ? $hashref->{filter}  : [];
    my $comb          = $is_hashref && 
                        $hashref->{bool} && 
                        $hashref->{bool} =~ m/^and$/i ?
                               'and' :
                               'or'; 
                   
    push @$arref, @{$hashref->{exclude}} 
        if $is_hashref and exists $hashref->{exclude} and 
            ref($hashref->{exclude}) eq 'ARRAY';
    
    for(@$arref){
        croak 'path in excluded array must be "absolute"' unless m!^/!;
        my $path = $home . $_;
        next unless -e $path;
        $_ = Cwd::realpath($path);
    }
    
    @$arref = grep { defined }@$arref;
    
    unless( open my $fh, '<', $manifest ){
        $bool = 0;
        $msg  = "can't open $manifest";
    }
    else{
        { # extra block to use "last"
        
        my $files_in_skip = _read_skip( $skip, \$msg, \$bool );
        last unless $files_in_skip;

        my @files = _read_file( $fh );
        close $fh;
    
        chomp @files;
    
        {
            local $/ = "\r";
            chomp @files;
        }
    
        for my $tfile(@files){
            $tfile = (split(/\s{2,}/,$tfile,2))[0];
            next unless -e $home . '/' . $tfile;
            $tfile = File::Spec->rel2abs($home . '/' . $tfile);
        }
    
        my (@dir_files,%files_hash,%excluded);
        @files_hash{@files} = ();
    
        find({
            no_chdir => 1,
            follow   => 0,
            wanted   => sub {
                my $file         = $File::Find::name;
                my $is_excluded  = _is_excluded(
                    $file,
                    $arref,
                    $filter,
                    $comb,
                    $files_in_skip,
                    $home,
                );
                
                push(@dir_files,File::Spec->rel2abs($file)) if -f $file and !$is_excluded;
                
                $excluded{$file} = 1 if -f $file and $is_excluded
            }
        },$home);

        #use Data::Dumper;
        #print STDERR ">>",++$counter,":",Dumper(\@files,\@dir_files);
        SFILE:
        for my $file(@dir_files){
            for my $check(@files){
                if($file eq $check){
                    delete $files_hash{$check};
                    next SFILE;
                }
            }
            push(@missing_files,$file);
            $bool = 0;
        }
    
        delete $files_hash{$_} for keys %excluded;
        @files_plus = sort keys %files_hash;
        $bool = 0 if scalar @files_plus > 0;

        my %seen_files = ();
        @dup_files = map { 1==$seen_files{$_}++ ? $_ : () } @files;
        $bool = 0 if scalar @dup_files > 0;
        
        } # close extra block
    }
    
    my $diag = 'The following files are not named in the MANIFEST file: '.
               join(', ',@missing_files);
    my $plus = 'The following files are not part of distro but named in the MANIFEST file: '.
               join(', ',@files_plus);
    my $dup  = 'The following files appeared more than once in the MANIFEST file: '.
               join(', ',@dup_files);
    
    $test->is_num($bool,$test_bool,$msg);
    $test->diag($diag) if scalar @missing_files >= 1 and $test_bool == 1 and $VERBOSE;
    $test->diag($plus) if scalar @files_plus    >= 1 and $test_bool == 1 and $VERBOSE;
    $test->diag($dup)  if scalar @dup_files     >= 1 and $test_bool == 1 and $VERBOSE;
}

sub _read_file {
    my ($fh) = @_;
    
    my @files;
    my $selftest = 0;

    while( my $fh_line = <$fh> ){
        chomp $fh_line;
        
        $selftest++ if $fh_line =~ m{# MANIFEST for Test-CheckManifest};

        next if $fh_line =~ m{ \A \s* \# }x;
        next if $selftest && $fh_line =~ m{# selftest};
        
        my ($file);
        
        if ( ($file) = $fh_line =~ /^'(\\[\\']|.+)+'\s*(.*)/) {
            $file =~ s/\\([\\'])/$1/g;
        }
        else {
            ($file) = $fh_line =~ /^(\S+)\s*(.*)/;
        }

        next unless $file;

        push @files, $file;
    }
    
    return @files;
}

sub _not_ok_manifest{
    $test_bool = 0;
    ok_manifest(@_);
    $test_bool = 1;
}

sub _is_excluded{
    my ($file,$dirref,$filter,$bool,$files_in_skip,$home) = @_;
    my @excluded_files = qw(
        pm_to_blib Makefile META.yml Build pod2htmd.tmp 
        pod2htmi.tmp Build.bat .cvsignore MYMETA.json MYMETA.yml
    );

    if ( $files_in_skip and 'ARRAY' eq ref $files_in_skip ) {
        (my $local_file = $file) =~ s{\Q$home\E/?}{};
        for my $rx ( @{$files_in_skip} ) {
            my $regex = qr/$rx/;
            return 1 if $local_file =~ $regex;
        }
    }
        
    my @matches = grep{ $file =~ /$_$/ }@excluded_files;
    
    if($bool eq 'or'){
        push @matches, $file if grep{ref($_) and ref($_) eq 'Regexp' and $file =~ /$_/}@$filter;
        push @matches, $file if grep{$file =~ /^\Q$_\E/}@$dirref;
    }
    else{
        if(grep{$file =~ /$_/ and ref($_) and ref($_) eq 'Regexp'}@$filter and
           grep{$file =~ /^\Q$_\E/ and not ref($_)}@$dirref){
            push @matches, $file;
        }
    }
    
    return scalar @matches;
}

sub _read_skip {
    my ($skip, $msg, $bool) = @_;

    return [] unless $skip and -e $skip;
    
    my @files;
    if( -e $skip and not open my $skip_fh, '<', $skip ) {
        $$bool = 0;
        $$msg  = "can't open $skip";
        return;
    }
    else {
        @files = _read_file( $skip_fh );
    }

    return \@files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::CheckManifest - Check if your Manifest matches your distro

=head1 VERSION

version 1.33

=head1 SYNOPSIS

  use Test::CheckManifest;
  ok_manifest();

=head2 EXPORT

There is only one method exported: C<ok_manifest>

=head1 METHODS

=head2 ok_manifest   [{exclude => $arref}][$msg]

checks whether the Manifest file matches the distro or not. To match a distro
the Manifest has to name all files that come along with the distribution.

To check the Manifest file, this module searches for a file named C<MANIFEST>.

To exclude some directories from this test, you can specify these dirs in the
hashref.

  ok_manifest({exclude => ['/var/test/']});

is ok if the files in C</path/to/your/dist/var/test/> are not named in the
C<MANIFEST> file. That means that the paths in the exclude array must be
"pseudo-absolute" (absolute to your distribution).

To use a "filter" you can use the key "filter"

  ok_manifest({filter => [qr/\.svn/]});

With that you can exclude all files with an '.svn' in the filename or in the
path from the test.

These files would be excluded (as examples):

=over 4

=item * /dist/var/.svn/test

=item * /dist/lib/test.svn

=back

You can also combine "filter" and "exclude" with 'and' or 'or' default is 'or':

  ok_manifest({exclude => ['/var/test'], 
               filter  => [qr/\.svn/], 
               bool    => 'and'});

These files have to be named in the C<MANIFEST>:

=over 4

=item * /var/foo/.svn/any.file

=item * /dist/t/file.svn

=item * /var/test/test.txt

=back

These files not:

=over 4

=item * /var/test/.svn/*

=item * /var/test/file.svn

=back

By default, C<ok_manifest> will look for the file C<MANIFEST> in the current working directory (which is how tests are traditionally run). If you wish to specify a different directory, you may pass the C<file> or C<dir> parameters, for example:

  ok_manifest({dir => '/path/to/my/dist/'});

=head1 EXCLUDING FILES

Beside C<filter> and C<exclude> there is another way to exclude files:
C<MANIFEST.SKIP>. This is a file with filenames that should be excluded:

  t/my_very_own.t
  file_to.skip

=head1 ACKNOWLEDGEMENT

Great thanks to Christopher H. Laco, who did a lot of testing stuff for me and
he reported some bugs to RT.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
