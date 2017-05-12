package Template::Plugin::GnuPG;

# ----------------------------------------------------------------------
# $Id: GnuPG.pm,v 1.1.1.1 2004/10/08 13:38:07 dlc Exp $
# ----------------------------------------------------------------------
# Template::Plugin::GnuPG -- A TT2 plugin for GnuPG
# Copyright (C) 2004 darren chamberlain <darren@cpan.org>
# ----------------------------------------------------------------------

use strict;
use base qw(Template::Plugin::Filter);
use vars qw($VERSION $REVISION);

$VERSION = 0.01;    # $Date: 2004/10/08 13:38:07 $
$REVISION = sprintf "%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/;

use GnuPG;
use IO::File;
use File::Temp qw(tempfile);

# ----------------------------------------------------------------------
# init(\%gpg_config)
#
# Create the GnuPG object, based on the configuration params passed to
# the plugin.
# ----------------------------------------------------------------------
sub init {
    my $self = shift;

    $self->{ _DYNAMIC } = 1;
    $self->{ _GNUPG   } = GnuPG->new(%{ $self->{ _CONFIG } ||= { } });

    return $self;
}

# ----------------------------------------------------------------------
# filter($text, $args, $conf)           [% FILTER $GnuPG KEY, OPTIONS %]
#
# Encrypt the filtered text to KEY, modified by OPTIONS
# ----------------------------------------------------------------------
sub filter {
    my ($self, $text, $args, $conf) = @_;
    my $gpg = $self->{ _GNUPG };
    my ($in_fh, $in_file) = tempfile("gpgXXXXX", UNLINK => 0);
    my ($out_fh, $out_file) = tempfile("gpgXXXXX", UNLINK => 0);
    my $ciphertext;

    print $in_fh $text or die "Can't write to '$in_fh': $!";
    close $in_fh or die "Can't close tempfile '$in_fh': $!";

    # $args is mostly ignored; if it exists, assume it contains the
    # keyid, and use it in preference to a key => value pair
    $conf = $self->merge_config($conf);
    $conf->{ recipient } = $args->[0] if ($args && @$args);
    $conf->{ armor } = 1 unless defined $conf->{ armor };

    $gpg->encrypt(
        %$conf,
        plaintext   => $in_file, 
        output      => $out_fh,
    );
    close $out_fh;

    $in_fh = IO::File->new($out_file) or die "Can't open '$out_file': $!";
    local $/;
    $ciphertext = <$in_fh>;
    close $in_fh;

    unlink $in_file, $out_file;

    return $ciphertext;
}

1;

__END__

=head1 NAME

Template::Plugin::GnuPG -- A simple encryption plugin

=head1 SYNOPSIS

    [% USE GnuPG %]
    [% FILTER $GnuPG recipient = '0xb56165aa' armor = 1 %]
    Your new password is 'password'.
    [% END %]

=head1 DESCRIPTION

C<Template::Plugin::GnuPG> provides a simple way to encrypt text
through C<gnupg>, using Francis J. Lacoste's C<GnuPG> module.  The
resulting text is encrypted to the key specified by the C<recipient>
parameter to the FILTER.

C<Template::Plugin::GnuPG> takes all of the configuration parameters
that C<GnuPG> takes; pass constructor parameters as C<name = value>
pairs to the C<USE> line, and all other parameters as C<name = value>
pairs to the C<FILTER> call:

    [% USE GnuPG gnupg_path = '/opt/bin/gpg' trace = 1 %]

    [% FILTER $GnuPG recipient = "mom@example.com" armor = 1 %]
    The recipe for Neiman-Marcus cookies is:
    [% recipe %]
    [% END %]

The C<recipient> parameter can be a keyid (like C<0xB56165AA>) or an
email address.  You can also specify symmetric encryption by passing
the C<symmetric> key with a true value (in this case, C<GnuPG> makes
you specify a passphrase with the C<passphrase> option).

Output is ASCII armored by default, unless you pass an explicit
C<armor = 0> to the C<FILTER> call:

    [% text | $GnuPG symmetric = 1 passphrase = pw armor = 0 %]

=head1 TODO

=over 4

=item *

Add a reasonable way to sign as well.  You can currently sign like so:

    [% FILTER $GnuPG recipient = 'foo@example.com' sign = 1 passphrase = pw %]

where C<pw> is the passphrase for I<your> key (the signing key).
That's pretty ugly, though; who wants their passphrase in the source
templates?

=item *

Better documentation

=item *

More tests.

=head1 SEE ALSO

L<Template::Plugin::Filter>, L<GnuPG>
