package Build;
use strict;
use warnings;
use base qw( Module::Build );

## no critic (InputOutput::ProhibitBacktickOperators)

our $VERSION = '0.80';

use File::Find;
use File::Spec;
use File::Path;
use Carp qw( croak );

use Build::Constants qw( :all );
use Build::Spec;
use Build::Util qw( slurp trim );

BEGIN {
    my %default = (
        add_pod_author_copyright_license => 0,
        build_monolith                   => 0,
        change_versions                  => 0,
        copyright_first_year             => 0,
        initialization_hook              => q(),
        monolith_add_to_top              => [],
        taint_mode_tests                 => 0,
        vanilla_makefile_pl              => 1,
    );
    foreach my $meth ( keys %default ) {
        __PACKAGE__->add_property( $meth => $default{ $meth } );
    }
}

sub new {
    my $class = shift;
    my %opt   = spec;
    my %def   = DEFAULTS;
    foreach my $key ( keys %def ) {
        $opt{ $key } = $def{ $key } if ! defined $opt{ $key };
    }
    $opt{no_index}            ||= {};
    $opt{no_index}{directory} ||= [];
    push @{ $opt{no_index}{directory} }, NO_INDEX;
    return $class->SUPER::new( %opt );
}

sub create_build_script {
    my $self = shift;
    $self->_add_vanilla_makefile_pl if $self->vanilla_makefile_pl;

    if ( my $hook = $self->initialization_hook ) {
        my $eok = eval $hook;
        croak "Error compiling initialization_hook: $@" if $@;
    }

    return $self->SUPER::create_build_script( @_ );
}

sub ACTION_dist { ## no critic (NamingConventions::Capitalization)
    my $self = shift;
    my $msg  = sprintf q{RUNNING 'dist' Action from subclass %s v%s},
                       ref($self),
                       $VERSION;
    warn "$msg\n";
    my @modules;
    find {
        wanted => sub {
            my $file = $_;
            return if $file !~ m{ [.] pm \z }xms;
            $file = File::Spec->catfile( $file );
            push @modules, $file;
            warn "FOUND Module: $file\n";
        },
        no_chdir => 1,
    }, 'lib';

    $self->_create_taint_mode_tests      if $self->taint_mode_tests;
    $self->_change_versions( \@modules ) if $self->change_versions;
    $self->_build_monolith(  \@modules ) if $self->build_monolith;

    return $self->SUPER::ACTION_dist( @_ );
}

sub ACTION_extratest {
    # Stolen from
    # http://elliotlovesperl.com/2009/11/24/explicitly-running-author-tests
    #
    my($self) = @_;
    $self->depends_on( 'build'    );
    $self->depends_on( 'manifest' );
    $self->depends_on( 'distmeta' );

    $self->test_files( qw< xt > );
    $self->recursive_test_files(1);

    $self->depends_on( 'test' );

    return;
}

sub ACTION_distdir {
    my ($self) = @_;

    $self->depends_on( 'extratest' );

    return $self->SUPER::ACTION_distdir();
}

sub _create_taint_mode_tests {
    my $self   = shift;
    my @tests  = glob 't/*.t';
    my @taints;
    require File::Basename;
    foreach my $t ( @tests ) {
        my($num,$rest) = split /\-/xms, File::Basename::basename( $t ), 2;
        push @taints, "t/$num-taint-mode-$rest";
    }

    for my $i ( 0..$#tests ) {
        next if $tests[$i] =~ m{ pod[.]t           \z }xms;
        next if $tests[$i] =~ m{ pod\-coverage[.]t \z }xms;
        next if $tests[$i] =~ m{ all\-modules\-have\-the\-same\-version[.]t \z }xms;

        next if -e $taints[$i]; # already created!

        open my $ORIG, '<:raw', $tests[$i]  or croak "Can not open file($tests[$i]): $!";
        open my $DEST, '>:raw', $taints[$i] or croak "Can not open file($taints[$i]): $!";
        print {$DEST} TAINT_SHEBANG or croak "Can not print to destination: $!";

        while ( defined( my $line = readline $ORIG ) ) {
            print {$DEST} $line or croak "Can not print to destination: $!";
        }

        close $ORIG or croak "Can not close original: $!";
        close $DEST or croak "Can not close destination: $!";

        $self->_write_file( '>>', 'MANIFEST', "$taints[$i]\n");
    }

    return;
}

