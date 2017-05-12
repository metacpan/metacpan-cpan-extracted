package Module::Husbandry;

$VERSION = 0.002;

use Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw(
    cppm
    install_file
    mvpm
    newpm
    newpmbin
    newpmdist
    parse_cli
    parse_module_specs
    parse_dist_specs
    reconfigure_dist
    rmpm
    skeleton_files
    test_scripts_for
    templates_for
    usage
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );


=head1 NAME

Module::Husbandry - build and manage perl modules in a Perl module distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTION

=over

=cut

use strict;
use Fatal qw( mkdir close );
use File::Basename;

sub _x { ## "eXception"
    my $options = ref $_[-1] ? pop : {};

    if ( $options->{describe} ) {
        warn @_;
    }
    else {
        die @_;
    }
}

sub _d { ## "describe".  Return 1 if in describe-only mode.
    my $options = pop;
    my $msg = join "", @_;
    1 while chomp $msg;
    if ( defined $options->{_prog_name} ) {
        my $sep = $options->{_prog_name_sep} || ":";
        $sep .= " ";
        $sep = "" if $msg =~ /^\W/;
        $msg =~ s/^/$options->{_prog_name}$sep/gm;
    }
    $msg .= "\n";
    print $msg unless $options->{quiet};
    $options->{describe};
}


sub _d_c { # "describe command".
    my $options = $_[-1];
    local $options->{_prog_name_sep} = '$';
    _d @_;
}

sub _rel($) {
    my ( $p ) = @_;
    require File::Spec;
    $p = File::Spec->abs2rel( $p );
}


sub _mkdir {
    my ( $dir, $options ) = @_;
    unless ( -d $dir or _d_c "mkdir -p ", _rel $dir, $options ) {
        require File::Path;
        File::Path::mkpath( [ $dir ] );
    }
}


sub _mkparentdir {
    my ( $fn, $options ) = @_;
    _mkdir( (fileparse $fn)[1], $options );
}


sub _chdir {
    my ( $dir, $options ) = @_;
    require Cwd;
    return if $dir eq Cwd::cwd();
    _mkdir $dir, $options;
    chdir $dir or die "$!: $dir\n"
        unless _d_c "chdir ", _rel $dir, $options;
}
    

=item parse_module_specs

    my @specs = parse_module_specs @ARGV, \%options;

Parses a module specification, one of:

    Foo
    Foo::Bar
    lib/Foo.pm
    lib/Foo/Bar.pm
    lib/Foo/Bar.pod

and returns the package name (C<Foo::Bar>) and the path to the
file (C<lib/Foo/Bar.pm>) for each parameter in a hash.  The result HASHes
look like:

    {
         Filename       => "lib/Foo/Bar.pm",
         Package        => "Foo::Bar",
         Spec           => $spec,   ## What was passed in
    };

Any name containing characters other that A-Z, 0-9, :, or ' are assumed
to be filenames.  Filenames should begin with lib/ (or LIB/ on Win32)
or will be warned about.

The only option provided is:

    as_dir    Set this to 1 to suppress the add "/" instead of ".pm"
              the Filename when a module name is converted to a filename.
              Does not affect anything when a filename is parsed.  This
              is used by mvpm's recurse option.

=cut

