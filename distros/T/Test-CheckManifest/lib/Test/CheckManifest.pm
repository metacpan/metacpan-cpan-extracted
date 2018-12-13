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
use Scalar::Util qw(blessed);

our $VERSION = '1.38';
our $VERBOSE = 1;
our $HOME;

my $test      = Test::Builder->new();
my $test_bool = 1;
my $plan      = 0;
my $counter   = 0;

my @excluded_files = qw(
    pm_to_blib Makefile META.yml Build pod2htmd.tmp META.json
    pod2htmi.tmp Build.bat .cvsignore MYMETA.json MYMETA.yml
);

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

sub _validate_args {
    my ($hashref, $msg) = @_;

    my $ref = ref $hashref;
    if ( !$ref || 'HASH' ne $ref ) {
        $msg     = $hashref if !$ref;
        $hashref = {};
    }

    my $ref_filter     = ref $hashref->{filter};
    $hashref->{filter} = [] if !$ref_filter || 'ARRAY' ne $ref_filter;
    $hashref->{filter} = [ grep{ blessed $_ && $_->isa('Regexp') } @{ $hashref->{filter} } ];

    my $ref_exclude     = ref $hashref->{exclude};
    $hashref->{exclude} = [] if !$ref_exclude || 'ARRAY' ne $ref_exclude;
    push @{$hashref->{exclude}}, qw!/blib /_blib! if $test_bool;

    for my $excluded_path ( @{ $hashref->{exclude} } ) {
        croak 'path in excluded array must be "absolute"' if $excluded_path !~  m!^/!;
    }

    my $bool = lc( $hashref->{bool} || '' );
    $hashref->{bool} = $bool && $bool eq 'and' ? 'and' : 'or';
    
    return $hashref, $msg;
}

sub _check_excludes {
    my ($hashref, $home) = @_;

    my @excluded;

    for my $excluded_path ( @{ $hashref->{exclude} } ) {
        my $path = Cwd::realpath( $home . $excluded_path );
        next if !$path || !-e $path;

        push @excluded, $path;
    }
    
    return \@excluded;
}

sub _find_home {
    my ($params) = @_;

    my $tmp_path = dirname( File::Spec->rel2abs( $0 ) );

    if ( $params->{file} ) {
        $tmp_path = dirname $params->{file};
    }
    elsif ( $params->{dir} ) {
        $tmp_path = $params->{dir};
    }

    my $home    = Cwd::realpath( $tmp_path );
    my $counter = 0;
    while ( 1 ) {
        last if -f File::Spec->catfile( $home, 'MANIFEST' );

        my $tmp_home = Cwd::realpath( File::Spec->catdir( $home, '..' ) );

        last if !$tmp_home || $tmp_home eq $home || $counter++ == 20;
        $home = $tmp_home;
    }

    return $HOME if $HOME;
    return $home;
}

sub ok_manifest {
    my ($hashref,$msg) = _validate_args( @_ );
    
    $test->plan(tests => 1) if !$plan;
    
    my $bool     = 1;
    my $home     = _find_home( $hashref );
    my $manifest = File::Spec->catfile( $home, 'MANIFEST' );

    if ( !-f $manifest ) {
        $test->BAILOUT( 'Cannot find a MANIFEST. Please check!' );
    }
    elsif( !-r $manifest ) {
        $test->is_num( 0, $test_bool, "can't open $manifest" );
        return;
    }
    
    my $skip_path  = File::Spec->catfile( $home, 'MANIFEST.SKIP' );
    my @skip_files = _read_file( $skip_path );

    my @dup_files     = ();
    my @missing_files = ();
    my @files_plus    = ();
    my $excluded      = _check_excludes( $hashref, $home );

    my @files = _read_file( $manifest );

    for my $tfile ( @files ) {
        $tfile = ( split /\s{2,}/, $tfile, 2 )[0];

        next if !-e $home . '/' . $tfile;

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
                $excluded,
                $hashref->{filter},
                $hashref->{bool},
                \@skip_files,
                $home,
            );
            
            push @dir_files, File::Spec->rel2abs($file) if -f $file and !$is_excluded;
            
            $excluded{$file} = 1 if -f $file and $is_excluded
        }
    },$home);

    #use Data::Dumper;
    #print STDERR ">>",++$counter,":",Dumper(\@files,\@dir_files);
    SFILE:
    for my $file ( @dir_files ) {
        for my $check ( @files ) {
            if ( $file eq $check ) {
                delete $files_hash{$check};
                next SFILE;
            }
        }

        push @missing_files, $file;
        $bool = 0;
    }

    delete @files_hash{ keys %excluded };
    @files_plus = sort keys %files_hash;
    $bool = 0 if scalar @files_plus > 0;

    my %seen_files = ();
    @dup_files = map { $seen_files{$_}++ ? $_ : () } @files;
    $bool = 0 if scalar @dup_files > 0;
    
    my $diag = 'The following files are not named in the MANIFEST file: '.
               join(', ',@missing_files);
    my $plus = 'The following files are not part of distro but named in the MANIFEST file: '.
               join(', ',@files_plus);
    my $dup  = 'The following files appeared more than once in the MANIFEST file: '.
               join(', ',@dup_files);
    
    my $success = $test->is_num($bool,$test_bool,$msg);

    $test->diag( "MANIFEST: $manifest" ) if !$success;
    $test->diag($diag) if scalar @missing_files >= 1 and $test_bool == 1 and $VERBOSE;
    $test->diag($plus) if scalar @files_plus    >= 1 and $test_bool == 1 and $VERBOSE;
    $test->diag($dup)  if scalar @dup_files     >= 1 and $test_bool == 1 and $VERBOSE;

    return $success;
}