sub _change_versions_pod {
    my($self, $mod) = @_;
    my $dver = $self->dist_version;
    my($mday, $mon, $year) = (localtime time)[3..5];
    my $date = join q{ }, $mday, [MONTHS]->[$mon], $year + YEAR_ADD;

    my $ns = $mod;
    $ns  =~ s{ [\\/]     }{::}xmsg;
    $ns  =~ s{ \A lib :: }{}xms;
    $ns  =~ s{ [.] pm \z }{}xms;
    my $pod = "\nThis document describes version C<$dver> of C<$ns>\n"
            . "released on C<$date>.\n"
            ;

    if ( $dver =~ m{[_]}xms ) {
        $pod .= join qq{\n},
                    "\nB<WARNING>: This version of the module is part of a",
                    "developer (beta) release of the distribution and it is",
                    "not suitable for production use.",
                ;
    }

    return $pod;
}

sub _change_versions {
    my($self, $files) = @_;
    my $dver = $self->dist_version;

    warn "CHANGING VERSIONS\n";
    warn "\tDISTRO Version: $dver\n";

    foreach my $mod ( @{ $files } ) {
        warn "\tPROCESSING $mod\n";
        my $new = $mod . '.new';

        open my $RO_FH, '<:raw', $mod or croak "Can not open file($mod): $!";
        open my $W_FH , '>:raw', $new or croak "Can not open file($new): $!";

        CHANGE_VERSION: while ( defined( my $line = readline $RO_FH ) ) {
            if ( $line =~ RE_VERSION_LINE ) {
                my $prefix    = $1 || q{};
                my $oldv      = $2;
                my $remainder = $3;
                warn "\tCHANGED Version from $oldv to $dver\n";
                printf {$W_FH} VTEMP . $remainder, $prefix, $dver;
                last CHANGE_VERSION;
            }
            print {$W_FH} $line or croak "Unable to print to FH: $!";
        }

        $self->_change_pod( $RO_FH, $W_FH, $mod );

        close $RO_FH or croak "Can not close file($mod): $!";
        close $W_FH  or croak "Can not close file($new): $!";

        unlink($mod) || croak "Can not remove original module($mod): $!";
        rename( $new, $mod ) || croak "Can not rename( $new, $mod ): $!";
        warn "\tRENAME Successful!\n";
    }

    return;
}

sub _change_pod {
    my($self, $RO_FH, $W_FH, $mod) = @_;
    my $acl = $self->add_pod_author_copyright_license;
    my $acl_buf;

    CHANGE_POD: while ( defined( my $line = readline $RO_FH ) ) {
        if ( $acl && $line =~ m{ \A =cut }xms ) {
            $acl_buf = $line; # buffer the last line
            last;
        }

        print {$W_FH} $line or croak "Unable to print to FH: $!";

        if ( $line =~ RE_POD_LINE ) {
            print {$W_FH} $self->_change_versions_pod( $mod )
                or croak "Unable to print to FH: $!";
        }
    }

    if ( $acl && defined $acl_buf ) {
        warn "\tADDING AUTHOR COPYRIGHT LICENSE TO POD\n";
        print {$W_FH} $self->_pod_author_copyright_license, $acl_buf
            or croak "Unable to print to FH: $!";

        while ( defined( my $line = readline $RO_FH ) ) {
            print {$W_FH} $line or croak "Unable to print to FH: $!";
        }
    }

    return;
}

