package Sys::LoadAvg;

use strict;

require Exporter;
require DynaLoader;

use vars qw( @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION);

@ISA = qw(Exporter DynaLoader);

use constant LOADAVG_1MIN  => 0;
use constant LOADAVG_5MIN  => 1;
use constant LOADAVG_15MIN => 2;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sys::LoadAvg ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
    loadavg LOADAVG_1MIN LOADAVG_5MIN LOADAVG_15MIN	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
    LOADAVG_1MIN LOADAVG_5MIN LOADAVG_15MIN	
);
$VERSION = '0.03';

bootstrap Sys::LoadAvg $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Sys::LoadAvg - Perl extension for accessing system CPU load averages.

=head1 SYNOPSIS

  use Sys::LoadAvg qw( loadavg );
  my @load = loadavg();

  print $load[LOADAVG_1MIN], $/;
  print $load[LOADAVG_5MIN], $/;
  print $load[LOADAVG_15MIN], $/;


=head1 DESCRIPTION

Module for accessing System load averages.

=head2 EXPORT

By default, the only exports are the constants LOADAVG_1MIN, LOADAVG_5MIN, and 
LOADAVG_15MIN. The loadavg() sub can be explicitly exported if desired.

=head1 AUTHOR

Jeremy Madea <jeremy@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2012 by Jeremy Madea

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=head1 SEE ALSO

L<perl>.

=cut
