########################################################################
# housekeeping
########################################################################

package Module::FromPerlVer::Dir;
use 5.006;
use strict;
use version;
use parent  qw( Module::FromPerlVer::Extract );

use Cwd                     qw( cwd             );
use File::Basename          qw( basename        );
use File::Copy::Recursive   qw( dircopy         );
use File::Find              qw( find            );
use FindBin                 qw( $Bin            );
use List::Util              qw( first           );

########################################################################
# package variables & sanity checks
########################################################################

our $VERSION    = version->parse( 'v0.0.2' )->numify;

########################################################################
# methods
########################################################################

sub source_prefix
{
    my $extract = shift;
    my $dir     = $extract->{ version_dir };

    # order of paths will prefer "./t/version" to 
    # "./version" during testing.

    my $path
    = first
    {
        -e 
    }
    (
        $dir        ,
        "$Bin/$dir" ,
        "./$dir"    ,
    )
    or die "Bogus version_prefix: Non-existant: '$dir' ($Bin)";

    for my $cwd ( cwd )
    {
        # convert $path to relative.

        my $i   = length $cwd;

        index $path, "$cwd/"
        or
        substr $path, 0, $i, '.'
    }

    -e $path    or die "Bogus version_prefix: non-existant '$path'";
    -d _        or die "Bogus version_prefix: non-dir      '$path'";
    -r _        or die "Bogus version_prefix: non-readable '$path'";
    -x _        or die "Bogus version_prefix: non-execable '$path'";

    my @found   = glob "$path/*"
    or die "Botchd version_prefix: '$path' is empty directory.\n";

    # caller gets back the relpath to the version dir.
    # cache it for later use in this module.

    $extract->value( source_dir => $path )
}

sub module_sources 
{
    my $extract     = shift;
    my $version_d   = $extract->value( 'source_dir' );

    grep
    {
        -d 
    }
    glob "$version_d/*"
}

sub source_files
{
    my $extract     = shift;
    my $source_d    = $extract->value( 'module_source' );
    my $n           = length $source_d;
    my @pathz       = ( [], [] );

    find
    sub
    {
        my $path    = $File::Find::name;

        $path ne $source_d
        or return;

        my $rel     = '.' . substr $path, $n;

        my $i
        = -d $_
        ? 1
        : 0
        ;

        push @{ $pathz[ $i ] }, $rel;
    },
    $source_d;

    $extract->value( source_files => \@pathz );

    # deal with a set of empty dirs.

    @{ $pathz[0] }
    or warn "No input files found: '$source_d'";

    @pathz
}

sub get_files
{
    local $\    = "\n";
    my $extract = shift;

    my ( $filz, $dirz ) = @{ $extract->value( 'source_files' ) };
    my $path            = $extract->value( 'module_source' ); 
    my $found           = dircopy $path, '.';
    
    print "# Copied: $found files from '$path'";

    my $expect          = @$filz + @$dirz + 1;

    $found != $expect
    and
    print "# Oddity: mismatched count $found != $expect.";

    $found
}

# keep require happy
1
__END__