sub _build_monolith {
    my $self      = shift;
    my $files     = shift;
    my @mono_dir  = ( monolithic_version => split /::/xms, $self->module_name );
    my $mono_file = pop(@mono_dir) . '.pm';
    my $dir       = File::Spec->catdir( @mono_dir );
    my $mono      = File::Spec->catfile( $dir, $mono_file );
    my $buffer    = File::Spec->catfile( $dir, 'buffer.txt' );
    my $readme    = File::Spec->catfile( qw( monolithic_version README ) );
    my $copy      = $mono . '.tmp';

    mkpath $dir;

    warn "STARTING TO BUILD MONOLITH\n";

    my(@files, $c);
    foreach my $f ( @{ $files }) {
        my(undef, undef, $base) = File::Spec->splitpath($f);
        if ( $base eq 'Constants.pm' ) {
            $c = $f;
            next;
        }
        push @files, $f;
    }

    push @files, $c;

    my $POD = $self->_monolith_merge(\@files, $mono_file, $mono, $buffer);
    $self->_monolith_add_pre( $mono, $copy, \@files, $buffer );

    if ( $POD ) {
        open my $MONOX, '>>:raw', $mono or croak "Can not open file($mono): $!";
        foreach my $line ( split /\n/xms, $POD ) {
            print {$MONOX} $line, "\n" or croak "Unable to print to FH: $!";
            if ( "$line\n" =~ RE_POD_LINE ) {
                print {$MONOX} $self->_monolith_pod_warning
                    or croak "Unable to print to FH: $!";
            }
        }
        close $MONOX or croak "Unable to close FH: $!";;
    }

    unlink $buffer or croak "Can not delete $buffer $!";
    unlink $copy   or croak "Can not delete $copy $!";

    print "\t" or croak "Unable to print to STDOUT: $!";
    system( $^X, '-wc', $mono ) && die "$mono does not compile!\n";

    $self->_monolith_prove;

    warn "\tADD README\n";
    $self->_write_file('>', $readme, $self->_monolith_readme);

    warn "\tADD TO MANIFEST\n";

    (my $monof   = $mono  ) =~ s{\\}{/}xmsg;
    (my $readmef = $readme) =~ s{\\}{/}xmsg;
    my $name = $self->module_name;

    $self->_write_file( '>>', 'MANIFEST',
        "$readmef\n",
        "$monof\tThe monolithic version of $name",
        " to ease dropping into web servers. Generated automatically.\n"
    );

    return;
}

sub _monolith_merge {
    my($self, $files, $mono_file, $mono, $buffer) = @_;
    my %add_pod;
    my $pod = q{};

    open my $MONO  , '>:raw', $mono   or croak "Can't open file($mono): $!";
    open my $BUFFER, '>:raw', $buffer or croak "Can't open file($buffer): $!";

    MONO_FILES: foreach my $mod ( reverse @{ $files } ) {
        warn "\tMERGE $mod\n";
        my(undef, undef, $base) = File::Spec->splitpath( $mod );
        my $is_eof = 0;
        my $is_pre = $self->_monolith_add_to_top( $base );
        my $TARGET = $is_pre ? $BUFFER : $MONO;
        open my $RO_FH, '<:raw', $mod or croak "Can not open file($mod): $!";

        MONO_MERGE: while ( defined( my $line = readline $RO_FH ) ) {
            chomp( my $chomped = $line );
            $is_eof++ if $chomped eq '1;';
            last MONO_MERGE if $is_eof && $base ne $mono_file;

            if ( $is_eof ) {
                warn "\tADD POD FROM $mod\n" if ! $add_pod{ $mod }++;
                $pod .= $line;
                next;
            }

            print { $TARGET } $line or croak "Unable to print to FH: $!";
        }

        close $RO_FH or croak "Unable to close FH: $!";
    }

    close $MONO   or croak "Unable to close FH: $!";
    close $BUFFER or croak "Unable to close FH: $!";

    return $pod;
}

