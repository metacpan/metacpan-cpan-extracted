package Pod::Multi::Auxiliary;
#$Id#
require 5.006001;
use strict;
use warnings;
use Exporter ();
our ($VERSION, @ISA, @EXPORT_OK);
$VERSION     = 0.09;
@ISA         = qw( Exporter );
@EXPORT_OK   = qw(
    stringify
    _save_pretesting_status
    _restore_pretesting_status
    _process_personal_defaults_file 
    _reprocess_personal_defaults_file 
    _subclass_preparatory_tests
    _subclass_cleanup_tests
); 
use Carp;
use Cwd;
use File::Save::Home qw|
        get_home_directory
        get_subhome_directory_status
        make_subhome_directory
        restore_subhome_directory_status
|;
use File::Copy;
use File::Path;
use File::Spec;
use File::Temp qw| tempdir |;
*ok = *Test::More::ok;
*is = *Test::More::is;
*copy = *File::Copy::copy;
*move = *File::Copy::move;


sub stringify {
    my $output = shift;
    local $/;
    open my $FH, $output or croak "Unable to open $output";
    my $str = <$FH>;
    close $FH or croak "Unable to close $output";
    return $str;
}

sub _save_pretesting_status {
    my $mmkr_dir_ref = get_subhome_directory_status(".pod2multi");
    my $mmkr_dir = make_subhome_directory($mmkr_dir_ref);
    ok( $mmkr_dir, "personal defaults directory now present on system");
    my $pers_file = "Pod/Multi/Personal/Defaults.pm";
    my $pers_def_ref = _process_personal_defaults_file(
        $mmkr_dir, 
        $pers_file,
    );
    return {
        cwd             => cwd(),
        mmkr_dir_ref    => $mmkr_dir_ref,
        pers_def_ref    => $pers_def_ref,
        mmkr_dir        => $mmkr_dir,   # needed in make_selections_defaults
        pers_file       => $pers_file,  # needed in make_selections_defaults
    }
}

sub _restore_pretesting_status {
    my $statusref = shift;
    _reprocess_personal_defaults_file($statusref->{pers_def_ref});
    ok(chdir $statusref->{cwd},
        "changed back to original directory after testing");
    ok( restore_subhome_directory_status($statusref->{mmkr_dir_ref}),
        "original presence/absence of .pod2multi directory restored");
}

sub _process_personal_defaults_file {
    my ($mmkr_dir, $pers_file) = @_;
    my $pers_file_hidden = $pers_file . '.hidden';
    my %pers;
    $pers{full} = File::Spec->catfile( $mmkr_dir, $pers_file );
    $pers{hidden} = File::Spec->catfile( $mmkr_dir, $pers_file_hidden );
    if (-f $pers{full}) {
        $pers{atime}   = (stat($pers{full}))[8];
        $pers{modtime} = (stat($pers{full}))[9];
        rename $pers{full},
               $pers{hidden}
            or croak "Unable to rename $pers{full}: $!";
        ok(! -f $pers{full}, 
            "personal defaults file temporarily suppressed");
        ok(-f $pers{hidden}, 
            "personal defaults file now hidden");
    } else {
        ok(! -f $pers{full}, 
            "personal defaults file not found");
        ok(1, "personal defaults file not found");
    }
    return { %pers };
}

sub _reprocess_personal_defaults_file {
    my $pers_def_ref = shift;;
    if(-f $pers_def_ref->{hidden} ) {
        rename $pers_def_ref->{hidden},
               $pers_def_ref->{full},
            or croak "Unable to rename $pers_def_ref->{hidden}: $!";
        ok(-f $pers_def_ref->{full}, 
            "personal defaults file re-established");
        ok(! -f $pers_def_ref->{hidden}, 
            "hidden personal defaults now gone");
        ok( (utime $pers_def_ref->{atime}, 
                   $pers_def_ref->{modtime}, 
                  ($pers_def_ref->{full})
            ), "atime and modtime of personal defaults file restored");
    } else {
        ok(1, "test not relevant");
        ok(1, "test not relevant");
        ok(1, "test not relevant");
    }
}

##### #####

sub _get_els {
    my $persref = shift;
    my %pers = %$persref;
    my %pm = %{$pers{pm}};
    my %hidden = %{$pers{hidden}};
    return ( pm => scalar(keys %pm), hidden => scalar(keys %hidden) );
}

