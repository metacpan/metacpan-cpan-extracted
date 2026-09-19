package Perl::Tests::Covering;
$Perl::Tests::Covering::VERSION = '0.002';
# ABSTRACT: Which tests run the file you just changed, from coverage kept on disk.

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use Readonly;

use Carp                             ();
use Config                           ();
use Cwd                              ();
use Cpanel::JSON::XS                 ();
use Devel::Cover::DB                 ();
use Devel::Cover::DB::IO             ();
use Digest::MD5                      ();
use Digest::SHA                      ();
use File::Find                       ();
use File::Path                       ();
use File::Slurper                    ();
use File::Slurper::Temp              ();
use File::Spec                       ();
use File::Temp                       ();
use IO::Compress::Gzip               ();
use IO::Uncompress::Gunzip           ();
use List::Util                       ();
use POSIX                            ();
use PPI                              ();
use TAP::Parser::SourceHandler::Perl ();
use Text::ParseWords                 ();

use parent qw{Exporter};
our @EXPORT_OK = qw{NO_TESTS};

# What a map returns to say that a path reaches no test: the empty string,
# which no path is.
use constant NO_TESTS => q{};


# Change it when what the cache holds changes shape.
Readonly::Scalar my $CACHE_FORMAT => 2;

Readonly::Scalar my $CACHE_NAME => 'perl-tests-covering';

# What this module names the files in its cache directory.
Readonly::Scalar my $CACHE_FILE_RX => qr/\A[0-9a-f]{40}[.]json[.]gz\z/;

# The files that say a directory is the root of a distribution.
Readonly::Array my @DIST_MARKERS => qw{dist.ini Makefile.PL Build.PL cpanfile META.json .git};

# The map a distribution has when it names none.
Readonly::Scalar my $DEFAULT_MAP => '.tests-covering-map.pl';

# What exec returns with in a child that could not become the test.
Readonly::Scalar my $EXEC_FAILED => 127;

# The directory this module was loaded from, so that a run can load the
# recorder from the same place.  Taken now, because __FILE__ may be relative to
# the directory we started in.
Readonly::Scalar my $OWN_LIB => File::Spec->rel2abs(__FILE__) =~ s{[/\\]Perl[/\\]Tests[/\\]Covering[.]pm\z}{}r;


