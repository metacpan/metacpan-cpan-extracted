package R3::rfcapi;
# Copyright (c) 1999 Johan Schoen. All rights reserved.

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw( );
@EXPORT_OK = qw( );

$VERSION = '0.32';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined R3::rfcapi macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap R3::rfcapi $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

R3::rfcapi - Perl extension for SAP's rfcsdk

=head1 SYNOPSIS

  use R3::rfcapi;

=head1 DESCRIPTION

R3::rfcapi is required by R3, R3::conn, R3::func and R3::itab.
The R3::rfcapi is not intended to be used directly. Use R3::conn,
R3::func and R3::itab which are the object interfaces. 

To compile and install R3::rfcapi you need RFCSDK from SAP AG.

=head1 AUTHOR

Johan Schoen, johan.schon@capgemini.se

=head1 SEE ALSO

perl(1), R3(3), R3::conn(3), R3::func(3), R3::itab(3)
and SAP's rfcsdk documentation.

=cut
