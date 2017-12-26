
use 5.006001;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Spec;

use lib 'inc';

use My::Module::Meta qw{ recommended_module_versions };

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '0.102';

#-----------------------------------------------------------------------------

# Certain developers change perl installations on occasion and don't always
# have all the optional modules installed.  Make sure that they know that they
# don't.  :]

my %module_versions = (
    recommended_module_versions(),
    'Test::Memory::Cycle'   => 0,
    'Test::Without::Module' => 0,
);

plan tests => scalar keys %module_versions;

foreach my $module (sort keys %module_versions) {
    check_version( $module, $module_versions{$module} );
}

# Check if the given module (and version) is installed.
#
# We used to just use 'use_ok()', but Readonly::XS now complains if anyone but
# Readonly loads it, and there seems to be no supportable way to defeat the
# complaint. So we hand-scan @INC, and use ExtUtils::MakeMaker to retrieve the
# version without actually loading the module.

sub check_version {
    my ( $module, $version ) = @_;
    my $want_v = $version;
    defined $want_v
        and $want_v =~ s/ _ //smxg;
    ( my $fn = $module ) =~ s{ :: }{/}smxg;
    $fn .= '.pm';
    foreach my $dir ( @INC ) {
        my $path = File::Spec->catfile( $dir, $fn );
        -f $path
            or next;
        if ( $want_v ) {
            ( my $file_v = MM->parse_version( $path ) ) =~ s/ _ //smxg;
            @_ = ( $file_v, '>=', $want_v, "$module version $version (at least) is installed" );
            goto &cmp_ok;
        } else {
            @_ = ( "$module is installed" );
            goto &pass;
        }
    }
    @_ = ( "$module is not installed" );
    goto &fail;
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
