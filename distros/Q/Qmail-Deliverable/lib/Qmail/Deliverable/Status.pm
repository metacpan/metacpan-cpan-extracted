package Qmail::Deliverable::Status;

use strict;
use 5.006;
use Exporter 'import';

our $VERSION = '1.12';

use constant {
    QD_NOT_DELIVERABLE         => 0x00,
    QD_UNKNOWN_PERM_DENIED     => 0x11,
    QD_UNKNOWN_PIPE            => 0x12,
    QD_UNKNOWN_BOUNCESAYING    => 0x13,
    QD_EZMLM                   => 0x14,
    QD_TEMPFAIL_GROUP_WRITABLE => 0x21,
    QD_TEMPFAIL_STICKY         => 0x22,
    QD_CLIENT_FAILURE          => 0x2f,
    QD_DELIVERABLE             => 0xf1,
    QD_VPOPMAIL_DIR            => 0xf2,
    QD_VPOPMAIL_VALIAS         => 0xf3,
    QD_VPOPMAIL_CATCHALL       => 0xf4,
    QD_VPOPMAIL_VUSER          => 0xf5,
    QD_VPOPMAIL_QMAIL_EXT      => 0xf6,
    QD_VPOPMAIL_NO_DOMAIN      => 0xfe,
    QD_NOT_LOCAL               => 0xff,
};

our @STATUS = qw(
    QD_NOT_DELIVERABLE
    QD_UNKNOWN_PERM_DENIED
    QD_UNKNOWN_PIPE
    QD_UNKNOWN_BOUNCESAYING
    QD_EZMLM
    QD_TEMPFAIL_GROUP_WRITABLE
    QD_TEMPFAIL_STICKY
    QD_CLIENT_FAILURE
    QD_DELIVERABLE
    QD_VPOPMAIL_DIR
    QD_VPOPMAIL_VALIAS
    QD_VPOPMAIL_CATCHALL
    QD_VPOPMAIL_VUSER
    QD_VPOPMAIL_QMAIL_EXT
    QD_VPOPMAIL_NO_DOMAIN
    QD_NOT_LOCAL
);

our @EXPORT_OK   = @STATUS;
our %EXPORT_TAGS = (
    all    => \@STATUS,
    status => \@STATUS,
);

1;

__END__

=head1 NAME

Qmail::Deliverable::Status - Status-code constants for Qmail::Deliverable

=head1 SYNOPSIS

    use Qmail::Deliverable::Status qw(:all);

    if ($rv == QD_DELIVERABLE)        { ... }
    if ($rv == QD_NOT_LOCAL)          { ... }
    if ($rv == QD_VPOPMAIL_CATCHALL)  { ... }

=head1 DESCRIPTION

Symbolic names for the integer status codes returned by
L<Qmail::Deliverable/deliverable> and
L<Qmail::Deliverable::Client/deliverable>. The numeric values are unchanged
from earlier releases; the constants exist purely for readability.

Loading this module has no side effects, which makes it safe to import
into unprivileged code that does not want to pull in the rest of
L<Qmail::Deliverable> (which reads C</var/qmail/control/*> at load time).

=head1 CONSTANTS

=over 4

=item C<QD_NOT_DELIVERABLE> (0x00)

The address is not deliverable.

=item C<QD_UNKNOWN_PERM_DENIED> (0x11)

Deliverability could not be determined because of file permissions.

=item C<QD_UNKNOWN_PIPE> (0x12)

A C<|>-command appears in the dot-qmail file.

=item C<QD_UNKNOWN_BOUNCESAYING> (0x13)

A C<bouncesaying> directive with extra program arguments.

=item C<QD_EZMLM> (0x14)

Probably deliverable: looks like an ezmlm mailing list.

=item C<QD_TEMPFAIL_GROUP_WRITABLE> (0x21)

Temporarily undeliverable: the home directory is group- or world-writable.

=item C<QD_TEMPFAIL_STICKY> (0x22)

Temporarily undeliverable: the home directory has the sticky bit set.

=item C<QD_CLIENT_FAILURE> (0x2f)

Returned only by L<Qmail::Deliverable::Client>; indicates the daemon could
not be reached.

=item C<QD_DELIVERABLE> (0xf1)

Deliverable, almost certainly: bare C<.qmail> or normal forwarding.

=item C<QD_VPOPMAIL_DIR> (0xf2)

Deliverable via vpopmail: a directory named after the local part exists.

=item C<QD_VPOPMAIL_VALIAS> (0xf3)

Deliverable via vpopmail: a C<valias> entry exists.

=item C<QD_VPOPMAIL_CATCHALL> (0xf4)

Deliverable via vpopmail: catch-all forwarding configured.

=item C<QD_VPOPMAIL_VUSER> (0xf5)

Deliverable via vpopmail: a virtual user exists.

=item C<QD_VPOPMAIL_QMAIL_EXT> (0xf6)

Deliverable via vpopmail: matched the C<qmail-ext> probe.

=item C<QD_VPOPMAIL_NO_DOMAIN> (0xfe)

vpopmail (vdelivermail) was detected but no domain was given in the address.

=item C<QD_NOT_LOCAL> (0xff)

The domain is not local.

=back

=head1 EXPORTS

Nothing by default. Pass C<:all> or C<:status> to import every constant,
or list individual ones explicitly.

=head1 SEE ALSO

L<Qmail::Deliverable>, L<Qmail::Deliverable::Client>

=cut