sub new {
    my ( $class, %opts ) = @_;

    my %known   = map  { $_ => 1 } qw{root tests lib jobs cache_dir map unexplained};
    my @unknown = grep { !$known{$_} } sort keys %opts;
    Carp::croak("Unknown option(s) to $class->new: @unknown") if @unknown;

    my $root = defined $opts{root} ? Cwd::abs_path( $opts{root} ) : _find_root( Cwd::getcwd() );
    Carp::croak( 'No root: ' . ( $opts{root} // 'no distribution above ' . Cwd::getcwd() ) ) if !defined $root || !-d $root;

    foreach my $list (qw{tests lib}) {
        Carp::croak("$list must be a list of directories, not '$opts{$list}'") if defined $opts{$list} && ref $opts{$list} ne 'ARRAY';
    }

    my $jobs = $opts{jobs} // 1;
    Carp::croak("jobs must be a whole number of 1 or more, not '$jobs'") if $jobs !~ m/\A[1-9][0-9]*\z/;

    my $unexplained = $opts{unexplained} // 'none';
    Carp::croak("unexplained must be none or all, not '$unexplained'") if $unexplained !~ m/\A(?:none|all)\z/;

    my $self = bless {
        root        => $root,
        tests       => [ @{ $opts{tests} // ['t'] } ],
        lib         => [ @{ $opts{lib}   // ['lib'] } ],
        jobs        => $jobs,
        cache_dir   => $opts{cache_dir} // _default_cache_dir(),
        unexplained => $unexplained,
        blob        => {},
    }, $class;

    my $default_map = File::Spec->catfile( $root, $DEFAULT_MAP );
    $self->{map} = $self->_load_map( exists $opts{map} ? $opts{map} : -e $default_map ? $default_map : undef );
    return $self;
}


sub root { return $_[0]{root} }


sub tests {
    my ($self) = @_;

    my @tests;
    foreach my $dir ( grep { -d } map { File::Spec->catdir( $self->{root}, $_ ) } @{ $self->{tests} } ) {
        File::Find::find( { no_chdir => 1, wanted => sub { push @tests, $File::Find::name if m/[.]t\z/ && -e && !-d } }, $dir );
    }
    return sort map { File::Spec->abs2rel( $_, $self->{root} ) } @tests;
}


sub refresh {
    my ($self) = @_;

    # A file edited between two refreshes has a new blob.
    $self->{blob} = {};

    my $cache  = $self->_read_cache();
    my $before = $cache->{tests};
    my ( %after, @stale );
    foreach my $test ( $self->tests() ) {
        if ( $self->_record_holds( $before->{$test}, {} ) ) {
            $after{$test} = $before->{$test};
            next;
        }
        push @stale, $test;
    }

    my $ran      = $self->_run_tests(@stale);
    my $versions = $cache->{versions};
    foreach my $test ( keys %$ran ) {
        my $new = delete $ran->{$test}{versions} // {};
        @{$versions}{ keys %$new } = values %$new;
        $after{$test} = $ran->{$test};
    }

    my $changed = @stale || grep { !$after{$_} } keys %$before;
    $self->_write_cache( \%after, $versions ) if $changed;

    $self->{before}   = $before;
    $self->{after}    = \%after;
    $self->{versions} = $versions;
    return @stale;
}


sub tests_covering {
    my ( $self, @files ) = @_;

    my @wanted = grep { defined } map { $self->_relative( $_, Cwd::getcwd() ) } @files;
    $self->refresh();

    my @records  = ( $self->{before}, $self->{after} );
    my %covering = map { $_ => 1 } map { _loaders( $_, @records ) } @wanted;
    $covering{$_} = 1 for $self->_unexplained_tests( \@wanted, \@records, {} );

    # A test that is gone covers nothing it could be run for.
    return sort grep { $self->{after}{$_} } keys %covering;
}


sub tests_covering_diff {
    my ( $self, $diff ) = @_;

    $self->{blob} = {};
    my $cache   = $self->_read_cache();
    my $cwd     = Cwd::getcwd();
    my @changes = map { $self->_resolve_change( $_, $cwd ) } _parse_diff($diff);
    my %in_diff = map { $_ => 1 } grep { defined } map { @{$_}{qw{old new}} } @changes;

    my %chosen;
    foreach my $test ( $self->tests() ) {
        my $record = $cache->{tests}{$test};
        $chosen{$test} = 1 if $in_diff{$test} || !$self->_record_holds( $record, \%in_diff ) || grep { $self->_change_reaches( $_, $record, $cache->{versions} ) } @changes;
    }

    # A Perl file that is new in the diff is usually reached through the files
    # that use it, which are in the diff too, so the map's silence explains it.
    my ( %change_of, %quiet );
    foreach my $change (@changes) {
        $change_of{$_} //= $change for grep { defined } @{$change}{qw{old new}};
        $quiet{ $change->{new} } = 1 if !defined $change->{old} && defined $change->{new} && $self->_is_perl( $change->{new} );
    }
    $chosen{$_} = 1 for $self->_unexplained_tests( [ sort keys %change_of ], [ $cache->{tests} ], \%change_of, \%quiet );
    return sort keys %chosen;
}


sub tests_covering_sub {
    my ( $self, $file, $name ) = @_;

    Carp::croak('tests_covering_sub needs a file and the name of a sub') if !defined $file || !defined $name || !length $name;
    my $rel = $self->_relative( $file, Cwd::getcwd() ) // Carp::croak("$file is not under ${\ $self->root() }");
    $self->refresh();

    my $content = eval { File::Slurper::read_binary( File::Spec->catfile( $self->{root}, $rel ) ) } // Carp::croak("Cannot read $file: $@");
    my @starts  = _sub_lines( $content, $name =~ s/\A.*:://r );
    Carp::croak("No sub $name in $file") if !@starts;

    my $blob = _git_blob($content);
    return sort grep {
        my $record = $self->{after}{$_};
        defined $record->{loaded}{$rel} && _touches( $self->{versions}{$blob}, $record->{executed}{$rel}, \@starts, [] )
    } keys %{ $self->{after} };
}


sub files_covered_by {
    my ( $self, $test ) = @_;

    Carp::croak('files_covered_by needs a test') if !defined $test;
    my $rel = $self->_relative( $test, Cwd::getcwd() ) // return;
    $self->refresh();
    return sort keys %{ $self->{after}{$rel}{loaded} // {} };
}

# The tests whose record, in any of @records, names $file as loaded.
sub _loaders {
    my ( $file, @records ) = @_;
    return map {
        my $records = $_;
        grep { exists $records->{$_}{loaded}{$file} } keys %$records
    } @records;
}

# The tests that the map, and then the unexplained option, choose for the
# paths in @$paths that no test is and no record in @$records names.
# $change_of holds the change from a diff for each path that has one.  A path
# in %$quiet is explained when the map has nothing to say about it.
sub _unexplained_tests {
    my ( $self, $paths, $records, $change_of, $quiet ) = @_;

    my %tests = map { $_ => 1 } $self->tests();
    my ( %chosen, $unexplained );
    foreach my $path ( grep { !$tests{$_} && !_loaders( $_, @$records ) } List::Util::uniq(@$paths) ) {
        my $answer  = $self->_ask_map( $path, $change_of->{$path}, \%tests );
        my @reached = ( @{ $answer->{tests} }, map { _loaders( $_, @$records ) } @{ $answer->{stand_ins} } );
        $chosen{$_} = 1 for @reached;
        $unexplained ||= !( @reached || $answer->{none} || ( $quiet->{$path} && !$answer->{said} ) );
    }
    return sort keys %tests if $unexplained && $self->{unexplained} eq 'all';
    return grep { $tests{$_} } sort keys %chosen;
}

# What the map says about one path, as a hash: tests and stand_ins, relative
# to the root; none, when it said NO_TESTS; and said, when it returned
# anything at all.  A path that is neither a test nor a file under the root is
# dropped with a warning, so a mistake in the map leaves the path unexplained
# rather than explained by nothing.
sub _ask_map {
    my ( $self, $path, $change, $tests ) = @_;

    my %answer = ( tests => [], stand_ins => [], none => 0, said => 0 );
    my $map    = $self->{map} or return \%answer;
    my @said   = $self->_in_root( sub { $map->( $path, $change ) } );
    $answer{said} = @said;

    foreach my $said (@said) {
        if ( defined $said && $said eq NO_TESTS ) {
            $answer{none} = 1;
            next;
        }
        my $rel = defined $said ? $self->_relative( $said, $self->{root} ) : undef;
        if ( defined $rel && $tests->{$rel} ) {
            push @{ $answer{tests} }, $rel;
        }
        elsif ( defined $rel && -e File::Spec->catfile( $self->{root}, $rel ) && !-d _ ) {
            push @{ $answer{stand_ins} }, $rel;
        }
        else {
            warn "tests-covering: the map said '${\( $said // 'undef' )}' for $path, which is neither a test nor a file under the root\n";
        }
    }
    return \%answer;
}

# The code reference a map option names, or undef for none.  A file is run
# as _in_root runs the map, so it can load the distribution's own modules.
sub _load_map {
    my ( $self, $map ) = @_;

    return                                                                                 if !defined $map;
    return $map                                                                            if ref $map eq 'CODE';
    Carp::croak( 'map must be a code reference or the name of a file, not a ' . ref $map ) if ref $map;

    my $path = File::Spec->rel2abs($map);
    my ($code) = $self->_in_root(
        sub {
            local ( $@, $! );
            my $got = do $path;
            Carp::croak("Cannot compile the map $map: $@")                        if $@;
            Carp::croak("Cannot read the map $map: ${\( $! || 'no such file' )}") if !defined $got && ( $! || !-e $path );
            return $got;
        }
    );
    Carp::croak("The map $map returns ${\( ref $code || 'something' )}, not a code reference") if ref $code ne 'CODE';
    return $code;
}

# Runs $code with the root as the working directory and the library
# directories at the front of @INC, and returns what it returns in list
# context.  A die in $code dies here, after the working directory is back.
sub _in_root {
    my ( $self, $code ) = @_;

    my $was = Cwd::getcwd();
    chdir $self->{root} or Carp::croak("Cannot chdir to $self->{root}: $!");
    local @INC = ( ( map { File::Spec->rel2abs( $_, $self->{root} ) } @{ $self->{lib} } ), @INC );
    my @got = eval { $code->() };
    my $err = $@;
    chdir $was or Carp::croak("Cannot chdir back to $was: $!");
    die $err if $err;
    return @got;
}

# Whether a file relative to the root is Perl: by its name, or by a #! line
# that names perl.
sub _is_perl {
    my ( $self, $rel ) = @_;
    return 1 if $rel =~ m/[.](?:pm|pl|PL|t)\z/;
    return ( _first_line( File::Spec->catfile( $self->{root}, $rel ) ) // q{} ) =~ m/\A#!.*\bperl/;
}

# The nearest directory, from $dir upwards, that holds a distribution.
sub _find_root {
    my ($dir) = @_;

    my ( $volume, $directories ) = File::Spec->splitpath( $dir, 1 );
    my @dirs = File::Spec->splitdir($directories);
    while (@dirs) {
        my $candidate = File::Spec->catpath( $volume, File::Spec->catdir(@dirs), q{} );
        return Cwd::abs_path($candidate) if grep { -e File::Spec->catfile( $candidate, $_ ) } @DIST_MARKERS;
        pop @dirs;
    }
    return;
}

sub _default_cache_dir {
    my $base = $ENV{XDG_CACHE_HOME} || ( $ENV{HOME} && File::Spec->catdir( $ENV{HOME}, '.cache' ) ) or return;
    return File::Spec->catdir( $base, $CACHE_NAME );
}

# $file relative to the root, or undef when it is not under the root.  A
# relative $file is relative to $base.  Only the directory has to exist, so
# that a file which was deleted still has a name.
sub _relative {
    my ( $self, $file, $base ) = @_;

    my $abs = File::Spec->rel2abs( $file, $base );
    my ( $volume, $dirs, $name ) = File::Spec->splitpath($abs);
    my $dir = Cwd::abs_path( File::Spec->catpath( $volume, $dirs, q{} ) ) // return;

    my $rel = File::Spec->abs2rel( File::Spec->catfile( $dir, $name ), $self->{root} );
    return if File::Spec->file_name_is_absolute($rel) || ( File::Spec->splitdir($rel) )[0] eq File::Spec->updir();
    return $rel;
}

# The git blob id of a file relative to the root, or undef when it cannot be
# read.  Kept until the next refresh or diff.
sub _blob {
    my ( $self, $rel ) = @_;

    return $self->{blob}{$rel} if exists $self->{blob}{$rel};
    return $self->{blob}{$rel} = _git_blob( _read( File::Spec->catfile( $self->{root}, $rel ) ) );
}

# The id git gives a file with this content, which is also what a diff from git
# names it by.
sub _git_blob {
    my ($content) = @_;
    return if !defined $content;
    return Digest::SHA::sha1_hex( 'blob ' . length($content) . "\0" . $content );
}

# The bytes of a file, or undef when it is not a file that can be read.
sub _read {
    my ($path) = @_;
    return if !-e $path || -d _;
    return eval { File::Slurper::read_binary($path) };
}

# Whether a record can be used at all, and whether each file it names, other
# than those in %$except, is as it was when the record was made.
sub _record_holds {
    my ( $self, $record, $except ) = @_;

    return if ref $record ne 'HASH' || ref $record->{loaded} ne 'HASH' || !%{ $record->{loaded} };
    foreach my $file ( grep { !$except->{$_} } keys %{ $record->{loaded} } ) {
        my $now = $self->_blob($file) // return;
        return if $now ne $record->{loaded}{$file};
    }
    return 1;
}

# Runs each test under coverage, $self->{jobs} at a time, and returns a record
# for each, keyed by test.
sub _run_tests {
    my ( $self, @queue ) = @_;

    my ( %running, %records );
    while ( @queue || %running ) {
        while ( @queue && keys %running < $self->{jobs} ) {
            my $test = shift @queue;
            my $tmp  = File::Temp->newdir();
            $running{ $self->_spawn( $test, $tmp->dirname() ) } = [ $test, $tmp ];
        }

        my $pid = waitpid -1, 0;
        last if $pid < 0;

        # Some other child of whoever called us.
        my $job = delete $running{$pid} or next;
        $records{ $job->[0] } = $self->_record( $job->[0], $job->[1]->dirname() );
    }
    return \%records;
}

# Starts one test under coverage, silently, and returns its pid.  Devel::Cover
# writes to cover_db under $tmp, and the recorder to loaded.
sub _spawn {
    my ( $self, $test, $tmp ) = @_;

    my $loaded = File::Spec->catdir( $tmp, 'loaded' );
    mkdir $loaded or Carp::croak("Cannot make $loaded: $!");

    my @lib  = ( ( map { File::Spec->rel2abs( $_, $self->{root} ) } @{ $self->{lib} } ), _split_path( $ENV{PERL5LIB} ), $OWN_LIB );
    my @opt  = ( $self->_cover_switch( File::Spec->catdir( $tmp, 'cover_db' ) ), '-MPerl::Tests::Covering::Recorder' );
    my @perl = ( $^X, $self->_taint_switches( $test, \@lib, \@opt ), $test );

    my $pid = fork // Carp::croak("Cannot fork to run $test: $!");
    return $pid if $pid;

    # From here on, this is the child, and it must not return into the caller's
    # code: every way out is exec or _exit.
    my $null = File::Spec->devnull();
    chdir $self->{root} or POSIX::_exit($EXEC_FAILED);
    open STDIN,  '<',  $null    or POSIX::_exit($EXEC_FAILED);
    open STDOUT, '>',  $null    or POSIX::_exit($EXEC_FAILED);
    open STDERR, '>&', \*STDOUT or POSIX::_exit($EXEC_FAILED);

    # A perl that a tainted test starts is not tainted, and reads these.
    $ENV{PERL5LIB}                   = join $Config::Config{path_sep}, @lib;
    $ENV{PERL5OPT}                   = join q{ }, @opt, grep { defined && length } $ENV{PERL5OPT};
    $ENV{PERL_TESTS_COVERING_LOADED} = $loaded;
    $ENV{HARNESS_ACTIVE}             = 1;

    # A list exec of perl itself, with no shell in between.
    { no warnings 'exec'; exec {$^X} @perl }    ## no critic (ProhibitShellDispatch)
    POSIX::_exit($EXEC_FAILED);
}

# The switches that go before the test on perl's command line: none, unless its
# #! line asks for taint.  Then they are the taint switch, and PERL5LIB and
# PERL5OPT as switches, which is what prove does.
sub _taint_switches {
    my ( $self, $test, $lib, $opt ) = @_;

    my $taint = TAP::Parser::SourceHandler::Perl->get_taint( _first_line( File::Spec->catfile( $self->{root}, $test ) ) ) // return;
    return ( "-$taint", ( map { "-I$_" } @$lib ), @$opt, Text::ParseWords::shellwords( $ENV{PERL5OPT} // q{} ) );
}

# The first line of a file, or undef.
sub _first_line {
    my ($path) = @_;

    open my $fh, '<', $path or return;
    my $line = <$fh>;
    close $fh;
    return $line;
}

# The directories in a PATH-like list, without the empty ones.
sub _split_path {
    my ($list) = @_;
    return grep { length } split m/\Q$Config::Config{path_sep}\E/, $list // q{};
}

# The -MDevel::Cover switch for one run.  Devel::Cover splits its options on
# commas, and perl splits PERL5OPT on whitespace, so either in the root is
# written as a \x escape, which the pattern still matches.  A relative name is
# relative to the root, where the run starts, and is sorted out from the rest
# in _files_in_run.
sub _cover_switch {
    my ( $self, $db ) = @_;

    ( my $root = quotemeta $self->{root} ) =~ s/\\([,\s])/sprintf '\\x%02x', ord $1/ge;
    Carp::croak("Cannot put a temporary directory with a comma or a space in it in PERL5OPT: $db") if $db =~ m/[,\s]/;
    return "-MDevel::Cover=-db,$db,-silent,1,-coverage,statement,-select,^(?!/)|^$root/";
}

# The record of one run: the blob of every file of the distribution that the
# test loaded, by what Devel::Cover and the recorder say, and of the test
# itself; the lines of each that ran; and under versions, the layout of each
# file as it was, keyed by blob.
sub _record {
    my ( $self, $test, $tmp ) = @_;

    my $covered = $self->_files_covered( File::Spec->catdir( $tmp, 'cover_db' ) );
    my %loaded  = map { $_ => 1 } $test, keys %$covered, $self->_files_recorded( File::Spec->catdir( $tmp, 'loaded' ) );

    my %record = ( loaded => {}, executed => {}, versions => {} );
    foreach my $rel ( keys %loaded ) {
        my $content = _read( File::Spec->catfile( $self->{root}, $rel ) ) // next;
        my $blob    = $record{loaded}{$rel} = _git_blob($content);

        # Lines are only good for the content they were counted in, and the
        # file may have changed while the test ran.
        my $run    = $covered->{$rel}{ Digest::MD5::md5_hex($content) } or next;
        my $layout = _layout($content)                                  or next;
        $record{executed}{$rel}  = [ sort { $a <=> $b } keys %{ $run->{executed} } ];
        $record{versions}{$blob} = { %$layout, statements => $run->{statements} };
    }
    return \%record;
}

# The files of the distribution that Devel::Cover saw in each run of one
# database, keyed by file and then by Devel::Cover's digest of the content:
# the lines that hold a statement, and those of them that ran.  It reads the
# counts of each run as loaded, because the public runs() goes through
# cover(), which also needs the working directory the run had.
sub _files_covered {
    my ( $self, $db ) = @_;

    my %files;
    foreach my $dir ( _entries( File::Spec->catdir( $db, 'runs' ) ) ) {
        my $runs = eval { Devel::Cover::DB->new( db => $dir ) } or next;
        foreach my $run ( grep { ref eq 'HASH' } values %{ $runs->{runs} // {} } ) {
            my $cwd = $run->{dir} // $self->{root};
            foreach my $name ( keys %{ $run->{count} // {} } ) {
                my $rel    = $self->_distribution_file( $name, $cwd ) // next;
                my $digest = $run->{digests}{$name}                   // next;
                my $lines  = _statement_lines( $db, $digest )         // next;
                my $counts = $run->{count}{$name}{statement}          // [];

                my $file = $files{$rel}{$digest} //= { statements => [ List::Util::uniqnum( sort { $a <=> $b } grep { defined } @$lines ) ], executed => {} };
                $file->{executed}{ $lines->[$_] } = 1 for grep { $counts->[$_] && defined $lines->[$_] } 0 .. $#$counts;
            }
        }
    }
    return \%files;
}

# The line of each statement in the file Devel::Cover knows by $digest, in the
# order of its counts.  Read from its structure file directly, because
# Devel::Cover::DB::Structure->read resolves the file against the working
# directory and deletes the structure of a file that changed.
sub _statement_lines {
    my ( $db, $digest ) = @_;

    my $structure = eval { Devel::Cover::DB::IO->new->read( File::Spec->catfile( $db, 'structure', $digest ) ) };
    return ref $structure eq 'HASH' && ref $structure->{statement} eq 'ARRAY' ? $structure->{statement} : undef;
}

# The files of the distribution in each list that the recorder wrote.  A
# relative name in %INC is relative to wherever the require happened, which
# the recorder cannot know, so it is taken as relative to the root, where the
# run started.
sub _files_recorded {
    my ( $self, $loaded ) = @_;

    my @files;
    foreach my $list ( _entries($loaded) ) {
        my @names = eval { File::Slurper::read_lines($list) } or next;
        push @files, grep { defined } map { $self->_distribution_file( $_, $self->{root} ) } @names;
    }
    return @files;
}

# The paths in a directory, or none when it cannot be read.
sub _entries {
    my ($dir) = @_;

    opendir my $dh, $dir or return;
    my @entries = map { File::Spec->catfile( $dir, $_ ) } grep { !m/\A[.]/ } readdir $dh;
    closedir $dh;
    return @entries;
}

# $name, which a run loaded from $cwd, relative to the root, or nothing when it
# is not a file of the distribution.
sub _distribution_file {
    my ( $self, $name, $cwd ) = @_;

    my $rel = $self->_relative( $name, $cwd ) // return;

    # A test run after `make` loads the copy in blib.
    $rel =~ s{\Ablib/(?:lib|arch)/}{lib/} or $rel =~ s{\Ablib/script/}{bin/};
    my $path = File::Spec->catfile( $self->{root}, $rel );
    return -e $path && !-d _ ? $rel : undef;
}

# Each file a unified diff changes: its old and new paths as the diff names
# them, or undef for /dev/null; the blob ids from its index line, which may be
# abbreviated; and its blocks, which L</THE MAP> describes.
sub _parse_diff {
    my ($diff) = @_;

    # Where the parse is: the changes so far, and in the hunk being read, the
    # next line on each side and how many are left.
    my %at = ( changes => [], old_left => 0, new_left => 0 );
    foreach my $line ( split m/\r?\n/, $diff // q{} ) {
        if ( $at{old_left} || $at{new_left} ) {
            _hunk_line( \%at, $line );
            next;
        }
        _header_line( \%at, $line );
    }
    return @{ $at{changes} };
}

# One line of a hunk: removed, added, or the same on both sides.
sub _hunk_line {
    my ( $at, $line ) = @_;

    my $mark = substr $line, 0, 1;
    if ( $mark eq q{-} || $mark eq q{+} ) {
        $at->{block} //= _new_block( $at->{changes}[-1], $at->{old} );
        my $side = $mark eq q{-}  ? 'old'     : 'new';
        my $kind = $side eq 'old' ? 'deleted' : 'added';
        push @{ $at->{block}{$kind} }, $at->{$side}++;
        push @{ $at->{block}{"${kind}_text"} }, substr $line, 1;
        $at->{"${side}_left"}--;
        return;
    }
    return if $mark eq q{\\};

    undef $at->{block};
    $at->{$_}++ for qw{old new};
    $at->{"${_}_left"}-- for qw{old new};
    return;
}

# One line outside a hunk.
sub _header_line {
    my ( $at, $line ) = @_;

    my $changes = $at->{changes};
    if ( $line =~ m/\Adiff --git (\S+) (\S+)\z/ ) {
        push @$changes, { git => 1, old => _diff_path( $1, 1 ), new => _diff_path( $2, 1 ), blocks => [] };
        return;
    }
    if ( $line =~ m/\Adiff / || ( $line =~ m/\A--- / && ( !@$changes || @{ $changes->[-1]{blocks} } ) ) ) {
        push @$changes, { blocks => [] };
    }

    my $change = $changes->[-1] or return;
    if ( $line =~ m/\Aindex ([0-9a-f]+)[.][.]([0-9a-f]+)/ ) {
        @{$change}{qw{old_blob new_blob}} = ( $1, $2 );
    }
    elsif ( my ( $moved, $marked, $path ) = $line =~ m/\A(?:(?:rename|copy) (from|to)|(---|[+]{3})) (.+)\z/ ) {
        my $side = ( $moved // $marked ) =~ m/\A(?:from|---)\z/ ? 'old' : 'new';
        $change->{$side} = _diff_path( $path, $marked && $change->{git} );
    }
    elsif ( $line =~ m/\A\@\@ -(\d+)(?:,(\d+))? [+](\d+)(?:,(\d+))? \@\@/ ) {
        @{$at}{qw{old old_left new new_left}} = ( $1, $2 // 1, $3, $4 // 1 );

        # An empty side is numbered by the line before it.
        $at->{$_}++ for grep { !$at->{"${_}_left"} } qw{old new};
        undef $at->{block};
        $change->{hunks}++;
    }
    return;
}

sub _new_block {
    my ( $change, $at ) = @_;
    my $block = { at => $at, deleted => [], added => [], deleted_text => [], added_text => [] };
    push @{ $change->{blocks} }, $block;
    return $block;
}

# A path as a diff writes it, unquoted, without git's a/ or b/ in front when
# $git, and without the date that diff -u puts after a tab.  Undef for
# /dev/null.
sub _diff_path {
    my ( $path, $git ) = @_;

    if ( $path =~ m/\A"(.*)"\z/s ) {
        my %escape = ( n => "\n", t => "\t", q{"} => q{"}, q{\\} => q{\\} );
        $path = $1 =~ s{\\([0-7]{3}|.)}{length $1 == 3 ? chr oct $1 : $escape{$1} // $1}gser;
    }
    else {
        $path =~ s/\t.*\z//s;
    }
    return                    if $path eq '/dev/null';
    $path =~ s{\A[abciow]/}{} if $git;
    return $path;
}

# A change from _parse_diff with its paths relative to the root.  A path
# outside the root is undef, like one that is not there.
sub _resolve_change {
    my ( $self, $change, $cwd ) = @_;

    my %resolved = %$change;
    $resolved{$_} = defined $change->{$_} ? $self->_relative( $change->{$_}, $cwd ) : undef for qw{old new};
    return \%resolved;
}

# Whether a change could reach a test, going by the test's record and the
# layouts of the files it loaded.  It reaches the test when it cannot tell.
sub _change_reaches {
    my ( $self, $change, $record, $versions ) = @_;

    # A file that is new in the change was not loaded before it.
    my $old  = $change->{old}          // return 0;
    my $blob = $record->{loaded}{$old} // return 0;

    # Every test that loaded a file breaks when it is deleted or moved.
    return 1 if ( $change->{new} // q{} ) ne $old;
    return 1 if !$change->{hunks} || !defined $change->{old_blob} || index( $blob, $change->{old_blob} ) != 0;
    my $version = $versions->{$blob};
    return 1 if !$version;

    my %old_inert = map { $_ => 1 } @{ $version->{inert} };
    my %new_inert = map { $_ => 1 } @{ $self->_new_inert($change) };
    my ( @lines, @gaps );
    foreach my $block ( @{ $change->{blocks} } ) {
        my @code = grep { !$old_inert{$_} } @{ $block->{deleted} };
        push @lines, @code;

        # Code in place of nothing but comments, blank lines and POD goes in
        # between the lines around it.
        push @gaps, $block->{at} if !@code && grep { !$new_inert{$_} } @{ $block->{added} };
    }
    return _touches( $version, $record->{executed}{$old}, \@lines, \@gaps );
}

# The inert lines of the new side of a change, when the file in the work tree
# is that new side.  Otherwise none, and every added line counts as code.
sub _new_inert {
    my ( $self, $change ) = @_;

    my $new = $change->{new} // return [];
    return [] if !defined $change->{new_blob} || index( $self->_blob($new) // q{}, $change->{new_blob} ) != 0;
    my $layout = _layout( _read( File::Spec->catfile( $self->{root}, $new ) ) ) or return [];
    return $layout->{inert};
}

# Whether a test that ran @$executed of the lines of a file, in the version
# that $version describes, could be affected by a change to @$lines, or by
# code added before each of @$gaps.  A changed line is judged by the innermost
# statement that holds it: by its first line when Devel::Cover counted a
# statement there, and otherwise by any statement inside it.  Added code is
# judged by the innermost statement around it.  When there is no such
# statement, or no statement inside it was counted, the answer is yes: that is
# code which runs when the file is loaded, or code nothing measured.
sub _touches {
    my ( $version, $executed, $lines, $gaps ) = @_;

    return 1 if ref $version ne 'HASH' || ref $executed ne 'ARRAY';
    my %ran   = map { $_ => 1 } @$executed;
    my %known = map { $_ => 1 } @{ $version->{statements} };

    foreach my $range ( ( map { [ $_, $_, 0 ] } @$lines ), ( map { [ $_ - 1, $_, 1 ] } @$gaps ) ) {
        my ( $from, $to, $is_gap ) = @$range;
        my $span     = _innermost( $version->{spans}, $from, $to ) or return 1;
        my @measured = !$is_gap && $known{ $span->[0] } ? ( $span->[0] ) : grep { $known{$_} } $span->[0] .. $span->[1];
        return 1 if !@measured || grep { $ran{$_} } @measured;
    }
    return 0;
}

# The innermost span that holds every line from $from to $to, or undef.
sub _innermost {
    my ( $spans, $from, $to ) = @_;

    my $best;
    foreach my $span ( grep { $_->[0] <= $from && $_->[1] >= $to } @$spans ) {
        $best = $span if !$best || $span->[0] > $best->[0] || ( $span->[0] == $best->[0] && $span->[1] < $best->[1] );
    }
    return $best;
}

# Where the statements of some perl are, as [ first line, last line ], and
# which lines are inert: blank, a comment and nothing else, or POD.  Undef
# when PPI cannot read it.  A statement with a heredoc ends where the last of
# its bodies does.  A line of a string or of a heredoc body is never inert,
# since changing it changes what the code does.
sub _layout {
    my ($content) = @_;

    my $doc   = _ppi($content) or return;
    my @lines = split qq{\n}, $content, -1;

    # What PPI calls a statement inside parentheses or brackets is part of the
    # statement around it, and Devel::Cover counts that one.
    my @statements = grep { my $parent = $_->parent(); !$parent->isa('PPI::Structure') || $parent->isa('PPI::Structure::Block') } @{ $doc->find('PPI::Statement') || [] };

    my @spans;
    foreach my $statement (@statements) {
        my $end = _last_line( $statement->last_token() );
        foreach my $heredoc ( @{ $statement->find('PPI::Token::HereDoc') || [] } ) {
            my @body = $heredoc->heredoc();
            $end = List::Util::max( $end, $heredoc->line_number() + @body + 1 );
        }
        push @spans, [ $statement->first_token()->line_number(), $end ];
    }

    my %inert;
    foreach my $token ( $doc->tokens() ) {
        my @span = ( $token->line_number() .. _last_line($token) );
        if ( $token->isa('PPI::Token::Pod') ) {
            $inert{$_} = 1 for @span;
        }
        elsif ( $token->isa('PPI::Token::Whitespace') || $token->isa('PPI::Token::Comment') ) {
            $inert{$_} = 1 for grep { ( $lines[ $_ - 1 ] // q{} ) =~ m/\A\s*(?:#.*)?\z/ } @span;
        }
    }
    return { spans => \@spans, inert => [ sort { $a <=> $b } keys %inert ] };
}

# The first line of each sub named $name, in any package, in some perl.
sub _sub_lines {
    my ( $content, $name ) = @_;

    my $doc = _ppi($content) or return;
    return map { $_->line_number() } grep { ( $_->name() // q{} ) =~ m/\A(?:.*::)?\Q$name\E\z/ } @{ $doc->find('PPI::Statement::Sub') || [] };
}

sub _ppi {
    my ($content) = @_;
    return if !defined $content;
    my $doc = PPI::Document->new( \$content ) or return;
    $doc->index_locations();
    return $doc;
}

# The last line a token is on.
sub _last_line {
    my ($token) = @_;
    my $content = $token->content();
    return $token->line_number() + ( $content =~ tr/\n// ) - ( $content =~ m/\n\z/ ? 1 : 0 );
}

sub _cache_path {
    my ($self) = @_;
    return if !defined $self->{cache_dir};
    return File::Spec->catfile( $self->{cache_dir}, Digest::SHA::sha1_hex( $self->{root} ) . '.json.gz' );
}

# The format of the cache, the stamp of this file, the perl, and the
# configuration a run depends on.  Records made under another key are stale.
sub _cache_key {
    my ($self) = @_;

    my @st = stat __FILE__;
    return join q{/}, $CACHE_FORMAT, join( q{:}, @st[ 0, 1, 7, 9 ] ), $^X, $], join( q{,}, @{ $self->{tests} } ), join( q{,}, @{ $self->{lib} } );
}

# The records in the cache, under tests and keyed by test, and the layouts of
# the files they name, under versions and keyed by blob.  Both are empty when
# there is no cache to use.
sub _read_cache {
    my ($self) = @_;

    my $path = $self->_cache_path() or return {};

    # A cache that is not there fails to read, like one that is unreadable.
    my $cache = eval {
        my $gz = File::Slurper::read_binary($path);
        IO::Uncompress::Gunzip::gunzip( \$gz => \my $json ) or return;
        Cpanel::JSON::XS->new->decode($json);
    };
    my $usable = ref $cache eq 'HASH' && ( $cache->{key} // q{} ) eq $self->_cache_key() && ref $cache->{tests} eq 'HASH' && ref $cache->{versions} eq 'HASH';
    return $usable ? $cache : { tests => {}, versions => {} };
}

# Replaces the file whole, so a reader never sees half of it.  Keeps only the
# versions that some record names.
sub _write_cache {
    my ( $self, $records, $versions ) = @_;

    my $path  = $self->_cache_path() or return;
    my %named = map { $_ => $versions->{$_} } grep { $versions->{$_} } map { values %{ $_->{loaded} } } values %$records;
    my $json  = Cpanel::JSON::XS->new->canonical->encode( { key => $self->_cache_key(), root => $self->{root}, tests => $records, versions => \%named } );

    # The root goes in the gzip header too, so that _prune_cache can read it
    # without decompressing the file.
    IO::Compress::Gzip::gzip( \$json => \my $gz, Comment => $self->{root} ) or return;

    File::Path::make_path( $self->{cache_dir}, { error => \my $errors } );
    return if @$errors;

    my $ok = eval { File::Slurper::Temp::write_binary( $path, $gz ); 1 };
    _prune_cache( $self->{cache_dir} ) if $ok;
    return $ok;
}

# Removes the cache of each root that is gone, such as a deleted checkout.  A
# file whose header cannot be read is removed too, since nothing can read it.
sub _prune_cache {
    my ($cache_dir) = @_;

    opendir( my $dh, $cache_dir ) or return;
    my @names = grep { m/$CACHE_FILE_RX/ } readdir $dh;
    closedir $dh;

    foreach my $name (@names) {
        my $file = File::Spec->catfile( $cache_dir, $name );
        my $root = _cached_root($file);
        next if defined $root && -d $root;
        unlink $file;
    }
    return;
}

# The root that a cache file is for, from its gzip header, or undef.
sub _cached_root {
    my ($file) = @_;

    my $z      = IO::Uncompress::Gunzip->new($file) or return;
    my $header = $z->getHeaderInfo();
    $z->close();
    return ref $header eq 'HASH' ? $header->{Comment} : undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Tests::Covering - Which tests run the file you just changed, from coverage kept on disk.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Perl::Tests::Covering;

    my $covering = Perl::Tests::Covering->new( root => '/src/My-Dist' );

    # The tests that load a file.
    my @tests = $covering->tests_covering('lib/My/Dist.pm');

    # The tests that ran the lines a change touches.
    my @chosen = $covering->tests_covering_diff( scalar `git diff --cached` );

    # The tests that ran a sub, and the files a test loaded.
    my @callers = $covering->tests_covering_sub( 'lib/My/Dist.pm', 'frobnicate' );
    my @files   = $covering->files_covered_by('t/frobnicate.t');

=head1 DESCRIPTION

You change one module, and you want to run the tests that exercise it and not
the rest.  This module tells you which tests those are.

It runs each test of a distribution once under L<Devel::Cover>, and records
every file of the distribution that the test loaded.  A later question about a
file is answered from that record.  A test is run again only when the record
for it is stale: when the test is new, or when the test or any file it loaded
changed since the record was made.

It also records which lines of each file each test ran.  So it can answer at
a finer grain: which tests ran a given sub, and which tests ran the lines that
a diff changes.

The answer is meant for a git pre-commit hook.  Hand it the files or the diff
of a changeset, and run what comes back.  L<tests-covering> is the command
line for it, and has the hooks:

    tests-covering lib/My/Dist.pm | xargs --no-run-if-empty prove -l

=head2 WHAT COUNTS AS COVERING

A test covers a file when the file was loaded during a run of the test.  That
includes the test itself, helpers under F<t/lib>, and scripts in F<bin/> that
the test runs in a child perl.  A module the test loads but never calls still
counts.  A syntax error in it fails the test all the same.

Only perl code is tracked.  A test that reads a template, a fixture or a
configuration file is not reported as covering that file.

=head2 WHEN A RECORD GOES STALE

A record holds the git blob id of each file the test loaded, which is the
SHA-1 that git gives the content.  The record is stale when any of those ids
changed, or when any of those files is gone.  A test that loads a new module
can only do so because a file it already loaded changed, so the new module
needs no id of its own.

The exception is code that finds modules at run time without naming them, for
example L<Module::Pluggable>.  A new plugin of that kind does not make a record
stale.  Neither does a change to the environment, such as C<AUTHOR_TESTING>,
that changes what a test runs.  L</THE MAP> is how a distribution says which
tests a new plugin reaches.

=head2 A FILE THAT CHANGED OR IS GONE

L</tests_covering> reports a test that covers the file now, and also a test
that covered it before its records were brought up to date.  So a module that
you deleted is still reported as covered by the tests that used it, which are
the tests that the deletion breaks.

=head2 CHOOSING TESTS FOR A CHANGE

L</tests_covering_diff> chooses tests by the lines a diff changes.  The
numbers in a diff are the lines of each file before the change.  So it reads
the records as they are and runs nothing, and a record only helps when it was
made of the file as the diff's C<index> line names it.  Bring the records up
to date after each commit, with L</refresh>, and the next diff finds them.
L<tests-covering> has a post-commit hook that does that.

A test is chosen when any of these is true:

=over 4

=item *

it has no record, or it is in the diff;

=item *

a file it loaded changed since its record, and the diff does not say how;

=item *

the diff deletes or moves a file it loaded, or changes the file without a
hunk, such as its mode;

=item *

its record of a file in the diff is of another version than the diff's old
side, or the diff has no C<index> line to say which;

=item *

it ran a line that the diff changes, or code the diff adds goes in among lines
it ran.

=back

The last rule needs to know where each statement is, and PPI says that.  A
changed line counts as run when the test ran the statement that holds it, so
a change to the second line of a statement over three lines counts.  So does a
change to the brace that closes a block the test ran.  Code added inside a sub
counts as run by the tests that ran that sub.  Blank lines, comments and POD
count for nothing, in the old version as the record has it, and in the new one
when the file in the work tree is what the diff made it.  A string or a
heredoc body that looks like a comment is still code.

Some code runs whenever the file is loaded, and Devel::Cover does not count it
in a module: the code at the top of the file, and a C<package> line.  A change
there, or code added between two subs, chooses every test that loads the file.
So does adding a whole sub, since a new C<import>, C<DESTROY> or method can
change what code that never called it does.

Choosing by line trusts that each changed file still compiles.  A syntax error
in a sub that no test runs chooses no tests, and still breaks every test that
loads the file.  L<tests-covering> says how to have the hook check that too.

=head2 THE MAP

Some files reach a test without the test loading them.  A template that a
test renders is one: the test reads it, and Perl does not record a read.
Watching which files a test opens does not help either, as a template engine
with a cache of compiled templates can read only its cache.  A script that a
test runs under another perl is a second kind, since that perl cannot load
L<Perl::Tests::Covering::Recorder>.  Only the distribution knows which tests
reach such files, and the map is how it says so.

The map is a code reference.  It is called once for each path in the question
that is not a test and that no record names as loaded:

    use Perl::Tests::Covering qw{NO_TESTS};

    sub {
        my ( $path, $change ) = @_;
        return 't/templates.t'  if $path =~ m{\Atemplates/};
        return 'lib/Plugins.pm' if $path =~ m{\Alib/Plugin/.+[.]pm\z};
        return NO_TESTS         if $path =~ m{\Adocs/};
        return;
    }

C<$path> is relative to the root.  C<$change> is the change to it from a diff,
as below, or undef when the question is L</tests_covering>.  The map runs with
the root as the working directory, and with the library directories at the
front of C<@INC>, so it can ask the distribution's own modules.  When it dies,
the question dies.

It returns paths relative to the root:

=over 4

=item *

a test, which is chosen;

=item *

any other file, which stands in for C<$path>: each test that loaded that file
is chosen, whatever lines the change touched;

=item *

C<NO_TESTS>, which says that C<$path> reaches no test;

=item *

nothing, which leaves C<$path> unexplained.

=back

C<NO_TESTS> is exported on request, and is the empty string, so a map can
return C<q{}> instead.

A path counts as explained when the map chooses a test for it, or says
C<NO_TESTS>.  A stand-in that no test loads chooses nothing, so it leaves the
path unexplained.  That happens when the stand-in is new, for example a
plugin that comes in the same diff as its template.  A path that is neither a
test nor a file under the root is dropped with a warning, so a mistake in the
map leaves the path unexplained, and does not explain it away.

A path that is unexplained chooses no test, unless the C<unexplained> option
is C<all>, which chooses every test.

A Perl file that a diff adds is asked about too, since code that finds modules
at run time, such as L<Module::Pluggable>, loads it with nothing in the diff
using it.  When the map says nothing about it, it counts as explained: the
files that use it are usually in the diff, and a distribution without plugins
does not run every test each time it adds a module.

The map answers when the question is asked, so it adds nothing to the cache,
and a change to it makes no record stale.

The change is a hash:

=over 4

=item C<old>, C<new>

The path before and after, relative to the root.  Undef for a file the diff
adds or deletes, and for a path outside the root.

=item C<old_blob>, C<new_blob>

The git blob ids from the C<index> line, which may be abbreviated, or undef.

=item C<hunks>

How many hunks the diff has for the file.

=item C<blocks>

Each run of removed and added lines, as a hash: C<at>, the old line the run
starts at, or that the added lines go in before when nothing is removed;
C<deleted>, the old line numbers removed, and C<deleted_text>, their text;
C<added>, the new line numbers added, and C<added_text>, their text.  The text
has no line end.

=back

=head2 THE CACHE ON DISK

The records of a distribution are one file of gzipped JSON, in
F<$XDG_CACHE_HOME/perl-tests-covering>, or F<~/.cache/perl-tests-covering> when
C<XDG_CACHE_HOME> is not set.  The file name is the SHA-1 of the root.  The
root is also in the gzip header, so that the cache of a root which is gone can
be removed without reading the whole file.  That removal happens each time a
cache is written.

Beside the records, the cache keeps the layout of each version of a file that
a record names, keyed by blob id: the lines that Devel::Cover counts a
statement on, where PPI finds each statement, and which lines are blank,
comments or POD.

The cache also records the stamp of this module's file, the version of perl,
and the configured test and library directories.  If any of them changes, all
of the records are stale.

A cache that cannot be read is treated as empty.  A cache that cannot be
written costs the next run the coverage runs again, and nothing else.

=head2 RUNNING THE TESTS

Each stale test runs under C<perl -MDevel::Cover> with the root as its working
directory, with C<HARNESS_ACTIVE> set, and with the library directories added
to C<PERL5LIB>.  C<Devel::Cover> goes in C<PERL5OPT>, so a perl that the test
starts is covered too.

L<Perl::Tests::Covering::Recorder> goes in C<PERL5OPT> as well, and writes
down C<%INC> as each perl exits.  Devel::Cover does not record a module whose
code is all at the top of the file, and the recorder does.

A test with C<-T> or C<-t> on its C<#!> line runs with that switch, as
C<prove> runs it.  Perl ignores C<PERL5LIB> and C<PERL5OPT> under taint, so
for such a test they also go on the command line, as C<-I> and C<-M>
switches.

Standard input, output and error go to the null device.  A test that fails
still has its coverage recorded, because the question is what it ran, not
whether it passed.

Each run writes to a temporary coverage database of its own, and the database
is deleted after it is read.  Nothing is written to F<cover_db>.  The lines a
test ran are only kept for a file whose content, when the run is read, is what
Devel::Cover counted.  A file that changed while the test ran has no lines in
the record, and a question about its lines chooses the test.

=head2 COMPARED WITH Devel::CoverX::Covered

L<Devel::CoverX::Covered|https://metacpan.org/pod/Devel::CoverX::Covered> answers the same question from a F<cover_db> that you
make yourself: you run the whole suite under Devel::Cover, then run C<covered
runs> before C<cover> merges the runs away.  This comparison is of its release
0.016, run on the same small distribution as this module.

It does more in two ways.  It reports how often each sub ran, with C<covered
subs>.  And it reads a F<cover_db> from any run of the suite, such as one in CI,
and editors reach it through L<Devel::PerlySense|https://metacpan.org/pod/Devel::PerlySense> and vim-covered.  This
module runs the tests itself.

This module does more in five ways.

=over 4

=item *

It keeps its answers current.  Devel::CoverX::Covered has no idea of a stale
record.  After a test changes, it gives the old answer until the whole suite
runs again under Devel::Cover, and a deleted test stays in its answers, as its
own documentation says.  This module runs again only the tests whose files
changed.

=item *

It reports the test.  Devel::CoverX::Covered takes each perl process as a test,
by its C<$0>.  So when a test runs F<bin/foo> in a child perl, it reports
F<bin/foo> as the test that covers the modules F<bin/foo> uses, and does not
report the test.

=item *

It counts every file a test loads.  Devel::CoverX::Covered counts a file only
when a named sub in it ran.  So it reports no test for a module that a test
loads and never calls, for a module that is all code at the top of the file,
for a script without subs, or for the test itself.

=item *

It chooses by the lines of a diff.  Devel::CoverX::Covered chooses by file or
by sub, and lists choosing by line as not done.

=item *

It can be told about files that no test loads, such as templates, through
L</THE MAP>, and it can run every test for a change that nothing explains.
Devel::CoverX::Covered knows only the files Devel::Cover measured, and chooses
no test for any other.

=back

Both answer the question turned around, which files a test covers, and both
choose by sub.  Devel::CoverX::Covered needs C<Moose>, C<DBD::SQLite>,
C<DBIx::Simple>, C<SQL::Abstract>, C<Path::Class> and C<File::chdir>.

=head1 CONSTRUCTOR

=head2 new

    my $covering = Perl::Tests::Covering->new(%options);

Every option is optional.

=over 4

=item C<root>

The root of the distribution.  The default is the nearest directory, from the
current directory upwards, that holds a F<dist.ini>, F<Makefile.PL>,
F<Build.PL>, F<cpanfile>, F<META.json> or F<.git>.  It dies when there is none.

=item C<tests>

The directories, relative to the root, that hold the tests.  Every F<.t> file
under them is a test.  The default is C<['t']>.

=item C<lib>

The directories, relative to the root, that go in C<PERL5LIB> for each run.
The default is C<['lib']>, like C<prove -l>.

=item C<jobs>

How many tests run at once.  The default is 1.

=item C<cache_dir>

Where the cache is kept.  The default is described in L</THE CACHE ON DISK>.

=item C<map>

What says which tests reach a file that no test loads: a code reference, or
the name of a Perl file that returns one.  L</THE MAP> says what it is called
with and what it returns.  The default is F<.tests-covering-map.pl> in the
root, when there is one.  Pass C<undef> for no map.  It dies when the file
does not compile or does not return a code reference.

=item C<unexplained>

What to do about a file in the question that neither a record nor the map
explains: C<none>, the default, chooses no test for it, and C<all> chooses
every test.

=back

=head1 METHODS

=head2 root

The absolute path of the root, with symbolic links resolved.

=head2 tests

Every test of the distribution, relative to the root, sorted.

=head2 refresh

    my @ran = $covering->refresh();

Brings the records up to date: runs each test that is stale under coverage,
drops the record of each test that is gone, and writes the cache when anything
changed.  Returns the tests it ran, relative to the root.

L</tests_covering> calls this for you.

=head2 tests_covering

    my @tests = $covering->tests_covering(@files);

The tests that cover any of C<@files>, relative to the root, sorted.  A file
that is relative is relative to the current directory, as it is on a command
line.  A file outside the root adds nothing.  A file that no test loads adds
what the map and C<unexplained> say, as L</THE MAP> describes.

It calls L</refresh> first, so it can take as long as the stale tests take to
run.  A test is reported when its record from before the refresh, or its record
from after it, says it covers one of the files.  See
L</A FILE THAT CHANGED OR IS GONE>.

=head2 tests_covering_diff

    my @tests = $covering->tests_covering_diff($diff);

The tests that a change could break, relative to the root, sorted.  C<$diff>
is the text of a unified diff from git, such as C<git diff --cached>.  Its
paths are relative to the current directory, which for git is the top of the
work tree.

It does not run anything first.  The line numbers of a diff describe the files
before the change, so the answer has to come from records made of those files.
See L</CHOOSING TESTS FOR A CHANGE>, which also says when it runs a test that
the change may not reach.

=head2 tests_covering_sub

    my @tests = $covering->tests_covering_sub( $file, $name );

The tests that ran any statement of the sub C<$name> in C<$file>, relative to
the root, sorted.  C<$name> matches with or without its package.  It calls
L</refresh> first, and dies when C<$file> has no such sub.

A test whose record has no lines for C<$file> is reported when it loaded the
file at all, as L</tests_covering> would.

=head2 files_covered_by

    my @files = $covering->files_covered_by($test);

The files that C<$test> loaded, relative to the root, sorted: the reverse of
L</tests_covering>.  It calls L</refresh> first.  A test that is not a test of
the distribution covers nothing.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<tests-covering|tests-covering>

=item *

L<Devel::Cover|Devel::Cover>

=item *

L<Perl::Critic::Policy::ProhibitUnusedDefinitions|Perl::Critic::Policy::ProhibitUnusedDefinitions>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-tests-covering/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
