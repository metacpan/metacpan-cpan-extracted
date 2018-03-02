########################################################################
# housekeeping
########################################################################

package Module::FromPerlVer::Git;
use 5.006;
use strict;
use version;
use parent  qw( Module::FromPerlVer::Extract );

use File::Basename          qw( basename        );
use List::Util              qw( first           );
use Symbol                  qw( qualify_to_ref  );

########################################################################
# package variables & sanity checks
########################################################################

our $VERSION    = version->parse( 'v0.0.2' )->numify;

my $nil         = sub{};

my @checkout    = qw( git checkout --detach );
my @restore     = qw( git checkout --theirs );

########################################################################
# methods
########################################################################

sub source_prefix
{
    my $extract = shift;

    $extract->value( 'git_prefix' )
}

sub module_sources
{
    my $extract = shift;
    my $prefix  = $extract->value( 'git_prefix' );

    # force a list context for qx

    ( qx{ git tag --list $prefix* } )
    or 
    die "No tags like '$prefix*' found"
}

sub source_files
{
    # avoid returning true in scalar context.

    return
}

sub get_files
{
    my $extract = shift;
    my $tag     = $extract->value( 'module_source' );

    # deal with parsing this iff cleanup is called.

    $extract->value( restore_branch => qx{ git branch } );

    # no telling what the tag might look like.
    # quotes protect it from the shell.

    system @checkout, "'$tag'"
    and
    do
    {
        local $, = ' ';
        warn "Non-zero exit: $? from @checkout '$tag'";
    }
}

sub cleanup
{
    my $extract = shift;
    my $branch  = $extract->value( 'restore_branch' );

    system @restore, "'$branch'"
    and
    do
    {
        local $, = ' ';
        warn "Non-zero exit: $? from @restore '$branch'";
    }
}

# keep require happy
1
__END__
