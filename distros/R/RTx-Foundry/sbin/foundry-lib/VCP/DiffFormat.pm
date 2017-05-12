package VCP::DiffFormat ;

=head1 NAME

    VCP::DiffFormat - special diff format for VCP

=head1 SYNOPSIS

    diff $a, $b { STYLE => "VCP::DiffFormat" };

=head1 DESCRIPTION

This is a plugin output formatter for Text::Diff that generates "unified" style
diffs without headers.  VCP::Dest::revml uses this to output differences for
several reasons:

=over

=item *

The Unix C<diff> command is not available on all platforms by default,
specifically WinNT.

=item *

The two line "file header" is not needed in RevML, since the meta information
is captured elsewhere in the <rev> element, and the name and mtime
of the files being compared is irrellevant; they're just some temporary files
somewhere

=item *

Because RevML offers MD5 hashes of the file to verify that a diff was applied
properly, all of the "-" lines present in a normal unified diff are not
necesssary.  They are left in now for ease of debugging with RevML files, but
may be stripped out to conserve space.

=cut

@ISA = qw( Text::Diff::Unified );

use strict;
use Text::Diff;
use Carp;

sub file_header { "" }

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1
