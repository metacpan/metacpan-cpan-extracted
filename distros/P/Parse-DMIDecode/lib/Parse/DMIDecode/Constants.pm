############################################################
#
#   $Id: Constants.pm 976 2007-03-04 20:47:36Z nicolaw $
#   Parse::DMIDecode::Constants - SMBIOS Constants
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package Parse::DMIDecode::Constants;
# vim:ts=4:sw=4:tw=78

use strict;
require Exporter;
use vars qw($VERSION $DEBUG
		@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
		@TYPES %GROUPS %TYPE2GROUP);

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@TYPES %GROUPS %TYPE2GROUP);
%EXPORT_TAGS = (all => \@EXPORT_OK);

$VERSION = '0.03' || sprintf('%d', q$Revision: 976 $ =~ /(\d+)/g);
$DEBUG ||= $ENV{DEBUG} ? 1 : 0;

@TYPES = ( # Description                    Index Group(s)
		'BIOS',                             # 0   bios
		'System',                           # 1   system
		'Base Board',                       # 2   baseboard
		'Chassis',                          # 3   chassis
		'Processor',                        # 4   processor
		'Memory Controller',                # 5   memory
		'Memory Module',                    # 6   memory
		'Cache',                            # 7   cache
		'Port Connector',                   # 8   connector
		'System Slots',                     # 9   slot
		'On Board Devices',                 # 10  baseboard
		'OEM Strings',                      # 11
		'System Configuration Options',     # 12  system
		'BIOS Language',                    # 13  bios
		'Group Associations',               # 14
		'System Event Log',                 # 15  system
		'Physical Memory Array',            # 16  memory
		'Memory Device',                    # 17  memory
		'32-bit Memory Error',              # 18
		'Memory Array Mapped Address',      # 19
		'Memory Device Mapped Address',     # 20
		'Built-in Pointing Device',         # 21
		'Portable Battery',                 # 22
		'System Reset',                     # 23  system
		'Hardware Security',                # 24
		'System Power Controls',            # 25
		'Voltage Probe',                    # 26
		'Cooling Device',                   # 27
		'Temperature Probe',                # 28
		'Electrical Current Probe',         # 29
		'Out-of-band Remote Access',        # 30
		'Boot Integrity Services',          # 31
		'System Boot',                      # 32  system
		'64-bit Memory Error',              # 33
		'Management Device',                # 34
		'Management Device Component',      # 35
		'Management Device Threshold Data', # 36 
		'Memory Channel',                   # 37
		'IPMI Device',                      # 38
		'Power Supply'                      # 39
	);

%GROUPS = (
		'bios'      => [ qw(0 13) ],
		'system'    => [ qw(1 12 15 23 32) ],
		'baseboard' => [ qw(2 10) ],
		'chassis'   => [ qw(3) ],
		'processor' => [ qw(4) ],
		'memory'    => [ qw(5 6 16 17) ],
		'cache'     => [ qw(7) ],
		'connector' => [ qw(8) ],
		'slot'      => [ qw(9) ],
	);

%TYPE2GROUP = ();
for my $group (keys %GROUPS) {
	for my $dmitype (@{$GROUPS{$group}}) {
		$TYPE2GROUP{$dmitype} = $group;
	}
}


1;


=pod

=head1 NAME

Parse::DMIDecode::Constants - SMBIOS Constants

=head1 SYNOPSIS

 use strict;
 use Parse::DMIDecode::Constants qw(@TYPES %GROUPS);
 
=head1 DESCRIPTION

This module provides and can export constants relating to the SMBIOS
specification and dmidecode interface command.

=head1 EXPORTS

=head2 @TYPES

=head2 %GROUPS

=head1 SEE ALSO

L<Parse::DMIDecode>

=head1 VERSION

$Id: Constants.pm 976 2007-03-04 20:47:36Z nicolaw $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

If you like this software, why not show your appreciation by sending the
author something nice from her
L<Amazon wishlist|http://www.amazon.co.uk/gp/registry/1VZXC59ESWYK0?sort=priority>? 
( http://www.amazon.co.uk/gp/registry/1VZXC59ESWYK0?sort=priority )

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut


__END__



