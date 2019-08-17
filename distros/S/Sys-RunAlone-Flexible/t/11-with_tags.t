use strict;
use warnings;

BEGIN {    # Magic Perl CORE pragma
    if ( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 49;

sub slurp ($) { open( my $handle, $_[0] ); local $/; <$handle> }

my @use_cases = (
    {
        name  => '__END__ in main found in main (use)',
        pkg   => 'main',
        tag   => '__END__',
        found => 'main',
    },
    {
        name  => '__END__ in My::Script found in main (use)',
        pkg   => 'My::Script',
        tag   => '__END__',
        found => 'main',
    },
    {
        name  => '__DATA__ in main found in main (use)',
        pkg   => 'main',
        tag   => '__DATA__',
        found => 'main',
    },
    {
        name  => '__DATA__ in My::Script found in My::Script (use)',
        pkg   => 'My::Script',
        tag   => '__DATA__',
        found => 'My::Script',
    },
);

for (@use_cases) {

    # create worker script
    ok( open( my $handle, '>', 'script' ), "Create script for $_->{pkg}" );
    ok( print( $handle <<"EOD" ), "Print script for $_->{pkg}" );
\$| = 1;
package $_->{pkg};
use Sys::RunAlone::Flexible;
warn "normal execution in \$Sys::RunAlone::Flexible::data_pkg\n";
exit;
$_->{tag}
EOD
    ok( close($handle), "Close script for $_->{pkg}" );

    # check fault reporting
    my $ok = 0;

    my $command = "| $^X -I$INC[-1] script 2>2";
    $ok++ if ok( open( my $stdin, $command ), "Run script for $_->{pkg}" );
    sleep 1;
    chomp( my $error = slurp 2 );
    $ok++ if like( $error, qr/normal execution in $_->{found}/, $_->{name} );
    $ok++ if ok( close($stdin), "Close pipe for $_->{pkg}" );
    diag($command) if $ok != 3;

}

my @require_cases = (
    {
        name  => '__END__ in main found in main (require)',
        pkg   => 'main',
        tag   => '__END__',
        found => 'main',
    },
    {
        name  => '__END__ in My::Script found in main (require)',
        pkg   => 'My::Script',
        tag   => '__END__',
        found => 'main',
    },
    {
        name  => '__DATA__ in main found in main (require)',
        pkg   => 'main',
        tag   => '__DATA__',
        found => 'main',
    },
    {
        name  => '__DATA__ in My::Script found in My::Script (require)',
        pkg   => 'My::Script',
        tag   => '__DATA__',
        found => 'My::Script',
    },
);

for (@require_cases) {

    # create worker script
    ok( open( my $handle, '>', 'script' ), "Create script for $_->{pkg}" );
    ok( print( $handle <<"EOD" ), "Print script for $_->{pkg}" );
\$| = 1;
package $_->{pkg};
require Sys::RunAlone::Flexible;
Sys::RunAlone::Flexible::lock();
warn "normal execution in \$Sys::RunAlone::Flexible::data_pkg\n";
exit;
$_->{tag}
EOD
    ok( close($handle), "Close script for $_->{pkg}" );

    # check fault reporting
    my $ok = 0;

    my $command = "| $^X -I$INC[-1] script 2>2";
    $ok++ if ok( open( my $stdin, $command ), "Run script for $_->{pkg}" );
    sleep 1;
    chomp( my $error = slurp 2 );
    $ok++ if like( $error, qr/normal execution in $_->{found}/, $_->{name} );
    $ok++ if ok( close($stdin), "Close pipe for $_->{pkg}" );
    diag($command) if $ok != 3;

}

exit;

END {
    is( 2, unlink(qw(script 2)), "Cleanup" );
    1 while unlink qw(script 2);
}

__END__
