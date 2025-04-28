use 5.10.1;
use strict;
use warnings;
use Test::Vars tests => $^O eq 'MSWin32'? 13 : 12;


vars_ok( 'lib/Term/Choose/Screen.pm', ignore_vars => [ '$size' ] );


my @modules = qw(
lib/Term/Choose.pm
lib/Term/Choose/Constants.pm
lib/Term/Choose/LineFold.pm
lib/Term/Choose/LineFold/PP.pm
lib/Term/Choose/LineFold/PP/CharWidthAmbiguousWide.pm
lib/Term/Choose/LineFold/PP/CharWidthDefault.pm
lib/Term/Choose/Linux.pm
lib/Term/Choose/Opt/Mouse.pm
lib/Term/Choose/Opt/Search.pm
lib/Term/Choose/Opt/SkipItems.pm
lib/Term/Choose/ValidateOptions.pm
);

if ( $^O eq 'MSWin32' ) {
    push @modules, 'lib/Term/Choose/Win32.pm';
}

for my $module ( @modules ) {
    vars_ok( $module );
}
