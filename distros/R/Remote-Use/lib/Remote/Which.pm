package Remote::Which;
use strict;

require Exporter;

@Remote::Which::ISA       = qw(Exporter);

@Remote::Which::EXPORT    = qw(which);

$Remote::Which::VERSION = '0.05';

use File::Spec;

my $Is_VMS    = ($^O eq 'VMS');
my $Is_MacOS  = ($^O eq 'MacOS');
my $Is_DOSish = (($^O eq 'MSWin32') or
                ($^O eq 'dos')     or
                ($^O eq 'os2'));

# For Win32 systems, stores the extensions used for
# executable files
# For others, the empty string is used
# because 'perl' . '' eq 'perl' => easier
my @path_ext = ('');
if ($Is_DOSish) {
    if ($ENV{PATHEXT} and $Is_DOSish) {    # WinNT. PATHEXT might be set on Cygwin, but not used.
        push @path_ext, split ';', $ENV{PATHEXT};
    }
    else {
        push @path_ext, qw(.com .exe .bat); # Win9X or other: doesn't have PATHEXT, so needs hardcoded.
    }
}
elsif ($Is_VMS) { 
    push @path_ext, qw(.exe .com);
}

sub which {
    my ($exec) = @_;

    return undef unless $exec;

    my $all = wantarray;
    my @results = ();
    
    # check for aliases first
    if ($Is_VMS) {
        my $symbol = `SHOW SYMBOL $exec`;
        chomp($symbol);
        if (!$?) {
            return $symbol unless $all;
            push @results, $symbol;
        }
    }
    if ($Is_MacOS) {
        my @aliases = split /\,/, $ENV{Aliases};
        foreach my $alias (@aliases) {
            # This has not been tested!!
            # PPT which says MPW-Perl cannot resolve `Alias $alias`,
            # let's just hope it's fixed
            if (lc($alias) eq lc($exec)) {
                chomp(my $file = `Alias $alias`);
                last unless $file;  # if it failed, just go on the normal way
                return $file unless $all;
                push @results, $file;
                # we can stop this loop as if it finds more aliases matching,
                # it'll just be the same result anyway
                last;
            }
        }
    }

    my @path = File::Spec->path();
    unshift @path, File::Spec->curdir if $Is_DOSish or $Is_VMS or $Is_MacOS;

    for my $base (map { File::Spec->catfile($_, $exec) } @path) {
       for my $ext (@path_ext) {
            my $file = $base.$ext;
# print STDERR "$file\n";

            if ((-x $file or    # executable, normal case
                 ($Is_MacOS ||  # MacOS doesn't mark as executable so we check -e
                  ($Is_DOSish and grep { $file =~ /$_$/i } @path_ext[1..$#path_ext])
                                # DOSish systems don't pass -x on non-exe/bat/com files.
                                # so we check -e. However, we don't want to pass -e on files
                                # that aren't in PATHEXT, like README.
                 and -e _)
                ) and !-d _)
            {                   # and finally, we don't want dirs to pass (as they are -x)

# print STDERR "-x: ", -x $file, " -e: ", -e _, " -d: ", -d _, "\n";

                    return $file unless $all;
                    push @results, $file;       # Make list to return later
            }
        }
    }
    
    if($all) {
        return @results;
    } else {
        return undef;
    }
}

1;
__END__