sub _monolith_prove {
    my($self) = @_;

    warn "\tTESTING MONOLITH\n";
    local $ENV{AUTHOR_TESTING_MONOLITH_BUILD} = 1;

    require File::Basename;
    require File::Spec;

    my $pbase = File::Basename::dirname( $^X );
    my $prove;
    find {
        wanted => sub {
            my $file = $_;
            return if $file !~ m{ prove }xms;
            $prove = $file;
        },
        no_chdir => 1,
    }, $pbase;

    if ( ! $prove || ! -e $prove ) {
        croak "No `prove command found related to $^X`";
    }

    warn "\n\tFOUND `prove` at $prove\n\n";

    require IPC::Open3;
    my $prove_pid = IPC::Open3::open3(
                        my($prove_in, $prove_out, $prove_err),
                        $prove, qw(-Ilib -r t xt)
                    );

    my $prove_status;
    while ( defined( my $result = <$prove_out> ) ) {
        chomp $result;
        $prove_status = $result;
        print "\t$result\n" or croak "Unable to print to STDOUT: $!";
    }

    waitpid( $prove_pid, 0 );
    my $prove_failed = $? >> 8;

    if ( $prove_failed || $prove_status ne 'Result: PASS' ) {
        croak MONOLITH_TEST_FAIL;
    }

    return;
}

sub _monolith_add_pre {
    my($self, $mono, $copy, $files, $buffer) = @_;
    require File::Copy;
    File::Copy::copy( $mono, $copy ) or croak "Copy failed: $!";

    my $clean_file = sub {
        my $f = shift;
        $f =~ s{    \\   }{/}xmsg;
        $f =~ s{ \A lib/ }{}xms;
        return $f;
    };

    my $clean_module = sub {
        my $m = shift;
        $m =~ s{ [.]pm \z }{}xms;
        $m =~ s{  /       }{::}xmsg;
        return $m;
    };

    my @inc_files = map { $clean_file->(   $_ ) } @{ $files };
    my @packages  = map { $clean_module->( $_ ) } @inc_files;

    open my $W, '>:raw', $mono or croak "Can not open file($mono): $!";

    printf {$W} q/BEGIN { $INC{$_} = 1 for qw(%s); }/, join q{ }, @inc_files
            or croak "Can not print to MONO file: $!";
    print  {$W} "\n" or croak "Can not print to MONO file: $!";

    foreach my $name ( @packages ) {
       print {$W} qq/package $name;\nsub ________monolith {}\n/
             or croak "Can not print to MONO file: $!";
    }

    open my $TOP,  '<:raw', $buffer or croak "Can not open file($buffer): $!";
    while ( defined( my $line = <$TOP> ) ) {
       print {$W} $line or croak "Can not print to BUFFER file: $!";
    }
    close $TOP or croak 'Can not close BUFFER file';

    open my $COPY, '<:raw', $copy or croak "Can not open file($copy): $!";

    while ( defined( my $line = <$COPY> ) ) {
        print {$W} $line or croak "Can not print to COPY file: $!";
    }

    close $COPY or croak "Can't close COPY file: $!";
    close $W    or croak "Can't close MONO file: $!";

    return;
}

sub _write_file {
    my($self, $mode, $file, @data) = @_;
    $mode = $mode . ':raw';
    open my $FH, $mode, $file or croak "Can not open file($file): $!";
    print {$FH} @data or croak "Can not print to FH: $!";
    close $FH or croak "Can not close $file $!";
    return;
}

sub _monolith_add_to_top {
    my $self = shift;
    my $base = shift;
    my $list = $self->monolith_add_to_top || croak 'monolith_add_to_top not set';
    croak 'monolith_add_to_top is not an ARRAY' if ref $list ne 'ARRAY';
    return grep { $_ eq $base } @{ $list };
}

