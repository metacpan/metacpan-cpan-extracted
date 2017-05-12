package Qmail::Deliverable;

use strict;
use 5.006;
use Carp qw(carp);
use base 'Exporter';

our $VERSION = '1.07';
our @EXPORT_OK = qw/reread_config qmail_local dot_qmail deliverable qmail_user/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VPOPMAIL_EXT = 0;

# rfc2822's "atext"
my $atext = "[A-Za-z0-9!#\$%&\'*+\/=?^_\`{|}~-]";
my $valid = qr/^(?!.*\@.*\@)($atext+(?:[\@.]$atext+)*)\.?\z/;

# disallow control characters and non-ascii
my $ascii = qr/^([\x20-\x7e]*)\z/;

# parse shell line
my $shell_sq = qr/'[^']+'/;  # no escaping in single quotes!
my $shell_dq = qr/(?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\"))/;  # from Regexp::Common
my $shell_bare = qr/[^"'\\\s]+/;  # no sq, dq, backslash, or space
my $shell_token = qr/(\\.|$shell_sq|$shell_dq|$shell_bare)+/;

sub _readpipe {
    my ($command, @args) = @_;
    local %ENV = ();
    open my $fh, '-|', $command, @args or die "open: @_: $!";
    my @data = readline $fh;
    close $fh;  # Without explicit close, $? is unreliable later
    return wantarray ? @data : join("", @data);
}

sub _slurp {
    my ($fn) = @_;
    open my $fh, '<', $fn or return;
    return wantarray ? readline $fh : join("", readline $fh);
}

sub _first (&@) {
    my $sub = shift;
    $sub->($_) and return $_ for @_;
    return;
}

sub _findinpath {
    my ($command) = @_;
    # Attempt to retain some level of security against PATH attacks
    my @path = grep defined, map /($ascii)/,  # untaint
        grep m{^/[^<>|]+$}, split /:/, $ENV{PATH};
    return _first { -x $_ } map "$_/$command", @path;
}

# Resolve only once to further reduce risk of PATH attacks
my $valias_exec = _findinpath 'valias';
my $vuser_exec = _findinpath 'vuserinfo';

my %locals;
my %virtualdomains;
my %users_exact;
my %users_wild;

sub reread_config {
    %locals         = ();
    %virtualdomains = ();
    %users_exact    = ();
    %users_wild     = ();
    my $locals_fn = -e "/var/qmail/control/locals"
        ? "/var/qmail/control/locals"
        : "/var/qmail/control/me";
    for (_slurp $locals_fn) {
        chomp;
        ($_) = lc =~ /$ascii/ or do { warn "Invalid character"; next; };
        $locals{$_} = 1;
    }
    for (_slurp "/var/qmail/control/virtualdomains") {
        chomp;
        ($_) = lc =~ /$ascii/ or do { warn "Invalid character"; next; };
        my ($domain, $prepend) = split /:/, $_, 2;
        $virtualdomains{$domain} = $prepend;
    }
    for (_slurp "/var/qmail/users/assign") {
        chomp;
        ($_) = /$ascii/ or do { warn "Invalid character"; next; };
        if (s/^=([^:]+)://) {
            $users_exact{lc $1} = $_;
        } elsif (s/^\+([^:]+)://) {
            $users_wild{lc $1} = $_;
        } elsif (/^\.$/) {
            last;
        } else {
            warn "Invalid line in users/assign: '$_'\n";
        }
    }
}

sub _qmail_getpw {
    my ($local) = @_;
    local $/ = "\0";
    my @a = _readpipe "/var/qmail/bin/qmail-getpw", $local;
    chomp @a;
    for (@a) {
        ($_) = /$ascii/ or do { warn "Invalid character"; return ""; }
    }
    return @a;
}

sub _prepend {
    my ($domain) = @_;

    return $virtualdomains{$domain} if exists $virtualdomains{$domain};

    my @parts = split /\./, $domain;
    for (reverse 1 .. @parts) {
        my $wildcard = join "", map ".$_", @parts[-$_ .. -1];
        return $virtualdomains{$wildcard} if exists $virtualdomains{$wildcard};
    }

    return $virtualdomains{''} if exists $virtualdomains{''};
    return undef;
}

sub _potential_exts {
    my ($ext) = @_;
    my @exts;

    # Exact match has highest precedence
    push @exts, $ext;  # user, or user-ext

    # Then user-default
    my @parts = split /(-)/, $ext;
    for (reverse 1 .. $#parts) {
        next unless $parts[$_] eq '-';
        push @exts, join("", @parts[0..$_]) . "default";
    }

    return @exts;
}


sub qmail_user {
    my ($in) = @_;
    my ($local) = lc($in) =~ /$valid/
        or do { carp "Invalid address: $in"; return; };

    if (exists $users_exact{$local}) {
        return split /:/, $users_exact{$local}, 7;  # colon terminated
    } else {
        for (reverse 1 .. length $local) {
            my $try = substr $local, 0, $_;
            if (exists $users_wild{$try}) {
                my @assign = split /:/, $users_wild{$try}, 7;
                $assign[5] = substr($local, $_) . $assign[5];
                return @assign;
            }
        }
    }

    return _qmail_getpw $local;
}

sub qmail_local {
    my ($in) = @_;
    my ($address) = lc($in) =~ /$valid/ or
        do { carp "Invalid address: $in"; return; };

    return $address if $address !~ /\@/;
    my ($local, $domain) = split /\@/, $address;

    return $local if exists $locals{$domain};

    my $prepend = _prepend $domain;
    return "$prepend-$local" if defined $prepend;

    return undef;
}

sub dot_qmail {
    my ($user, $uid, $gid, $homedir, $dash, $ext) = @_;
    if (@_ == 1) {
        my ($in) = @_;
        my ($address) = lc($in) =~ /$valid/
            or do { carp "Invalid address: $in"; return; };

        my $local = qmail_local $address;
        return undef if not defined $local;

        ($user, $uid, $gid, $homedir, $dash, $ext) = qmail_user $local;
    }

    $ext =~ s/\./:/g;

    my $dashext = $dash . $ext;

    if (not length $dashext) {
        return "$homedir/.qmail" if -e "$homedir/.qmail";
        return "";  # defaultdelivery
    }

    for ( _potential_exts($ext), 'default' ) {
        return "$homedir/.qmail-$_" if -e "$homedir/.qmail-$_";
    }

    return undef;
}

sub valias {
    my ($address) = @_;
    if (not $valias_exec) {
        warn "Cannot check valias; valias executable not found";
        return 0;
    }
    my ($local, $domain) = split /\@/, $address;
    for ( _potential_exts($local) ) {
        eval { _readpipe( $valias_exec, "$_\@$domain") };
        return 1 if $? == 0;
    };
    return 0;
}

sub vuser {
    my ($address) = @_;
    if (not $vuser_exec) {
        warn "Cannot check vuser; vuser executable not found";
        return 0;
    }
    eval { _readpipe $vuser_exec, $address } or return 0;
    return 1 if $? == 0;
    return 0;
}

sub deliverable {
    my ($in) = @_;
    my ($address) = lc($in) =~ /$valid/
        or do { carp "Invalid address: $in"; return; };

    my $local = qmail_local $address;
    return 0xff if not defined $local;

    my ($user, $uid, $gid, $homedir, $dash, $ext) = qmail_user $local;

    return 0x11 if not -r $homedir or not -x _;
    return 0x21 if (stat _)[2] & 0020;  # group writable
    return 0x21 if (stat _)[2] & 0002;  # world writable
    return 0x22 if -T _;

    my $dot_qmail = dot_qmail $user, $uid, $gid, $homedir, $dash, $ext;

    return 0x00 if not defined $dot_qmail;
    return 0xf1 if not length $dot_qmail;  # no .qmail => defaultdelivery

    return 0x00 if not -e $dot_qmail;
    return 0x11 if not -r $dot_qmail;
    return 0xf1 if not -s _;  # empty => defaultdelivery

    my @dot_qmail = _slurp $dot_qmail;

    if ($dot_qmail[0] =~ /^\|\s*\S*vdelivermail/) {
        if ($address !~ /\@/) {
            carp "vpopmail support not available if no domain given";
            return 0xfe;
        }
        my $origlocal = (split /\@/, $address)[0];

        # Update domain with user field in assign file, just like vpopmail
        # does. This way we support alias domains. See vpopmail.c,
        # vget_assign().
        $address = $origlocal . '@' . $user;

        if ($dot_qmail[0] =~ /bounce-no-mailbox/) {
            return 0xf2 if -d "$homedir/$origlocal";
            return 0xf3 if valias $address;
            return 0xf5 if vuser $address;
            if ( $VPOPMAIL_EXT ) {
                my ($local, $domain) = split /@/, $address;
                my @chunks = split /\-/, $local; # vpopmails qmail-ext option
                for ( 0 .. $#chunks ) {
                    return 0xf6 if vuser $chunks[$_] .'@'.$domain;
                };
            };
            return 0x00;
        }
        return 0xf4;
    }
    if ($dot_qmail[0] =~ /^\|bouncesaying\s+(.*)/) {
        my @args = $1 =~ /$shell_token/g;
        return 0x13 if @args > 1;
        return 0x00;
    }

    return 0x12 if grep /^\|/, @dot_qmail;

    return 0xf1;
}

reread_config;

# use Memoize;
# use Memoize::Expire;
# tie my %deliverable_cache, 'Memoize::Expire', LIFETIME => 60;
# memoize 'deliverable';

1;

__END__

=head1 NAME

Qmail::Deliverable - Determine deliverability of local addresses

=head1 SYNOPSIS

In a qpsmtpd plugin:

    use Qmail::Deliverable ':all';

    return DECLINED if not qmail_local $recip;
    return DECLINED if deliverable $recip;
    return DENY, "Who's that?";

Probably also pretty useful:

    my $dot_qmail_filename = dot_qmail 'foo@example.com';

=head1 DESCRIPTION

qmail-smtpd does not know if a user exists. Lots of resources are wasted by
scanning mail for spam and viruses for addresses that do not exist anyway,
including the annoying I<backscatter> or I<outscatter> phenomenon.

A replacement smtpd written in Perl could use this module to quickly verify
that a local email address is (probably) actually in use. Qmail::Delivery uses
the same logic that qmail itself (in qmail-send/lspawn/local) uses.

=head2 Bundled software

This module comes with a daemon program called qmail-deliverabled and a module
called Qmail::Deliverable::Client that provides access to qmail_local and
deliverable through via daemon. Typically, the daemon runs as the root
user, and the client is used by the unprivileged smtpd.

=head2 Functions

All documented functions are exportable, and a tag :all is available for
convenience.

Note that addresses and local user names must be in user@domain form, just like
qmail internally uses. Comments, angle brackets, etcetera, must be stripped
before you pass the address to these functions. Addresses and local user names
may not begin with a dot, have two subsequent dots, have a dot before or after
the @, have a dot at the beginning, or have any characters that are not
in rfc2822's C<atext> definition, with the exception of at most one "@". Given
an invalid address, a warning is emitted and an empty list or undef is
returned. A single dot at the end is allowed but ignored.

=over 4

=item qmail_local $address

Returns the local qmail user for $address, or undef if the address is not local.

Returns $address if it does not contain an @. Returns the left side of the @ if
the right side is listed in /var/qmail/control/locals. Returns the left side of
the @, prepended with the right prepend string, if the right side is listed in
/var/qmail/control/virtualdomains.

=item qmail_user $address

=item qmail_user $local

Returns a list of $user, $uid, $gid, $homedir, $dash, $ext according to
/var/qmail/users/assign or qmail-getpw.

=item dot_qmail $address

=item dot_qmail $user, $uid, $gid, $homedir, $dash, $ext

Returns the relevant dot-qmail filename for the given user info. Returns an
empty string if a bare ".qmail" (without extension) does not exist, because
that needs to be treated specially (defaultdelivery). Returns undef when the
given $address is not local, and when no dot-qmail file was found.

No string validation is done if more than one argument is passed.

=item deliverable $address

=item deliverable $local

Returns true if the address is locally deliverable (or temporarily
undeliverable), according to rules described in L<dot-qmail>. Also returns true
if deliverability could not be determined.

The system default delivery method, and mailbox, maildir, and forward
instructions in dot-qmail files, are assumed to always succeed.

Possible return values are:

    0x00   Not deliverable

    0x11   Deliverability unknown: permission denied for any file
    0x12   Deliverability unknown: qmail-command called in dot-qmail file
    0x13   Deliverability unknown: bouncesaying with program

    0x21   Temporarily undeliverable: group/world writable
    0x22   Temporarily undeliverable: homedir is sticky

    0xf1   Deliverable, almost certainly
    0xf2   Deliverable, vdelivermail: directory exists
    0xf3   Deliverable, vdelivermail: valias exists
    0xf4   Deliverable, vdelivermail: catch-all defined
    0xf5   Deliverable, vdelivermail: vuser exists
    0xf6   Deliverable, vdelivermail: qmail-ext

    0xfe   vpopmail (vdelivermail) detected but no domain was given
    0xff   Domain is not local

(These values are, currently, not bitmasks. Do not treat them as such.)

For qmail-ext support (a vpopmail feature that is disabled by default), set
C<$Qmail::Deliverable::VPOPMAIL_EXT = 1>.

Status 0x12 is returned if any command is found in a dot-qmail file, regardless
of its position relative to mailbox, maildir, and forward instructions.

A special case exists for vpopmail. If a dot-qmail file and calls (on the first
line) a program with "vdelivermail" in the command name, then 0x00 or 0xf2 is
returned. 0x00 is returned if the line also contains "bounce-no-mailbox" and
no directory exists by the name of the local part of the address. B<For this to
work, the full address (including C<@domain>) must be given.>

Another special case exists for bouncesaying (used by Plesk). 0x00 or 0x13 is
returned.

=item reread_config

Re-reads the config files /var/qmail/control/locals,
/var/qmail/control/virtualdomains, and /var/qmail/users/assign.

=back

=head1 CAVEATS

Although C<bouncesaying> and C<vpopmail's vdeliver> are special cased, normally
if you have a catch-all .qmail-default and let a program do all the work, this
module cannot determine deliverability in a useful way, because it would
need to execute the program. It failsafes by allowing delivery.

This module does NOT support user-ext characters other than hyphen (dash). i.e.
".qmail+default" is not supported.

The "percent hack" (user%domain@ignored) is not supported.

The error message passed to bouncesaying is ignored. The default "No mailbox
here by that name" is used.

Addresses are lower cased before comparison, but having upper cased user names
or domain names in configuration may or may not work.

This module is relatively new and has not been used in production for a very
long time.

CDB files are not supported (yet). The plain text source files are used.

This is not a replacement for existing relay checks. You still need those.

Don't forget to escape C<@> as C<\@> when testing with double quoted strings.

=head1 PERFORMANCE

The server on which I benchmarked this, easily reached 10_000 deliverability
checks per second for assigned/virtual users. Real and virtual users are much
slower. For my needs, this is still plenty fast enough.

To support local users automatically, C<qmail-getpw> is executed for local
addresses that are not matched by /var/qmail/users/assign. If you need it
faster, you can use C<qmail-pw2u> to build a users/assign file.

To support vpopmail's vdelivermail instruction, C<valias> is executed for
virtual email addresses, to test if a valias exists. If performance is a big
issue, you could monkeypatch the valias subroutine in this module to access
mysql directly, or if you don't use the valias mechanism at all, to always
return false. (Or chmod -x all valias executables in your path.) Valias
checking is only used for vdelivermail instructions, and does not impose
performance penalties on non-vpopmail systems.

To support vpopmail's vdelivermail instruction on systems that use a "hashed"
user directory tree, C<vuserinfo> is executed for virtual email addresses, to
test if a virtual user exists. To optimize the common case, this is only done
if a directory with the same name as the local-part does not exist. Such
directories are made by vpopmail for the first 100 users in a virtual
domain. If performance is a big issue, you could monkeypatch the vuser
subroutine in this module to access mysql directly. Vuser checking is only
used for vdelivermail instructions, and does not impose performance
penalties on non-vpopmail systems.

Rough linear performance benchmark of C<deliverable> on our test machine:

    vpopmail domain, vuser with top level dir   11000/s
    vpopmail domain, valias exists               1500/s
    vpopmail domain, vuser with hashed dir       1400/s
    vpopmail domain, address unknown             1400/s
    local, user listed in users/assign          15000/s
    local, user exists, not listed               2000/s
    local, user unknown                          1800/s
    experimental caching enabled               200000/s

To play with the experimental caching, see the four commented lines in the
source code.

=head1 UNICODE SUPPORT

This module refuses non-ASCII data. If anyone out there actually uses non-ASCII
data or control characters in their mail configuration, I'd like to learn about
the circumstances. Please email me.

=head1 LEGAL

This software is released into the public domain, and does not come with
warranty or guarantee of any kind. Use it at your own risk.

=head1 AUTHOR

Juerd Waalboer <#####@juerd.nl>
