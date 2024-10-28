use Test::Vars tests => $^O eq 'MSWin32'? 12 : 11;


#all_vars_ok();

if ( $^O eq 'MSWin32' ) {
    vars_ok( 'lib/Term/Choose/Win32.pm' );
}


vars_ok( 'lib/Term/Choose/Screen.pm', ignore_vars => [ '$size' ] );


my @modules = qw(
    lib/Term/Choose.pm
    lib/Term/Choose/Constants.pm
    lib/Term/Choose/LineFold.pm
    lib/Term/Choose/LineFold/CharWidthAmbiguousWide.pm
    lib/Term/Choose/LineFold/CharWidthDefault.pm
    lib/Term/Choose/Linux.pm
    lib/Term/Choose/Opt/Mouse.pm
    lib/Term/Choose/Opt/Search.pm
    lib/Term/Choose/Opt/SkipItems.pm
    lib/Term/Choose/ValidateOptions.pm
);
for my $module ( @modules ) {
    vars_ok( $module );
}
