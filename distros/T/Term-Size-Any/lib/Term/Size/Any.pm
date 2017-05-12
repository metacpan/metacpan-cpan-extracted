
package Term::Size::Any;

use strict;
use vars qw( $VERSION );

$VERSION = '0.002';

sub _require_any {
    my $package;

    if ( $^O eq 'MSWin32' ) {
        require Term::Size::Win32;
        $package = 'Term::Size::Win32';

    } else {
        #require Best;
        #my @modules = qw( Term::Size::Perl Term::Size Term::Size::ReadKey );
        #Best->import( @modules );
        #$package = Best->which( @modules );
        require Term::Size::Perl;
        $package = 'Term::Size::Perl';

    }
    $package->import( qw( chars pixels ) ); # allows Term::Size::Any::chars
    return $package;
}

sub import {
    my $self = shift;
    my $package = _require_any;
    unshift @_, $package;
    my $import_sub = $package->can('import');
    goto &$import_sub;
}

1;