sub parse_module_specs {
    my $options = @_ && ref $_[-1] ? pop : {};

    map {
        my $spec = $_;

        my ( $pkg, $fn ) = $spec =~ /[^\w:']/ 
            ? do {
                require File::Spec;
                my $p = File::Spec->canonpath( $spec );
                for ( $p ) {
                    s{^(\.[\\/]+)+}{};
                    ( $^O =~ /Win32/
                        ? s{^lib[\\/]+}{}i
                        : s{^lib[\\/]+}{}
                    ) or warn "Module spec '$spec' does not begin with lib/\n";
                    s{[\\/]+}{::}g;
                    s{\..*\z}{};
                }
                ( $p, $spec );
            }
            : do {
                ( my $p = $spec ) =~ s{::}{/}g;
                ( $spec, $options->{as_dir} ? "lib/$p" : "lib/$p.pm" );
            };

        {
             Filename => $fn,
             Package  => $pkg,
             Spec     => $spec,
        };
    } @_;
}


=item parse_bin_specs

    my @specs = parse_bin_specs @ARGV, \%options;

Parses specifications for a "bin" program, like:

    foo
    bin/foo

and returns the program name (C<foo>) and the path to the
file (C<bin/foo>) for each parameter in a hash.  The result HASHes
look like:

    {
         Filename       => "bin/foo",
         Program        => "foo",
         Spec           => $spec,   ## What was passed in
    };

If a spec has no directory separators, "bin/" is prepended.
If a spec has directory separator, no "bin/" is prepended.

=cut

sub parse_bin_specs {
    my $options = @_ && ref $_[-1] ? pop : {};

    map {
        my $spec = $_;

        require File::Spec;
        my @names = File::Spec->splitdir( $spec );
        unshift @names, "bin" if @names == 1;
        my $fn = File::Spec->canonpath( File::Spec->catdir( @names ) );
        my $program = (fileparse $fn);

        {
             Filename => $fn,
             Program  => $program,
             Spec     => $spec,
        };
    } @_;
}


=item parse_dist_specs

Takes a list of distributions specs (Foo::Bar, Foo-Bar) and returns a hash
like 

    {
        Package => "Foo::Bar",
        Spec    => $spec,
    }

=cut

sub parse_dist_specs {
    map {
        my $spec = $_;

        ( my $pkg = $spec ) =~ s{-}{::}g;
        ( my $dn  = $spec ) =~ s{::}{-}g;

        {
             Spec     => $spec,
             Package  => $pkg,
             DistName => $dn,
        };
    } @_;
}


=item reconfigure_dist

Runs perl Makefile.PL using the current Perl.

TODO: Support Module::Build methodology.

=cut

sub reconfigure_dist {
    my ( $options ) = @_;

    if ( -f "Makefile" ) {
        if ( -f "Makefile.PL" ) {
            unless ( _d_c "touch Makefile.PL", $options ) {
                my $time = time;
                utime $time, $time, "Makefile.PL"
                    or warn "$! touching Makefile.PL";
                if ( (stat "Makefile")[9] >= $time
                    && ! _d_c "untouch Makefile", $options
                ) {
                    utime $time - 1, $time - 1, "Makefile"
                        or warn "$! touching Makefile.PL";
                }
            }
        }

        system "make Makefile" unless _d_c "make Makefile\n", $options;
    }
    elsif ( -f "Makefile.PL" ) {
        system $^X, "Makefile.PL" unless _d_c "$^X Makefile\n", $options;
    }
    else {
        warn "Can't reconfigure distribution, no Makefile or Makefile.PL found\n"
            unless $options->{describe};
    }

}


=item add_to_MANIFEST

    add_to_MANIFEST "foo", "bar";

Adds one or more files to the MANIFEST.

=cut

## TODO: back up to the backup dirs used elsewhere.

sub _backup_and_read_MANIFEST {
    my $options = @_ && ref $_[-1] ? pop : {};

    my @manifest;
    if ( -e "MANIFEST"  && ! _d_c "cp MANIFEST MANIFEST.old", $options ) {
        open MANIFEST, "<MANIFEST"
            or die "$!: MANIFEST\n";
        @manifest = grep length, map {
            1 while chomp;
            $_;
        } <MANIFEST>;
        close MANIFEST;
        unlink "MANIFEST.old" or die "$!: MANIFEST.old"
            if -e "MANIFEST.old";
        rename "MANIFEST", "MANIFEST.old"
            or die "$! while renaming MANIFEST to MANIFEST.old\n";
        $options->{clean_up_MANIFEST} = 1;
    }

    return \@manifest;
}

sub _write_MANIFEST {
    my ( $manifest, $options ) = @_;

    unless ( $options->{describe} ) {
        ## TODO: Also add other files not in MANIFEST.SKIP by default?
        ## Normally, this is done by the skeleton MANIFEST.
        push @$manifest, "MANIFEST" unless @$manifest;

        open MANIFEST, ">MANIFEST" or die "$!: MANIFEST";
        my %seen;
        print MANIFEST map "$_\n", sort grep !$seen{$_}++, @$manifest
            or die "$! writing MANIFEST";
        close MANIFEST;
    }

    unlink "MANIFEST.old" or warn "$! MANIFEST.old\n"
        if $options->{clean_up_MANIFEST} && ! _d_c "rm MANIFEST.old", $options;
}


sub add_to_MANIFEST {
    my $options = @_ && ref $_[-1] ? pop : {};

    my $manifest =  _backup_and_read_MANIFEST $options;
    unless ( _d_c
        "echo ",
        join( " ", map "'$_'", @_ ),
        " >> MANIFEST   ## and sort it",
        $options 
    ) {
        push @$manifest, @_;
    }

    _write_MANIFEST $manifest, $options;
}


=item rm_from_MANIFEST

    rm_from_MANIFEST "foo", "bar";

Remove one or more files to the MANIFEST.

=cut

sub rm_from_MANIFEST {
    my $options = @_ && ref $_[-1] ? pop : {};

    my $manifest = _backup_and_read_MANIFEST $options;

    unless ( _d_c
        "cat MANIFEST.old | grep -v '",
        join( "|", map "$_", @_ ),
        "' >> MANIFEST",
        $options 
    ) {
        my %doomed = map { ( $_ => 1 ) } @_;
        @$manifest = grep ! exists $doomed{$_}, @$manifest;
    }

    _write_MANIFEST $manifest, $options;
}


=item install_file

    install_file $from_file_hash, $to_file_hash, \%macros;

Locates the approptiate file in the .newpm directory and copies it,
instantiating any <%macros%> needed.

Reads <%meta foo bar %> and <%meta foo=bar %> tags.

    Meta tags
    =========
    <%meta chmod 0755 %>    chmod the resulting file (numeric only)

Any unrecognized meta or macro tags are ignored with a warning.

Adds file to MANIFEST.

TODO: adapt to Module::Build's manifesting procedures.

=cut

sub install_file {
    my $options = @_ > 3 ? pop : {};
    my ( $from, $to, $macros ) = @_;

    return if _d_c "install ",
        basename( $from->{Filename} ),
        " $to->{Filename}\n", $options;

    _mkparentdir $to->{Filename}, $options;

    open F, $from->{Filename}  or die "$!: $from->{Filename}\n";
    open T, ">$to->{Filename}" or die "$!: $to->{Filename}\n";
    my %meta;
    while (<F>) {
        for my $macro ( keys %$macros ) {
            s/<%\s*$macro\s*%>/$macros->{$macro}/gi;
        }
        s{
            <%\s*META\s*([a-z]\w+)\s*(?:=\s*)?(.*?)\s*%>
        }{
            $meta{lc $1} = $2;
            "";
        }geix;
        warn "install: WARNING: macro $1 in $from->{Filename} line $. ignored.\n"
            for /(<%.*?%>)/g;
        print T $_ or die "$! writing to $to->{Filename}\n";
    }
    close F;
    close T;

    if ( my $perms = delete $meta{chmod} ) {
        unless ( _d_c "chmod $perms $to->{Filename}", $options ) {
            $perms = oct $perms if substr( $perms, 0, 1 ) eq "0";
            chmod $perms, $to->{Filename}
                or warn "$! chmod( $perms )ing $to->{Filename}\n";
        }
    }

    warn "install: WARNING: ignoring META setting",
        " $_ $meta{$_} in $from->{Filename}\n"
        for sort keys %meta;

    add_to_MANIFEST $to->{Filename}, $options;
}


=item templates_for

    my @from_files = templates_for @to_files;

Given a list of files to write to, find the appropriate source files.

=cut

{
    use vars qw( $template_dir );
    
    sub template_dir {
        if ( ! defined $template_dir ) {
            $template_dir = File::Spec->catdir(
                $^O =~ /Win32/
                    ? "C:\\etc"
                    : $ENV{HOME},
                $^O =~ /Win32/
                    ? "newpm"
                    : ".newpm"
            );
        }
        $template_dir;
    }
}
    

sub templates_for {
    require File::Spec;
    map {
        my $fn = $_->{Filename};
        $fn =~ s{\A[^.]*(\.|\z)}{Template$1};
        {
            Filename => File::Spec->catfile( template_dir, $fn ),
        };
    } @_;
}

=item test_scripts_for

    my @test_scripts = test_scripts_for @modules;

Returns test scripts for any .pm and .pl file in @modules:

    {
        Filename => "t/Foo.t",
    }

where @modules is an array of HASHes returned by parse_module_specs.

=cut

sub test_scripts_for {
    map {
        ( $_->{Filename} =~
            ( ( $^O =~ /Win32/ )
                ? qr/\.p[ml]\z/i
                : qr/\.p[ml]\z/
            ) )
            ? do {
                ( my $fn = $_->{Package} ) =~ s{::}{-}g;

                {
                    Filename => "t/$fn.t",
                };
            }
            : ();
    } @_;
}

=item skeleton_files

    my %skel_map = skeleton_files $target_dir;

Returns a list of from/to files to install from the skeleton directory.

=cut

sub skeleton_files {
    my ( $target_dir ) = @_;

    require File::Find;
    require File::Spec;

    my $skel_dir = File::Spec->catdir( template_dir, "skel" );

    die "$skel_dir not found\n" unless -e $skel_dir;

    my @files;
    File::Find::find(
        {
            wanted => sub {
                return unless -f;
                my $to_fn = File::Spec->abs2rel( $_, $skel_dir );
                $to_fn =~ s{\A(\.[\\/]+)+}{}g;
                my $from_fn = File::Spec->catfile( $skel_dir, $to_fn );
                push @files, [
                    {  # From file
                        Filename => $from_fn,
                    },
                    {  # To file
                        Filename => $to_fn,
                    },
                ];
            },
            no_chdir => 1,
        },
        $skel_dir
    );

    return @files;
}

=item cppm

    cppm $from, $to, \%options

Copies a file in a distribution and a related test suite (if found).

TODO: Don't rewrite changelogs.  Not sure how best to recognize them; this
could be an option for the mythical .newpmrc.

TODO: Make the filename substitutions patterns case insensitive on Win32?

=cut

sub cppm {
    my $options = @_ && ref $_[-1] ? pop : {};

    my @copies;
    require File::Find;
    require File::Spec;

    my %substs;      ## Strings to substitute as a result of the name change
    my $substs_pat;  ## The re that looks for things to substitute

    if ( $options->{recurse} ) {
        die "Sorry, -r not implemented yet.\n";
        my ( $from, $to ) = parse_module_specs @_, { as_dir => 1 };

        ### SET from_pat, to_name

        my ( $bn, $dn ) = fileparse $from->{Filename};
        File::Find::find(
            {
                no_chdir => 1,
                wanted => sub {
                    my $p = File::Spec->abs2rel( $_, $dn );
                    ## TODO
                },
            },
            $dn
        );
    }
    else {
        my ( $from, $to ) = parse_module_specs @_;

        _x "$from->{Filename} not found\n", $options
            unless -e $from->{Filename};

        _x "$from->{Filename} is not a file\n", $options
            unless -f _;

        _x "$to->{Filename} exists (and is a directory), not copying module\n", $options
            if -d $to->{Filename};

        _x "$to->{Filename} exists, not copying module\n", $options
            if -e _;

        push @copies, [ $from, $to ];

        %substs = (
            $from->{Package}  => $to->{Package},
            $from->{Filename} => $to->{Filename},
        );

        my ( $test_script_from ) = test_scripts_for $from;
        my ( $test_script_to   ) = test_scripts_for $to;

        if (
            $test_script_from
            && $test_script_to
            && -f $test_script_from->{Filename}
        ) {
            push @copies, [ $test_script_from, $test_script_to ];
            $substs{$test_script_from->{Filename}}
                = $test_script_to->{Filename};
        }

        $substs_pat = join(
            join( "|", map quotemeta, sort keys %substs ),
            "\\b(",
            ")\\b"
        );
        $substs_pat = qr/$substs_pat/;
    }

    require File::Copy;

    my ( $from_w, $to_w ) = ( 0, 0 );  # for pretty-printing

    for ( @copies ) {
        my ( $from, $to ) = @$_;
        $from_w = length $from->{Filename}
            if length $from->{Filename} > $from_w;
        $to_w = length $to->{Filename}
            if length $to->{Filename} > $to_w;
    }

    {
        my $f_w = ( 0, 0 );
        for ( keys %substs ) {
            $f_w = length $_ if length $_ > $f_w;
        }
        my $f = "# subst: %-${f_w}s => %s\n";
        _d sprintf( $f, $_, $substs{$_} ), $options for sort keys %substs;
    }

    for ( @copies ) {
        my $from_fn = $_->[0]->{Filename};
        my $to_fn   = $_->[1]->{Filename};

        unless ( _d_c
            sprintf( "munge %-${from_w}s > %s\n", $from_fn, $to_fn ),
            $options
        ) {
            open FROM, "<$from_fn" or die "$!: $from_fn";
            open TO,   ">$to_fn"   or die "$!: $to_fn";

            while (<FROM>) {
                s/$substs_pat/$substs{$1}/sge;
                print TO $_;
            }

            close FROM;
            close TO;
        }

        add_to_MANIFEST $to_fn, $options;
    }

    reconfigure_dist $options;
}

=item newpm

Create new modules in ./lib/... and, if it's a .pm module,
a test suite in ./t/...

Does not build the make file.

=cut

{
    use vars qw( $time );
    sub _time {
        $time = time unless defined $time;
        $time;
    }
}


sub _newpm_installs {
    my $options = ref $_[-1] ? pop : {};
    my @modules = parse_module_specs @_;

    my @errors;

    my @installs;

    for my $module ( @modules ) {
        my %macros = (
            PackageName => $module->{Package},
            ModulePath  => $module->{Filename},
            Date        => scalar localtime( _time ),
            Year        => 1900 + (localtime( _time ))[5],
        );

        push @errors, "$module->{Filename} found, can't overwrite\n"
            if -e $module->{Filename};

        my ( $template ) = templates_for $module;

        push @installs, [ $template, $module, \%macros ];

        my ( $test_script ) = test_scripts_for $module;

        if ( defined $test_script ) {
            my ( $test_script_template ) = templates_for $test_script;
            _x "$test_script->{Filename} found, can't overwrite.\n", $options
                if -e $test_script->{Filename};
            push @installs, [ $test_script_template, $test_script, \%macros ];
        }
    }
    _x @errors, $options if @errors;

    @installs;
}


sub newpm {
    my $options = ref $_[-1] ? pop : {};
    install_file @$_, $options for _newpm_installs @_, $options;
    reconfigure_dist $options;
}

=item newpmbin

Create new script files in bin/.  Does not add a test script
(since there's no safe way to test an arbitrary program).

=cut

sub _newpmbin_installs {
    my $options = ref $_[-1] ? pop : {};
    my @programs = parse_bin_specs @_;

    my @errors;

    my @installs;

    for my $program ( @programs ) {
        my %macros = (
            ProgramName => $program->{Program},
            ProgramPath => $program->{Filename},
            Date        => scalar localtime( _time ),
            Year        => 1900 + (localtime( _time ))[5],
        );

        push @errors, "$program->{Filename} found, can't overwrite\n"
            if -e $program->{Program};

        my ( $template ) = templates_for $program;

        push @installs, [ $template, $program, \%macros ];

#        my ( $test_script ) = test_scripts_for $program;
#
#        if ( defined $test_script ) {
#            my ( $test_script_template ) = templates_for $test_script;
#            _x "$test_script->{Filename} found, can't overwrite.\n", $options
#                if -e $test_script->{Filename};
#            push @installs, [ $test_script_template, $test_script, \%macros ];
#        }
    }
    _x @errors, $options if @errors;

    @installs;
}


sub newpmbin {
    my $options = ref $_[-1] ? pop : {};
    install_file @$_, $options for _newpmbin_installs @_, $options;
    reconfigure_dist $options;
}

=item newpmdist

Create a new distribution in . and populate it from the skeleton
files.  newpm() a new module.

=cut

sub newpmdist {
    my $options = ref $_[-1] ? pop : {};
    my @installs;

    for my $dist ( parse_dist_specs @_ ) {
        my ( $module ) = parse_module_specs $dist->{Package};

        my %macros = (
            PackageName => $dist->{Package},
            ProgramName => $dist->{Program},
            DistName    => $dist->{DistName},
            ModulePath  => $module->{Filename},
            Date        => scalar localtime( _time ),
            Year        => 1900 + (localtime( _time ))[5],
        );

        my @files = skeleton_files $dist->{DistName};

        _x "No skeleton files found for dist $dist->{Spec}\n", $options
            unless @files;

        push @installs, $dist->{DistName};
        push @installs, map [ @$_, \%macros ], sort @files;
        push @installs, _newpm_installs $module->{Package};
        push @installs, "reconfigure!";
    }

    require Cwd;
    my $d = Cwd::cwd();

    for ( @installs ) {
        if ( ref $_ ) {
            install_file @$_, $options;
        }
        elsif ( $_ eq "reconfigure!" ) {
            reconfigure_dist $options;
        }
        else {
            my $dir = File::Spec->catdir( $d, $_ );
            _chdir $dir, $options;
        }
    }

    _chdir $d, $options;
}

=item mvpm

    mvpm $from, $to, \%options

Changes the name of a file in a distribution and all occurences of the
file's name (and, if applicable, package name) in it and in all other
files.

A backup of any files changed is placed in .newpm/bak_0000 (where 0000
increments each time).

TODO: some kind of locking so simultaneous mvpms don't happen to choose
the same backup directory name.

TODO: Don't rewrite changelogs.  Not sure how best to recognize them; this
could be an option for the mythical .newpmrc.

TODO: Make the filename substitutions patterns case insensitive on Win32?

=cut

{
    use vars qw( $workdir );
    sub _workdir {
        $workdir = ".mvpm.d" unless defined $workdir;
        $workdir;
    }
}


sub _mk_bak_dir {
    my $options = pop;

    my $wd = _workdir;

    require File::Spec;
    my $max = 0;
    for ( glob( "$wd/bak_*" ) ) {
        /\bbak_(\d+)/ or warn "Unusual backup dir name: '$_'\n";
        my $n = $1 || 0;
        $max = $n if $n > $max;
    }

    my $bd = sprintf "$wd/bak_%04d", $max + 1;

    die "BUG: trying to reuse backup dir $bd" if -e $bd;

    _mkdir $bd, $options;

    return $bd;
}


sub mvpm {
    my $options = @_ && ref $_[-1] ? pop : {};

    my @moves;
    require File::Find;
    require File::Spec;

    my %substs;      ## Strings to substitute as a result of the name change
    my $substs_pat;  ## The re that looks for things to substitute

    if ( $options->{recurse} ) {
        die "Sorry, -r not implemented yet.\n";
        my ( $from, $to ) = parse_module_specs @_, { as_dir => 1 };

        ### SET from_pat, to_name

        my ( $bn, $dn ) = fileparse $from->{Filename};
        File::Find::find(
            {
                no_chdir => 1,
                wanted => sub {
                    my $p = File::Spec->abs2rel( $_, $dn );
                    ## TODO
                },
            },
            $dn
        );
    }
    else {
        my ( $from, $to ) = parse_module_specs @_;

        _x "$from->{Filename} not found\n", $options
            unless -e $from->{Filename};

        _x "$from->{Filename} is not a file\n", $options
            unless -f _;

        _x "$to->{Filename} exists (and is a directory), not moving module\n", $options
            if -d $to->{Filename};

        _x "$to->{Filename} exists, not moving module\n", $options
            if -e _;

        push @moves, [ $from, $to ];

        %substs = (
            $from->{Package}  => $to->{Package},
            $from->{Filename} => $to->{Filename},
        );

        my ( $test_script_from ) = test_scripts_for $from;
        my ( $test_script_to   ) = test_scripts_for $to;

        if (
            $test_script_from
            && $test_script_to
            && -f $test_script_from->{Filename}
        ) {
            push @moves, [ $test_script_from, $test_script_to ];
            $substs{$test_script_from->{Filename}}
                = $test_script_to->{Filename};
        }

        $substs_pat = join(
            join( "|", map quotemeta, sort keys %substs ),
            "\\b(",
            ")\\b"
        );
        $substs_pat = qr/$substs_pat/;

        require Cwd;
        my $cwd = Cwd::cwd();

        File::Find::find(
            {
                no_chdir => 1,
                wanted => sub {
                    my $p = File::Spec->abs2rel( $_, $cwd );
                    my $is_d = -d;

                    $File::Find::prune =
                        $p eq template_dir
                        || $p eq _workdir
                        || $p eq "blib"
                        || $p eq "pm_to_blib"
                        || $p =~ /^change/
                        || ( $is_d && substr( $p, 0, 1 ) eq "." );

                    if ( $File::Find::prune ) {
                        _d "# ignoring $p", $is_d ? "/..." : (), $options;
                        return;
                    }

                    return if $is_d;

                    if ( -B ) {
                        _d "# ignoring binary file $_", $options;
                        return;
                    }

                    return if $p eq $from->{Filename}
                        || (
                            $test_script_from
                            && $p eq $test_script_from->{Filename}
                        );

                    open FROM, "<$p" or die "$! while scanning $p\n";
                    while (<FROM>) {
                        if ( /$substs_pat/ ) {
                            my $f = {
                                Filename => $p,
                            };
                            push @moves, [ $f, $f ];
                            last;
                        }
                    }
                    close FROM or die "$! closing $p\n";
                },
            },
            "."
        );
    }

    require File::Copy;

    my $bak_dir = _mk_bak_dir $options;

    my ( $from_w, $to_w, $bak_w ) = ( 0, 0, 0 );  # for pretty-printing

    for ( @moves ) {
        my ( $from, $to ) = @$_;
        $from->{BakFilename}
            = File::Spec->catfile( $bak_dir, $from->{Filename} );

        $from_w = length $from->{Filename}
            if length $from->{Filename} > $from_w;
        $bak_w = length $from->{BakFilename}
            if length $from->{BakFilename} > $bak_w;
        $to_w = length $to->{Filename}
            if length $to->{Filename} > $to_w;
    }

    for ( @moves ) {
        my $from_fn = $_->[0]->{Filename};
        my $bak_fn  = $_->[0]->{BakFilename};

        _mkparentdir(
            File::Spec->catdir( $bak_dir, $_->[0]->{Filename} ),
            $options
        );

        File::Copy::copy( $from_fn, $bak_fn )
            or die "$! copying $from_fn to $bak_fn\n"
            unless _d_c
                sprintf( "cp %-${from_w}s %s\n", $from_fn, $bak_fn ),
                $options
    }

    {
        my $f_w = ( 0, 0 );
        for ( keys %substs ) {
            $f_w = length $_ if length $_ > $f_w;
        }
        my $f = "# subst: %-${f_w}s => %s\n";
        _d sprintf( $f, $_, $substs{$_} ), $options for sort keys %substs;
    }

    for ( @moves ) {
        my $from_fn = $_->[0]->{Filename};
        my $bak_fn  = $_->[0]->{BakFilename};
        my $to_fn   = $_->[1]->{Filename};

        unless ( _d_c
            sprintf( "munge %-${bak_w}s > %s\n", $bak_fn, $to_fn ),
            $options
        ) {
            open BAK, "<$bak_fn" or die "$!: $bak_fn";
            open NEW, ">$to_fn"  or die "$!: $to_fn";

            while (<BAK>) {
                s/$substs_pat/$substs{$1}/sge;
                print NEW $_;
            }

            close BAK;
            close NEW;
        }

        unlink $from_fn or die "$! unlinking $from_fn"
            if $from_fn ne $to_fn && ! _d_c "rm $from_fn\n", $options;
    }

    reconfigure_dist $options;
}

=item rmpm

Removes any modules and tests named after a package (or module) name.

Warns about any other files that refer to the doomed package.

A backup is made in the backup directory (.mvpm/... for now, will change)..

TODO: Allow a site-specific rm command to be used, like 'trash', so
this command may be better integrated with a user's working environment.
This will wait until we restructure the directories.

=cut

sub rmpm {
    my $options = @_ && ref $_[-1] ? pop : {};

    my @deletes;     ## Those who are about to die, we salute you...
    require File::Find;
    require File::Spec;

    my %spoor;       ## Strings to scan for before deleting
    my $spoor_pat;   ## The re used to scan for %spoor
    my @spoor; ## filenames, line numbers and lines of spoor that
                     ## will be left behind.

    if ( $options->{recurse} ) {
        die "Sorry, -r not implemented yet.\n";
        my @doomed = parse_module_specs @_, { as_dir => 1 };

        ### SET doomed_pat
#
#        my ( $bn, $dn ) = fileparse $from->{Filename};
#        File::Find::find(
#            {
#                no_chdir => 1,
#                wanted => sub {
#                    my $p = File::Spec->abs2rel( $_, $dn );
#                    ## TODO
#                },
#            },
#            $dn
#        );
    }
    else {
        my @doomed = parse_module_specs @_;

        for my $doomed ( @doomed ) {
            _x "$doomed->{Filename} not found\n", $options
                unless -e $doomed->{Filename};

            _x "$doomed->{Filename} is not a file\n", $options
                unless -f _;

            push @deletes, [ $doomed ];

            %spoor = (
                $doomed->{Package}  => undef,
                $doomed->{Filename} => undef,
            );

            my ( $doomed_test_script ) = test_scripts_for $doomed;

            if (
                $doomed_test_script
                && -f $doomed_test_script->{Filename}
            ) {
                push @deletes, [ $doomed_test_script ];
                $spoor{$doomed_test_script->{Filename}} = undef;
            }
        }

        $spoor_pat = join(
            join( "|", map quotemeta, sort keys %spoor),
            "\\b(",
            ")\\b"
        );
        my $spoor_pat_re = qr/$spoor_pat/;

        require Cwd;
        my $cwd = Cwd::cwd();

        ## TODO: generalize all or part of this so mvpm() and rmpm() can
        ## share it.
        File::Find::find(
            {
                no_chdir => 1,
                wanted => sub {
                    my $p = File::Spec->abs2rel( $_, $cwd );
                    my $is_d = -d;

                    $File::Find::prune =
                        $p eq template_dir
                        || $p eq _workdir
                        || $p eq "blib"
                        || $p eq "pm_to_blib"
                        || $p =~ /^change/
                        || ( $is_d && substr( $p, 0, 1 ) eq "." );

                    if ( $File::Find::prune ) {
                        _d "# ignoring $p", $is_d ? "/..." : (), $options;
                        return;
                    }

                    return if $is_d;

                    if ( -B ) {
                        _d "# ignoring binary file $_", $options;
                        return;
                    }

                    return if grep $p eq $_->{Filename}, @doomed;

                    open SURVIVORS, "<$p" or die "$! while scanning $p\n";
                    while (<SURVIVORS>) {
                        if ( /$spoor_pat_re/ ) {
                            1 while chomp;
                            push @spoor, [ $p, $., $_ ];
                            last;
                        }
                    }
                    close SURVIVORS or die "$! closing $p\n";
                },
            },
            "."
        );
    }

    if ( @spoor ) {
        my ( $sfn_w, $ln_w ) = ( 0, 0 );
        my @spoor_recs;
        for ( @spoor ) {
            local $_ = [ "$_->[0],", @{$_}[1,2]];
            push @spoor_recs, $_;
            $sfn_w = length $_->[0] if length $_->[0] > $sfn_w;
            $ln_w  = length $_->[1] if length $_->[1] > $ln_w;
        }

        my $spoor_format = "%-${sfn_w}s %${ln_w}d: %s\n";

        _d_c "grep -r '$spoor_pat' .", $options;
        printf $spoor_format, @$_ for @spoor_recs;
    }


    my $bak_dir = _mk_bak_dir $options;

    my ( $from_w, $bak_w ) = ( 0, 0, 0 );  # for pretty-printing

    for ( @deletes ) {
        my ( $from ) = @$_;
        $from->{BakFilename}
            = File::Spec->catfile( $bak_dir, $from->{Filename} );

        $from_w = length $from->{Filename}
            if length $from->{Filename} > $from_w;
        $bak_w = length $from->{BakFilename}
            if length $from->{BakFilename} > $bak_w;
    }

    require File::Copy;
    for ( @deletes ) {
        my $from_fn = $_->[0]->{Filename};
        my $bak_fn  = $_->[0]->{BakFilename};

        _mkparentdir(
            File::Spec->catdir( $bak_dir, $_->[0]->{Filename} ),
            $options
        );

        File::Copy::copy( $from_fn, $bak_fn )
            or die "$! copying $from_fn to $bak_fn\n"
            unless _d_c
                sprintf( "cp %-${from_w}s %s\n", $from_fn, $bak_fn ),
                $options
    }

    for ( @deletes ) {
        my $from_fn = $_->[0]->{Filename};
        unlink $from_fn or die "$! unlinking $from_fn";
        rm_from_MANIFEST $from_fn;
    }

    reconfigure_dist $options;
}

=item usage

=cut

sub usage {
    my ( $messages, $spec ) = @_;
    my $prog_name = basename $0;

    push @$messages, "\nSee $prog_name --help for details" if @$messages;
    my $message = join "\n", @$messages, @$messages ? ( "", "" ) : ();

    my $examples = $spec->{examples};

    my $desc;
    $desc = $spec->{description} if ! length $message;
    $desc ||= "";

    my $options =
        join "\n", map {
            my $name = join ", ", grep length, split /\|+/;
            my @desc = 
                length $messages
                    ? ()
                    : do {
                        my $desc = $spec->{$_};
                        $desc =~ s/^(\w+:)?(\w+=)?\s*//;
                        $desc =~ s/^/    /;
                        1 while chomp $desc;
                        "$desc\n";
                    };
            ( $name, @desc );
        } grep /^-/, sort keys %$spec;

    1 while chomp $message;
    1 while chomp $examples;
    1 while chomp $desc;

    s/^/    /mg for ( grep length, $examples, $desc, $options );
    $message  = "$message\n\n"             if length $message;
    $examples = "Usage\n\n$examples\n\n"   if length $examples;
    $options  = "Options (may occur anywhere except after a '--')\n\n$options\n\n"  if length $options;
    $desc     = "Description\n\n$desc\n\n" if length $desc;

    my $usage = "$message$examples$options$desc";
    $usage =~ s/%p/$prog_name/g;
    print $usage;

    exit length $messages ? 1 : 0;
}


=item parse_cli

    my ( $options, @params ) = parse_options @ARGV, \%spec;

Reads the command line and parses out the options and other parameters.
Options may be intermixed with parameters.

Options -h|-?|--help and -- do the normal things always.

-n|--describe print out what *would* happen, but do nothing.

=cut

sub parse_cli {
    my ( $cli, $spec ) = @_;

    my ( %options, @params );  ## These shall be returned if all is ok.

    $options{_prog_name} = basename $0;

    my %options_spec;
    my @errors;
    my $check;
    my ( $min_params, $max_params );
    my $found_examples;

    $spec->{"-h|-?|--help"}  = "Display full help";
    $spec->{"-n|--describe"} = "Describe what would happen without doing it";
    $spec->{"--"}            = "Mark end of options";

    for ( keys %$spec ) {
        my $desc = $spec->{$_};
        if ( substr( $_, 0, 1 ) eq "-" ) {
            my $type = "flag";
            $type = $1 if $desc =~ s/^(\w+)://;
            my $canonical_spelling;
            $canonical_spelling = $1 if $desc =~ s/^(\w+)=//;
            
            my @spellings = split /\|/;
            unless ( defined $canonical_spelling ) {
                $canonical_spelling = $spellings[-1];
                $canonical_spelling =~ s/^-+//;
                $canonical_spelling =~ s/\W/_/g;
                $canonical_spelling =~ s/^(\d)/_$1/;
            }

            my $action = 
                $type eq "flag" ? sub { $options{$canonical_spelling} = $desc }
                : do {
                    push @errors, "Unrecognized option type '$type:'";
                    next;
                };

            $options_spec{$_} = $action
                for @spellings;
        }
        elsif ( $_ eq "check" ) {
            $check = $desc;
        }
        elsif ( $_ eq "param_count" ) {
            if ( $desc =~ /\A(\d+)\.\.((?:\d+)?)\z/ ) {
                ( $min_params, $max_params) = ( $1, $2 );
                $max_params = 1_000_000_000 unless length $max_params;
            }
            else {
                ( $min_params, $max_params) = ( $desc, $desc );
            }
        }
        elsif ( $_ eq "examples" ) {
            $found_examples = 1;
        }
        elsif ( $_ eq "description" ) {
            ## ignore it, it's optional
        }
        else {
            push @errors, "unrecognized option spec key '$_'";
        }
    }

    push @errors, "examples missing from command line parsing spec"
        unless $found_examples;

    my @checks;
    if ( defined $min_params ) {
        push @checks, sub {
            pop;
            join "",
                @_ < $min_params
                    ? (
                        "missing parameter",
                        $min_params - @_ > 1 ? "s" : (),
                        ": expected ",
                        $min_params != $max_params ? "at least " : (),
                        $min_params,
                        ", got ",
                        scalar @_,
                    )
                : @_ > $max_params 
                    ? (
                        "extra parameter",
                        @_ - $max_params > 1 ? "s" : (),
                        ": expected ",
                        $min_params != $max_params ? "at most " : (),
                        $max_params,
                        ", got ",
                        scalar @_,
                    )
                : ();
        };
    }

    push @checks, $check if $check;

    require Carp, Carp::croak( join "\n", @errors ) if @errors;

    $options_spec{"--"} =
        sub { push @params, splice @$cli; last };

    $options_spec{"-h"} =
        $options_spec{"--help"} =
        $options_spec{"-?"} =
            sub { usage [], $spec };

    while ( @$cli ) {
        my $p = shift @$cli;
        if ( substr( $p, 0, 1 ) eq "-" ) {
            my $d = $options_spec{$p};
            unless ( defined $d ) {
                push @errors, "unrecognized option: $p";
                next;
            }

            if ( ref $d eq "CODE" ) {
                 last unless defined $d->();
            }
            else {
                require Carp;
                Carp::confess "BUG: $d is not a CODE ref";
            }
        }
        else {
            push @params, $p;
        }
    }

    push @errors, grep defined && length, $_->( @params, \%options )
        for @checks;

    usage \@errors, $spec
        if @errors;

    return ( @params, \%options );
}

=back

=head1 LIMITATIONS

ASSumes a dir tree and file naming conventions like:

    Foo-Bar/
        Makefile.PL
        ...
        lib/Foo/Bar.pm
        t/Foo-Bar.pm

This probably won't work out all that well for XS distributions, not
sure how they work.  Let me know and we'll see if we can add it :)

Not tested on Win32.

Does not know about Module::Build.

Does not use anything like a .newpmrc file.

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
