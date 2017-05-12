use strict;
use ExtUtils::MakeMaker;
use 5.008009;
use Config;        # for path separator
use File::Spec;    # for catpath

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

sub check_perl_compat {

    return 1; # ok for now. this is a placeholder.

}

sub get_dir_contents {
    my $dir   = shift;
    my @parts = File::Spec->splitpath($dir);
    my $path  = File::Spec->catdir(@parts);
    opendir( DIR, $path ) or return ();
    my @contents = grep { !m/^\./ } readdir(DIR);
    closedir(DIR);
    return @contents;
}

sub get_available_locales {
    my @locales;
    eval { @locales = backtick('locale -a'); };
    return (@locales) if @locales;

    # this list directly from perllocale.pod
    my @dirs = qw(
        /usr/lib/nls/loc
        /usr/lib/locale
        /usr/lib/nls
        /usr/share/locale
    );
    for my $dir (@dirs) {
        my @contents = get_dir_contents($dir);
        if (@contents) {
            return @contents;
        }
    }
    return ();
}

sub has_locale_support {
    use POSIX qw(locale_h);

    # first, check the current locale
    for my $category ( ( LC_CTYPE, LC_ALL ) ) {
        my $locale = setlocale($category);
        if ( defined($locale) and $locale =~ m/UTF-8|utf8/i ) {
            return 1;
        }
    }

    # second, try en_US
    my $locale = setlocale( LC_CTYPE, "en_US.UTF-8" );
    if ( defined($locale) and $locale =~ m/UTF-8/ ) {
        return 1;
    }

    # third, find out what is installed and try any UTF-8
    my @locales = get_available_locales();
    for my $locale (@locales) {
        if ( $locale =~ m/UTF-8/i ) {
            my $ret = setlocale( LC_CTYPE, $locale );
            if ( $ret eq $locale ) {
                return 1;
            }
        }
    }

    # give up
    return 0;

}

# these routines cribbed from Swish-e 2.x Makefile.PL

#----------------------------------------------------------------------------------
# Find a program in either $PATH or path/directory passed in.
#----------------------------------------------------------------------------------
sub find_program {
    my ($name) = @_;

    my $search_path ||= $ENV{LIBSWISH3_PATH} || $ENV{PATH};

    for my $dir ( split /$Config{path_sep}/, $search_path ) {
        my $path = File::Spec->catfile( $dir, $name );

        for my $extension ( '', '.exe' ) {
            my $file = $path . $extension;
            return $file if -x $file && !-d _;
        }
    }
    return;
}

#----------------------------------------------------------------------------------
# Run a program with backtics, checking for errors
#----------------------------------------------------------------------------------

sub backtick {
    my ($command) = @_;

    my $output = `$command`;

    my $status
        = $? == 0  ? ''
        : $? == -1 ? "Failed to execute: $!"
        : $? & 127 ? sprintf(
        "Child died with signal %d, %s corefile",
        ( $? & 127 ),
        ( $? & 128 ) ? 'with' : 'without'
        )
        : sprintf( "Child exited with value %d", $? >> 8 );

    die "Failed to run program [$command]: $status\n" if $status;

    chomp $output;
    return $output;
}

# OS check
if ($^O eq 'Win32') {
    print STDERR <<EOF;

libswish3 has not yet been ported to Windows and will not build
on this system.

EOF

    exit(0);
}

###########################################
# get the config scripts and write makefile

my $xml2_config = find_program('xml2-config') || '';
warn "using xml2-config $xml2_config\n";
if ( !$xml2_config ) {

    print STDERR <<EOF;

Missing one or more dependencies.

You must have libxml2 installed in order to build
SWISH::3. If you have it installed, set the LIBSWISH3_PATH 
environment variable or make sure 'xml2-config' is in your PATH.

EOF

    exit(0);    # per Search::Xapian Makefile.PL, MakeMaker expects exit 0
                # to indicate failed dependencies

}

if ( !has_locale_support() ) {

    print STDERR <<EOF;

Your system does not appear to support locales with the UTF-8
character set. libswish3 requires both a functioning setlocale()
and support for a UTF-8 locale.

EOF

    exit(0);    # same as above;

}

if ( !check_perl_compat() ) {
    exit(0);    # ditto
}

WriteMakefile(
    NAME         => 'SWISH::3',
    VERSION_FROM => 'lib/SWISH/3.pm',
    PREREQ_PM    => {
        'Test::More' => 0,
        'Data::Dump' => 0,
    },
    XS => { '3.xs' => '3.c' },
    C  => [qw( libswish3.c 3.c )],
    H  => [qw( xs_helpers.c xs_boiler.h libswish3.h macros.h )],
    (   $] >= 5.005
        ? ( ABSTRACT_FROM => 'lib/SWISH/3.pm',
            AUTHOR        => 'Peter Karman <perl@peknet.com>'
            )
        : ()
    ),
    LIBS   => join( ' ', backtick( $xml2_config . ' --libs' ) ),
    DEFINE => '',        # e.g., '-DHAVE_SOMETHING'
    INC    => join( ' ', backtick( $xml2_config . ' --cflags' ) ),

    clean => { FILES => 't/swish.xml SWISH-3-*tar.gz' },

    OBJECT => '$(O_FILES)',    # links libswish3.o with XS

    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'GPL2' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'GPL2',
                    homepage => 'http://dev.swish-e.org/wiki/swish3',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-3',
                    repository => 'http://svn.swish-e.org/libswish3',
                },
            }
            )
    ),
);

sub MY::postamble {

    build_constants();

    return
          "\$(XS_FILES): "
        . join( " ", <XS/*.xs> )
        . "\n\ttouch \$(XS_FILES)";
}

sub build_constants {
    my $libswish3_h_file = 'libswish3.h';
    if ( !$libswish3_h_file ) {
        print STDERR "Failed to find libswish3.h file\n";
        exit(0);
    }

    my @defines;
    my @constants;
    my %uniq;

    open( HFILE, "< $libswish3_h_file" )
        or die "can't read $libswish3_h_file: $!";
    while (<HFILE>) {
        next unless m/SWISH_/;
        push( @defines, $_ );
    }
    close(HFILE);

    for my $def (@defines) {
        chomp $def;
        if ( $def =~ m/^#define (\w+)\ +(\d+)/ ) {
            my $const = $1;
            next if $uniq{$const}++;
            push( @constants,
                qq{newCONSTSUB(stash, "$const", newSViv($const));} );
        }
        elsif ( $def =~ m/^#define (\w+)\ +"(.+?)"/ ) {
            my $const = $1;
            next if $uniq{$const}++;
            push( @constants,
                qq{newCONSTSUB(stash, "$const", newSVpv($const, 0));} );
        }
    }
    open( XS, "> XS/Constants.xs" ) or die "can't write XS/Constants.xs: $!";
    print XS '
BOOT:
{
    HV *stash;
  
    stash = gv_stashpv("SWISH::3", TRUE);
';

    for my $const (@constants) {
        print XS "    $const\n";
    }
    print XS "}\n";
    close(XS);

}
