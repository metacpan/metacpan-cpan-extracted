use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

set_swish_version();

WriteMakefile(
    NAME            => 'SWISH::Fork',
    VERSION_FROM    => 'Fork.pm',  # finds $VERSION

    NORECURS        => 1,          # keep it from recursing into subdirectories
    DIR             => [],

    PREREQ_PM       => {
        'SWISH'         => 0,
        #'Sys::Signal'   => 0.02,  # this is needed under mod_perl
    },
    
    dist            => {
        COMPRESS        => 'gzip',
        SUFFIX          => 'gz',
        # PREOP         => 'pod2text -80 < Fork.pm > README',
    },

    clean           => {
        FILES           => 't/test.index t/swish.dat t/test.conf',
    },
);

sub set_swish_version {
    $|=1;

    print "\nFor testing we will need the path to your SWISH-E binary\n",
          "Also note that you must have the SWISH module also installed.\n\n";
          


    my $swish = '';
    for ( split /:/, $ENV{PATH} ) {
        if ( -x "$_/swish-e" && !-d _ ) {
            $swish = "$_/swish-e";
            last;
        }
    }

    

    my $version;

    while ( 1 ) {
        my $enter = $swish;

        print "Enter the location of a the swish-e executable[$enter]: ";

        $enter = <STDIN>;
        chomp $enter;

        $enter = $enter || $swish;

        $enter =~ s/^(~|\$HOME)/($ENV{HOME}||'')/e;
        
        if ( $enter && !-x $enter ) {
            print "File '$enter' missing or not exectuable\n";

        } else {
            $version = `$enter -V`;
            $version =~ tr/[0-9].//cd;
            $version = do { my @v=split('\.', $version ); sprintf "%d." . "%03d"x$#v,@v };
            
            if ( $version ) {
                print "Your SWISH-E version: $version\n";
                $swish = $enter;
                last;
            } else {
                print "Failed to parse version from '$enter'\n";
            }
        }
            
    }

    open FH, '>t/swish.dat' or die "Can't write to t/swish.dat: $!";
    print FH "$swish\n$version\n";

    create_index( $swish, $version );
}    

sub create_index {
    my ($swish, $version) = @_;
    
    open ( F, '>t/test.conf' ) or die "Failed to create 't/test.config': $!";

    print F "IndexDir t/test.html t/test1.html t/test2.html\n";

    if ( $version >= 1.3 ) {

        $settings{properties} = ['property','property2'];
        print F "PropertyNames property property2\n";
    }

    close F;

    unlink 't/test.index' if -r 't/test.index';

    print "Creating index...'$swish -c t/test.conf -f t/test.index'\n\n";
    system($swish,  '-c', 't/test.conf', '-f', 't/test.index', '-v','0');

    die "Failed to create index file" unless -r 't/test.index';
}