sub _monolith_readme {
    my $self = shift;
    (my $pod  = $self->_monolith_pod_warning) =~ s{B<(.+?)>}{$1}xmsg;
    return $pod;
}

sub _monolith_pod_warning {
    my $self = shift;
    return $self->_compile_template(
                'pod/monolith-warning.pod' => {
                    module => $self->module_name,
                },
            );
}

sub _automatic_build_file_header {
    return shift->_compile_template( 'tools/builder.header' );
}

sub _add_automatic_build_pl {
    my $self = shift;
    my $file = 'Build.PL';
    return if -e $file; # do not overwrite
    $self->_write_file(  '>', $file    =>  $self->_automatic_build_pl       );
    $self->_write_file( '>>', MANIFEST => "$file\tGenerated automatically\n");
    warn "ADDED AUTOMATIC $file\n";
    return;
}

sub _automatic_build_pl {
    my $self    = shift;
    my %spec    = Build::Spec::spec( builder => 1 );
    my $build   = delete $spec{BUILDER} || croak 'SPEC does not have a BUILDER key';
    my $methods = join ";\n",
                  map { sprintf q{$mb->%s( %s )}, $_, $build->{ $_ } }
                  keys %{ $build };

    return join q{},
                $self->_automatic_build_file_header,
                $self->_compile_template(
                    'tools/Build.PL' => {
                        methods => $methods,
                    },
                ),
            ;
}

sub _add_vanilla_makefile_pl {
    my $self = shift;
    my $file = 'Makefile.PL';
    return if -e $file; # don't overwrite
    $self->_write_file(  '>', $file    => $self->_vanilla_makefile_pl       );
    $self->_write_file( '>>', MANIFEST => "$file\tGenerated automatically\n");
    warn "ADDED VANILLA $file\n";
    return;
}

sub _vanilla_makefile_pl {
    my $self = shift;
    my $hook = $self->initialization_hook;

    if ( $hook ) {
        $hook = $self->_compile_template(
                    'tools/Makefile.PL.hook' => {
                        hook => $hook,
                    },
                ),
    }

    return join q{},
                $self->_automatic_build_file_header,
                $self->_compile_template(
                    'tools/Makefile.PL' => {
                        hook => $hook || q{},
                    },
                ),
            ;
}

sub _pod_author_copyright_license {
    my $self = shift;
    my $da   = $self->dist_author; # support only 1 author for now
    my $cfy  = $self->copyright_first_year;
    my $year = (localtime time)[YEAR_SLOT] + YEAR_ADD;
    my($author, $email) = $da->[0] =~ m{ (.+?) < (.+?) > }xms;
    $author = trim( $author ) if $author;
    $email  = trim( $email )  if $email;
    $year   = "$cfy - $year"  if $cfy && $cfy != $year && $cfy < $year;

    return $self->_compile_template(
                'pod/author.pod' => {
                    author => $author,
                    email  => $email,
                    year   => $year,
                    perl   => sprintf( '%vd', $^V ),
                },
            );

}

sub _compile_template {
    my($self, $path, $param) = @_;

    my $full_path = File::Spec->catfile(  qw( builder templates ), $path );
    die "Can't locate template $path: $!" if ! -e $full_path;

    $param ||= {};
    my $raw = slurp( $full_path );
    my %p   = map { uc( $_ ) => $param->{ $_ } } keys %{ $param };
    my %seen;
    my $key_value = sub {
        my $match = shift;
        my $key   = trim( $match );
        my $value = $p{ $key };

        if ( ! defined $value ) {
            if ( ! $seen{ $key }++ ) {
                warn "$path: Bogus or no value for template key '$key'";
            }
            return q();
        }

        return $value;
    };

    $raw =~ s{[[][%](.+?)[%][]]}{$key_value->($1)}xmsge;

    return $raw;
}

1;

__END__
