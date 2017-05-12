
use strict;
use warnings;
use Test::More tests => 19;

sub not_in_file_ok {
    my ( $filename, %regex ) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while ( my $line = <$fh> ) {
        while ( my ( $desc, $regex ) = each %regex ) {
            if ( $line =~ $regex ) {
                push @{ $violated{$desc} ||= [] }, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    }
    else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok(
        $module => 'the great new $MODULENAME' => qr/ - The great new /,
        'boilerplate description'  => qr/Quick summary of what the module/,
        'stub function definition' => qr/function[12]/,
    );
}

TODO: {

    #  local $TODO = "Need to replace the boilerplate text";

    not_in_file_ok(
        README => "The README is used..." => qr/The README is used/,
        "'version information here'" => qr/to provide version information/,
    );

    not_in_file_ok( Changes => "placeholder date/time" => qr(Date/time) );

    module_boilerplate_ok('lib/Provision/Unix.pm');
    module_boilerplate_ok('lib/Provision/Unix/User.pm');
    module_boilerplate_ok('lib/Provision/Unix/User/Darwin.pm');
    module_boilerplate_ok('lib/Provision/Unix/User/FreeBSD.pm');
    module_boilerplate_ok('lib/Provision/Unix/User/Linux.pm');
    module_boilerplate_ok('lib/Provision/Unix/DNS.pm');
    module_boilerplate_ok('lib/Provision/Unix/DNS/BIND.pm');
    module_boilerplate_ok('lib/Provision/Unix/DNS/NicTool.pm');
    module_boilerplate_ok('lib/Provision/Unix/DNS/tinydns.pm');
    module_boilerplate_ok('lib/Provision/Unix/Web.pm');
    module_boilerplate_ok('lib/Provision/Unix/Utility.pm');
    module_boilerplate_ok('lib/Provision/Unix/VirtualOS.pm');
    module_boilerplate_ok('lib/Provision/Unix/VirtualOS/Linux.pm');
    module_boilerplate_ok('lib/Provision/Unix/VirtualOS/Linux/Xen.pm');
    module_boilerplate_ok('lib/Provision/Unix/VirtualOS/Linux/OpenVZ.pm');
    module_boilerplate_ok('lib/Provision/Unix/VirtualOS/FreeBSD/Jail.pm');
    module_boilerplate_ok('lib/Provision/Unix/VirtualOS/FreeBSD/Ezjail.pm');
}

