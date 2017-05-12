package Sys::Info::Driver::Linux::Constants;
use strict;
use warnings;
use vars qw( $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS );
use base qw( Exporter );

$VERSION = '0.7903';

# uptime
use constant UP_TIME          => 0;
use constant IDLE_TIME        => 1;

# fstab entries
use constant FS_SPECIFIER     => 0;
use constant MOUNT_POINT      => 1;
use constant FS_TYPE          => 2;
use constant MOUNT_OPTS       => 3;
use constant DUMP_FREQ        => 4;
use constant FS_CHECK_ORDER   => 5;

# getpwnam()
use constant REAL_NAME_FIELD  => 6;

# format: 'Linux version 1.2.3 (foo@bar.com)'
# format: 'Linux version 1.2.3 (foo@bar.com) (gcc 1.2.3)'
# format: 'Linux version 1.2.3 (foo@bar.com) (gcc 1.2.3 (Redhat blah blah))'
use constant RE_LINUX_VERSION => qr{
   \A
   Linux \s+ version \s
   (.+?)
   \s
   [(] .+? \@ .+? [)]
   (.*?)
   \z
}xmsi;

# format: 'linux foo.domain.bar 1.2.3-foo'
use constant RE_LINUX_VERSION2 => qr{
   \A
   linux \s+ [a-zA-Z0-9.]+ \s+
   ([a-zA-Z0-9.]+)?
}xmsi;

%EXPORT_TAGS = (
    uptime => [qw/
                    UP_TIME
                    IDLE_TIME
                  /],
    fstab => [qw/
                    FS_SPECIFIER
                    MOUNT_POINT
                    FS_TYPE
                    MOUNT_OPTS
                    DUMP_FREQ
                    FS_CHECK_ORDER
                    /],
    user => [qw/
                    REAL_NAME_FIELD
                    /],
    general => [qw/
                    RE_LINUX_VERSION
                    RE_LINUX_VERSION2
                    /],
);

@EXPORT_OK        = map { @{ $_ } } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;

1;

__END__

=head1 NAME

Sys::Info::Driver::Linux::Constants - Constants for Linux driver

=head1 SYNOPSIS

=head1 DESCRIPTION

This document describes version C<0.7903> of C<Sys::Info::Driver::Linux::Constants>
released on C<8 May 2013>.

Constants for Linux driver.

=head1 METHODS

None.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2013 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
=cut
