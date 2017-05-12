# Makefile generator
# $Id: Makefile.PL,v 1.2 2000/02/16 13:14:05 mfowler Exp $


use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            =>  'Parse::PerlConfig',
    VERSION_FROM    =>  'PerlConfig.pm',

    'dist' => {
        COMPRESS        =>  'gzip',
        TARFLAGS        =>  'cvf',
        SUFFIX          =>  'gz',
    },


    PM => {
        'PerlConfig.pm' => '$(INST_LIBDIR)/PerlConfig.pm'
    },


    # This may not be portable, as I found the TESTS attribute in
    # ExtUtils::MM_Unix.pm's source.  However, it seems cleaner and
    # easier to me than relying on directory sort order.
    'test' => {
        TESTS  =>  read_test_manifest('MANIFEST', '^t/.*\.t$'),
    },
);



# read_test_manifest <filename> <regex>

# This subroutine is responsible for reading a manifest for a given regex,
# quoting the lines found so as not be oddly interpreted by a shell, and
# returning the entire thing in the form of a space-seperated string.
#
# Returns undef if there was an error, an empty string if no tests were
# found.
sub read_test_manifest {
    my($manifest, $regex) = (shift, shift);
    local(*FILE);

    # Compile the regex if we can.
    $regex = qr/$regex/ if $] >= 5.00503;


    unless (open MANIFEST, $manifest) {
        warn("Unable to open manifest \"$file\": \L$!\n");
        return;
    }

    my @tests;
    while (defined($file = <MANIFEST>)) {
        chomp;
        $file =~ s/(^\s*|\s*$)//; # trim whitespace

        if ($file =~ /$regex/) {
    
            # escape potentially dangerous characters
            $file =~ s#([^-\w\d./])#\\$1#g;

            push(@tests, $file);
        }
    }


    return join("", @tests);
}
