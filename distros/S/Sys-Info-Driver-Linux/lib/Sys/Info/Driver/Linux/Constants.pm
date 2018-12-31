package Sys::Info::Driver::Linux::Constants;
$Sys::Info::Driver::Linux::Constants::VERSION = '0.7905';
use strict;
use warnings;
use base qw( Exporter );

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

our %EXPORT_TAGS = (
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

our @EXPORT_OK        = map { @{ $_ } } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::Driver::Linux::Constants

=head1 VERSION

version 0.7905

=head1 SYNOPSIS

=head1 DESCRIPTION

Constants for Linux driver.

=head1 NAME

Sys::Info::Driver::Linux::Constants - Constants for Linux driver

=head1 METHODS

None.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