sub _read_file {
    my ($path) = @_;

    return if !-r $path;
    
    my @files;

    open my $fh, '<', $path;
    while( my $fh_line = <$fh> ){
        chomp $fh_line;
        
        next if $fh_line =~ m{ \A \s* \# }x;
        
        my ($file);
        
        if ( ($file) = $fh_line =~ /^'(\\[\\']|.+)+'\s*/) {
            $file =~ s/\\([\\'])/$1/g;
        }
        else {
            ($file) = $fh_line =~ /^(\S+)\s*/;
        }

        next unless $file;

        push @files, $file;
    }

    close $fh;
    
    chomp @files;

    {
        local $/ = "\r";
        chomp @files;
    }

    return @files;
}

sub _not_ok_manifest {
    $test_bool = 0;
    ok_manifest(@_);
    $test_bool = 1;
}

sub _is_excluded{
    my ($file,$dirref,$filter,$bool,$files_in_skip,$home) = @_;

    if ( $files_in_skip and 'ARRAY' eq ref $files_in_skip ) {
        (my $local_file = $file) =~ s{\Q$home\E/?}{};
        for my $rx ( @{$files_in_skip} ) {
            my $regex = qr/$rx/;
            return 1 if $local_file =~ $regex;
        }
    }
        
    my @matches = grep{ $file =~ /$_$/ }@excluded_files;

    return 1 if @matches;

    my $is_in_dir = _is_in_dir( $file, $dirref );
    
    $bool ||= 'or';
    if ( $bool eq 'or' ) {
        push @matches, $file if grep{ $file =~ /$_/ }@$filter;
        push @matches, $file if $is_in_dir;
    }
    else{
        if( grep{ $file =~ /$_/ }@$filter and $is_in_dir ) {
            push @matches, $file;
        }
    }
    
    return scalar @matches;
}

sub _is_in_dir {
    my ($file, $excludes) = @_;

    my (undef, $path) = File::Spec->splitpath( $file );
    my @file_parts    = File::Spec->splitdir( $path );
    my $is_in_dir;

    EXCLUDE:
    for my $exclude ( @{ $excludes || [] } ) {
        my (undef, $exclude_dir, $efile) = File::Spec->splitpath( $exclude );
        my @exclude_parts        = File::Spec->splitdir( $exclude_dir . $efile );

        pop @exclude_parts if $exclude_parts[-1] eq '';

        next EXCLUDE if @exclude_parts > @file_parts;

        my @subparts = @file_parts[ 0 .. $#exclude_parts ];

        my $exclude_join = join '/', @exclude_parts;
        my $sub_join     = join '/', @subparts;

        next EXCLUDE if $exclude_join ne $sub_join;

        $is_in_dir = 1;
        last EXCLUDE;
    }

    return $is_in_dir;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::CheckManifest - Check if your Manifest matches your distro

=head1 VERSION

version 1.38

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