sub _subclass_preparatory_tests {
    my $odir = shift;
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    my $mmkr_dir_ref = get_subhome_directory_status(".pod2multi");
    my $mmkr_dir = make_subhome_directory($mmkr_dir_ref);
    ok($mmkr_dir, "home/.pod2multi directory now present on system");
    my $eumm = File::Spec->catfile( qw| Pod Multi | );
    my $eumm_dir = File::Spec->catfile( $mmkr_dir, $eumm );
    unless (-d $eumm_dir) {
            mkpath($eumm_dir) or croak "Unable to make path: $!";
    }
    ok(-d $eumm_dir, "eumm directory now exists");

    my $pers_file = "Pod/Multi/Personal/Defaults.pm";
    my $pers_def_ref = 
        _process_personal_defaults_file( $mmkr_dir, $pers_file );

    my $persref;

    $persref = _identify_pm_files_under_mmkr_dir($eumm_dir);
    my %els1 = _get_els($persref);

    _hide_pm_files_under_mmkr_dir($persref);

    $persref = _identify_pm_files_under_mmkr_dir($eumm_dir);
    my %els2 = _get_els($persref);

    if (! $els1{pm}) {
        is($els1{pm}, $els2{pm}, 
            "no .pm files originally, so no .pm files now");
        is($els1{pm}, $els2{hidden}, 
            "no .pm files originally, so no .pm.hidden files now");
    } elsif ($els1{pm}) {
        is($els2{pm}, 0,
            "original .pm files are now hidden");
        is($els1{pm}, $els2{hidden},
            ".pm.hidden files exist");
    }

    my $sourcedir = File::Spec->catdir( $odir, q{t}, q{lib}, $eumm );
    ok( -d $sourcedir, "source directory exists");
    ok( -d $eumm_dir, "destination directory exists");
    return {
        mmkr_dir_ref     => $mmkr_dir_ref,
        persref          => $persref,
        pers_def_ref     => $pers_def_ref,
        initial_els_ref  => \%els1,
        sourcedir        => $sourcedir,
        eumm_dir         => $eumm_dir,
    }
}

sub _subclass_cleanup_tests {
    my $cleanup_ref = shift;
    my $persref         = $cleanup_ref->{persref};
    my $pers_def_ref    = $cleanup_ref->{pers_def_ref};
    my $eumm_dir        = $cleanup_ref->{eumm_dir};
    my %els1            = %{ $cleanup_ref->{initial_els_ref} };
    my $odir            = $cleanup_ref->{odir}; 
    my $mmkr_dir_ref    = $cleanup_ref->{mmkr_dir_ref};

    _reveal_pm_files_under_mmkr_dir($persref);

    $persref = _identify_pm_files_under_mmkr_dir($eumm_dir);
    my %els3 = _get_els($persref);

    if (! $els1{pm}) {
        is($els1{pm}, $els3{pm}, 
            "no .pm files originally, so no .pm files now");
        is($els1{pm}, $els3{hidden}, 
            "no .pm files originally, so no .pm.hidden files now");
    } elsif ($els1{pm}) {
        is($els1{pm}, $els3{pm},
            "same number of .pm files as originally");
        is($els3{hidden}, 0,
            "no more .pm.hidden files");
    }

    _reprocess_personal_defaults_file($pers_def_ref);

    ok(chdir $odir, 'changed back to original directory after testing');

    ok( restore_subhome_directory_status($mmkr_dir_ref),
        "original presence/absence of .pod2multi directory restored");
}

sub _identify_pm_files_under_mmkr_dir {
    my $eumm_dir = shift;
    my (@pm_files, @pm_files_hidden);
    opendir my $dirh, $eumm_dir 
        or croak "Unable to open $eumm_dir for reading: $!";
    while (my $f = readdir($dirh)) {
        if ($f =~ /\.pm$/) {
            push @pm_files, File::Spec->catfile( $eumm_dir, $f );
        } elsif ($f =~ /\.pm\.hidden$/) {
            push @pm_files_hidden, File::Spec->catfile( $eumm_dir, $f );
        } else {
            next;
        }
    }
    closedir $dirh or croak "Unable to close $eumm_dir after reading: $!";
    # sanity check:
    # If there are .pm files, there should be no .pm.hidden files
    # and vice versa.
    if ( scalar(@pm_files) and scalar(@pm_files_hidden) )  {
        croak "Both .pm and .pm.hidden files found in $eumm_dir: $!";
    }
    my %pers;
    my %pm;
    foreach my $f (@pm_files) {
        $pm{$f}{atime}   = (stat($f))[8];
        $pm{$f}{modtime} = (stat($f))[9];
    }
    my %hidden;
    foreach my $f (@pm_files_hidden) {
        $hidden{$f}{atime}   = (stat($f))[8];
        $hidden{$f}{modtime} = (stat($f))[9];
    }
    $pers{dir}    = $eumm_dir;;
    $pers{pm}     = \%pm;
    $pers{hidden} = \%hidden;
    return \%pers;
}

sub _hide_pm_files_under_mmkr_dir {
    my $per_dir_ref = shift;
    my %pers = %{$per_dir_ref};
    my %pm = %{$pers{pm}};
    foreach my $f (keys %pm) {
        my $new = "$f.hidden";
        rename $f, $new or croak "Unable to rename $f: $!";
        utime $pm{$f}{atime}, $pm{$f}{modtime}, $new;
    }
}

sub _reveal_pm_files_under_mmkr_dir {
    my $per_dir_ref = shift;
    my %pers = %{$per_dir_ref};
    my %hidden = %{$pers{hidden}};
    foreach my $f (keys %hidden) {
        $f =~ m{(.*)\.hidden$};
        my $new = $1;
        rename $f, $new or croak "Unable to rename $f: $!";
        utime $hidden{$f}{atime}, $hidden{$f}{modtime}, $new;
    }
}

1;
