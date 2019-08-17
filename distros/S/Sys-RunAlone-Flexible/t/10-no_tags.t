use strict;
use warnings;

BEGIN {    # Magic Perl CORE pragma
    if ( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 27;

sub slurp ($) { open( my $handle, $_[0] ); local $/; <$handle> }

my @use_cases = (
    {
        name => 'missing tags in main (use)',
        pkg  => 'main',
    },
    {
        name => 'missing tags in My::Script (use)',
        pkg  => 'My::Script',
    },
);

for (@use_cases) {

    # create faulty worker script
    ok( open( my $handle, '>', 'script' ), "Create script for $_->{pkg}" );
    ok( print( $handle <<"EOD" ), "Print script for $_->{pkg}" );
\$| = 1;
package $_->{pkg};
use Sys::RunAlone::Flexible;
<>;
EOD
    ok( close($handle), "Close script for $_->{pkg}" );

    # check fault reporting
    my $ok = 0;

    my $command = "| $^X -I$INC[-1] script 2>2";
    $ok++ if ok( open( my $stdin, $command ), "Run script for $_->{pkg}" );
    sleep 1;
    chomp( my $error = slurp 2 );
    $ok++ if like( $error, qr/Add __END__ or __DATA__/, $_->{name} );
    $ok++ if ok( !close($stdin), "Close pipe for $_->{pkg}" );
    diag($command) if $ok != 3;

}

my @require_cases = (
    {
        name => 'tags not needed in main for require',
        pkg  => 'main',
    },
    {
        name => 'tags not needed in My::Script for require',
        pkg  => 'My::Script',
    },
);

for (@require_cases) {

    # create worker script
    ok( open( my $handle, '>', 'script' ), "Create script for $_->{pkg}" );
    ok( print( $handle <<"EOD" ), "Print script for $_->{pkg}" );
\$| = 1;
package $_->{pkg};
require Sys::RunAlone::Flexible;
warn "normal execution in \$Sys::RunAlone::Flexible::pkg\n";
Sys::RunAlone::Flexible::lock();
<>;
EOD
    ok( close($handle), "Close script for $_->{pkg}" );

    # check fault reporting
    my $ok = 0;

    my $command = "| $^X -I$INC[-1] script 2>2";
    $ok++ if ok( open( my $stdin, $command ), "Run script for $_->{pkg}" );
    sleep 1;
    chomp( my $error = slurp 2 );
    $ok++ if like( $error, qr/normal execution/, $_->{name} );
    $ok++
      if like( $error, qr/Add __END__ or __DATA__/,
        'lock() fails without tags' );
    $ok++ if ok( !close($stdin), "Close pipe for $_->{pkg}" );
    diag($command) if $ok != 4;

}

exit;

END {
    is( 2, unlink(qw(script 2)), "Cleanup" );
    1 while unlink qw(script 2);
}

__END__
