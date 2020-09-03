# Create a PGP signature for data, securely.
#
# THIS IS NOT A GENERAL PGP MODULE.
#
# For a general PGP module that handles encryption and decryption, key ring
# management, and all of the other wonderful things you want to do with PGP,
# see the PGP module directory on CPAN.  This module is designed to do one and
# only one thing and do it fast, well, and securely -- create and check
# detached signatures for some block of data.
#
# This above all: to thine own self be true,
# And it must follow, as the night the day,
# Thou canst not then be false to any man.
#                               -- William Shakespeare, _Hamlet_
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

##############################################################################
# Modules and declarations
##############################################################################

package PGP::Sign 1.02;

use 5.020;
use autodie;
use warnings;

use Carp qw(croak);
use Exporter qw(import);
use File::Temp ();
use IO::Handle;
use IPC::Run qw(finish run start timeout);
use Scalar::Util qw(blessed);

# Export pgp_sign and pgp_verify by default for backwards compatibility.
## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT    = qw(pgp_sign pgp_verify);
our @EXPORT_OK = qw(pgp_error);
## use critic

# The flags to use with the various PGP styles.
my %SIGN_FLAGS = (
    GPG => [
        qw(
          --detach-sign --armor
          --quiet --textmode --batch --no-tty --pinentry-mode=loopback
          --no-greeting --no-permission-warning
          ),
    ],
    GPG1 => [
        qw(
          --detach-sign --armor
          --quiet --textmode --batch --no-tty --no-use-agent
          --no-greeting --no-permission-warning
          --force-v3-sigs --allow-weak-digest-algos
          ),
    ],
);
my %VERIFY_FLAGS = (
    GPG => [
        qw(
          --verify
          --quiet --batch --no-tty
          --no-greeting --no-permission-warning
          --no-auto-key-retrieve --no-auto-check-trustdb
          --allow-weak-digest-algos
          --disable-dirmngr
          ),
    ],
    GPG1 => [
        qw(
          --verify
          --quiet --batch --no-tty
          --no-greeting --no-permission-warning
          --no-auto-key-retrieve --no-auto-check-trustdb
          --allow-weak-digest-algos
          ),
    ],
);

##############################################################################
# Old global variables
##############################################################################

# These variables are part of the legacy PGP::Sign interface and are
# maintained for backward compatibility.  They are only used by the legacy
# pgp_sign and pgp_verify functions, not by the new object-oriented API.

# Whether or not to perform some standard whitespace munging to make other
# signing and checking routines happy.
our $MUNGE = 0;

# The default path to PGP.  PGPS is for signing, PGPV is for verifying.
# (There's no reason to use separate commands any more, but with PGPv5 these
# were two different commands, so this became part of the legacy API.)
our $PGPS;
our $PGPV;

# The path to the directory containing the key ring.  If not set, defaults to
# $ENV{GNUPGHOME} or $HOME/.gnupg.
our $PGPPATH;

# What style of PGP invocation to use by default.  If not set, defaults to the
# default style for the object-oriented API.
our $PGPSTYLE;

# The directory in which temporary files should be created.  If not set,
# defaults to whatever File::Temp decides to use.
our $TMPDIR;

# Used by pgp_sign and pgp_verify to store errors returned by the
# object-oriented API so that they can be returned via pgp_error.
my @ERROR = ();

##############################################################################
# Utility functions
##############################################################################

# print with error checking and an explicit file handle.  autodie
# unfortunately can't help us with these because they can't be prototyped and
# hence can't be overridden.
#
# $fh   - Output file handle
# @args - Remaining arguments to print
#
# Returns: undef
#  Throws: Text exception on output failure
sub _print_fh {
    my ($fh, @args) = @_;
    print {$fh} @args or croak("print failed: $!");
    return;
}

##############################################################################
# Object-oriented interface
##############################################################################

# Create a new PGP::Sign object encapsulating the configuration.
#
# $args_ref - Anonymous hash of arguments with the following keys:
#   home   - Path to the GnuPG homedir containing keyrings
#   munge  - Boolean indicating whether to munge whitespace
#   path   - Path to the GnuPG binary to use
#   style  - Style of OpenPGP backend to use
#   tmpdir - Directory to use for temporary files
#
# Returns: Newly created object
#  Throws: Text exception for an invalid OpenPGP backend style
sub new {
    my ($class, $args_ref) = @_;

    # Check the style argument.
    my $style = $args_ref->{style} || 'GPG';
    if ($style ne 'GPG' && $style ne 'GPG1') {
        croak("Unknown OpenPGP backend style $style");
    }

    # If path is not given, set a default based on the style.
    my $path = $args_ref->{path} // lc($style);

    # Create and return the object.
    my $self = {
        home   => $args_ref->{home},
        munge  => $args_ref->{munge},
        path   => $path,
        style  => $style,
        tmpdir => $args_ref->{tmpdir},
    };
    bless($self, $class);
    return $self;
}

# This function actually sends the data to a file handle.  It's necessary to
# implement munging (stripping trailing spaces on a line).
#
# $fh     - The file handle to which to write the data
# $string - The data to write
sub _write_string {
    my ($self, $fh, $string) = @_;

    # If there were any left-over spaces from the last invocation, prepend
    # them to the string and clear them.
    if ($self->{spaces}) {
        $string = $self->{spaces} . $string;
        $self->{spaces} = q{};
    }

    # If whitespace munging is enabled, strip any trailing whitespace from
    # each line of the string for which we've seen the newline.  Then, remove
    # and store any spaces at the end of the string, since the newline may be
    # in the next chunk.
    #
    # If there turn out to be no further chunks, this removes any trailing
    # whitespace on the last line without a newline, which is still correct.
    if ($self->{munge}) {
        $string =~ s{ [ ]+ \n }{\n}xmsg;
        if ($string =~ s{ ([ ]+) \Z }{}xms) {
            $self->{spaces} = $1;
        }
    }

    _print_fh($fh, $string);
    return;
}

# This is our generic "take this data and shove it" routine, used both for
# signature generation and signature checking.  Scalars, references to arrays,
# references to IO::Handle objects, file globs, references to code, and
# references to file globs are all supported as ways to get the data, and at
# most one line at a time is read (cutting down on memory usage).
#
# References to code are an interesting subcase.  A code reference is executed
# repeatedly, passing whatever it returns to GnuPG, until it returns undef.
#
# $fh      - The file handle to which to write the data
# @sources - The data to write, in any of those formats
sub _write_data {
    my ($self, $fh, @sources) = @_;
    $self->{spaces} = q{};

    # Deal with all of our possible sources of input, one at a time.
    #
    # We can't do anything interesting or particularly "cool" with references
    # to references, so those we just print.  (Perl allows circular
    # references, so we can't just dereference references to references until
    # we get something interesting.)
    for my $source (@sources) {
        if (ref($source) eq 'ARRAY') {
            for my $chunk (@$source) {
                $self->_write_string($fh, $chunk);
            }
        } elsif (ref($source) eq 'GLOB' || ref(\$source) eq 'GLOB') {
            while (defined(my $chunk = <$source>)) {
                $self->_write_string($fh, $chunk);
            }
        } elsif (ref($source) eq 'SCALAR') {
            $self->_write_string($fh, $$source);
        } elsif (ref($source) eq 'CODE') {
            while (defined(my $chunk = &$source())) {
                $self->_write_string($fh, $chunk);
            }
        } elsif (blessed($source)) {
            if ($source->isa('IO::Handle')) {
                while (defined(my $chunk = <$source>)) {
                    $self->_write_string($fh, $chunk);
                }
            } else {
                $self->_write_string($fh, $source);
            }
        } else {
            $self->_write_string($fh, $source);
        }
    }
    return;
}

# Construct the command for signing.  This will expect the passphrase on file
# descriptor 3.
#
# $keyid - The OpenPGP key ID with which to sign
#
# Returns: List of the command and arguments.
sub _build_sign_command {
    my ($self, $keyid) = @_;
    my @command = ($self->{path}, '-u', $keyid, qw(--passphrase-fd 3));
    push(@command, @{ $SIGN_FLAGS{ $self->{style} } });
    if ($self->{home}) {
        push(@command, '--homedir', $self->{home});
    }
    return @command;
}

# Construct the command for verification.  This will send all logging to
# standard output and the status messages to file descriptor 3.
#
# $signature_file - Path to the file containing the signature
# $data_file      - Path to the file containing the signed data
#
# Returns: List of the command and arguments.
sub _build_verify_command {
    my ($self, $signature_file, $data_file) = @_;
    my @command = ($self->{path}, qw(--status-fd 3 --logger-fd 1));
    push(@command, @{ $VERIFY_FLAGS{ $self->{style} } });
    if ($self->{home}) {
        push(@command, '--homedir', $self->{home});
    }
    push(@command, $signature_file, $data_file);
    return @command;
}

# Create a detached signature for the given data.
#
# $keyid      - GnuPG key ID to use to sign the data
# $passphrase - Passphrase for the GnuPG key
# @sources    - The data to sign (see _write_data for more information)
#
# Returns: The signature as an ASCII-armored block with embedded newlines
#  Throws: Text exception on failure that includes the GnuPG output
sub sign {
    my ($self, $keyid, $passphrase, @sources) = @_;

    # Ignore SIGPIPE, since we're going to be talking to GnuPG.
    local $SIG{PIPE} = 'IGNORE';

    # Build the command to run.
    my @command = $self->_build_sign_command($keyid);

    # Fork off a pgp process that we're going to be feeding data to, and tell
    # it to just generate a signature using the given key id and pass phrase.
    my $writefh = IO::Handle->new();
    my ($signature, $errors);
    #<<<
    my $h = start(
        \@command,
        '3<', \$passphrase,
        '<pipe', $writefh,
        '>', \$signature,
        '2>', \$errors,
    );
    #>>>
    $self->_write_data($writefh, @sources);
    close($writefh);

    # Get the return status and raise an exception on failure.
    if (!finish($h)) {
        my $status = $h->result();
        $errors .= "Execution of $command[0] failed with status $status";
        croak($errors);
    }

    # The resulting signature will look something like this:
    #
    # -----BEGIN PGP SIGNATURE-----
    # Version: GnuPG v0.9.2 (SunOS)
    # Comment: For info see http://www.gnupg.org
    #
    # iEYEARECAAYFAjbA/fsACgkQ+YXjQAr8dHYsMQCgpzOkRRopdW0nuiSNMB6Qx2Iw
    # bw0AoMl82UxQEkh4uIcLSZMdY31Z8gtL
    # =Dj7i
    # -----END PGP SIGNATURE-----
    #
    # Find and strip the marker line for the start of the signature.
    my @signature = split(m{\n}xms, $signature);
    while ((shift @signature) !~ m{-----BEGIN [ ] PGP [ ] SIGNATURE-----}xms) {
        if (!@signature) {
            croak('No signature returned by GnuPG');
        }
    }

    # Strip any headers off the signature.  Thankfully all of the important
    # data is encoded into the signature itself, so the headers aren't needed.
    while (@signature && $signature[0] ne q{}) {
        shift(@signature);
    }
    shift(@signature);

    # Remove the trailing marker line.
    pop(@signature);

    # Everything else is the signature that we want.
    return join("\n", @signature);
}

# Check a detached signature for given data.
#
# $signature - The signature as an ASCII-armored string with embedded newlines
# @sources   - The data over which to check the signature
#
# Returns: The human-readable key ID of the signature, or an empty string if
#          the signature did not verify
#  Throws: Text exception on an error other than a bad signature
sub verify {
    my ($self, $signature, @sources) = @_;
    chomp($signature);

    # Ignore SIGPIPE, since we're going to be talking to PGP.
    local $SIG{PIPE} = 'IGNORE';

    # To verify a detached signature, we need to save both the signature and
    # the data to files and then run GnuPG on the pair of files.  There
    # doesn't appear to be a way to feed both the data and the signature in on
    # file descriptors.
    my @tmpdir = defined($self->{tmpdir}) ? (DIR => $self->{tmpdir}) : ();
    my $sigfh  = File::Temp->new(@tmpdir, SUFFIX => '.asc');
    _print_fh($sigfh, "-----BEGIN PGP SIGNATURE-----\n");
    _print_fh($sigfh, "\n", $signature);
    _print_fh($sigfh, "\n-----END PGP SIGNATURE-----\n");
    close($sigfh);
    my $datafh = File::Temp->new(@tmpdir);
    $self->_write_data($datafh, @sources);
    close($datafh);

    # Build the command to run.
    my @command
      = $self->_build_verify_command($sigfh->filename, $datafh->filename);

    # Call GnuPG to check the signature.
    my ($output, $results);
    run(\@command, '>&', \$output, '3>', \$results);
    my $status = $?;

    # Check for the message that gives us the key status and return the
    # appropriate thing to our caller.
    #
    # GPG 1.4.23
    #   [GNUPG:] GOODSIG 7D80315C5736DE75 Russ Allbery <eagle@eyrie.org>
    #   [GNUPG:] BADSIG 7D80315C5736DE75 Russ Allbery <eagle@eyrie.org>
    #
    # Note that this returns the human-readable key ID instead of the actual
    # key ID.  This is a historical wart in the API; a future version will
    # hopefully add an option to return more accurate signer information.
    for my $line (split(m{\n}xms, $results)) {
        if ($line =~ m{ ^ \[GNUPG:\] \s+ GOODSIG \s+ \S+ \s+ (.*) }xms) {
            return $1;
        } elsif ($line =~ m{ ^ \[GNUPG:\] \s+ BADSIG \s+ }xms) {
            return q{};
        }
    }

    # Neither a good nor a bad signature seen.
    $output .= $results;
    if ($status != 0) {
        $output .= "Execution of $command[0] failed with status $status";
    }
    croak($output);
}

##############################################################################
# Legacy function API
##############################################################################

# This is the original API from 0.x versions of PGP::Sign.  It is maintained
# for backwards compatibility, but is now a wrapper around the object-oriented
# API that uses the legacy global variables.  The object-oriented API should
# be preferred for all new code.

# Create a detached signature for the given data.
#
# The original API returned the PGP implementation version from the signature
# headers as the second element of the list returned in array context.  This
# information is pointless and unnecessary and GnuPG doesn't include that
# header by default, so the fixed string "GnuPG" is now returned for backwards
# compatibility.
#
# Errors are stored for return by pgp_error(), overwriting any previously
# stored error.
#
# $keyid      - GnuPG key ID to use to sign the data
# $passphrase - Passphrase for the GnuPG key
# @sources    - The data to sign (see _write_data for more information)
#
# Returns: The signature as an ASCII-armored block in scalar context
#          The signature and the string "GnuPG" in list context
#          undef or the empty list on error
sub pgp_sign {
    my ($keyid, $passphrase, @sources) = @_;
    @ERROR = ();

    # Create the signer object.
    my $signer = PGP::Sign->new(
        {
            home   => $PGPPATH,
            munge  => $MUNGE,
            path   => $PGPS,
            style  => $PGPSTYLE,
            tmpdir => $TMPDIR,
        },
    );

    # Do the work, capturing any errors.
    my $signature = eval { $signer->sign($keyid, $passphrase, @sources) };
    if ($@) {
        @ERROR = split(m{\n}xms, $@);
        return;
    }

    # Return the results, including a dummy version if desired.
    ## no critic (Freenode::Wantarray)
    return wantarray ? ($signature, 'GnuPG') : $signature;
    ## use critic
}

# Check a detached signature for given data.
#
# $signature - The signature as an ASCII-armored string with embedded newlines
# @sources   - The data over which to check the signature
#
# Returns: The human-readable key ID of the signature
#          An empty string if the signature did not verify
#          undef on error
sub pgp_verify {
    my ($signature, $version, @sources) = @_;
    @ERROR = ();

    # Create the verifier object.
    my $verifier = PGP::Sign->new(
        {
            home   => $PGPPATH,
            munge  => $MUNGE,
            path   => $PGPV,
            style  => $PGPSTYLE,
            tmpdir => $TMPDIR,
        },
    );

    # Do the work, capturing any errors.
    my $signer = eval { $verifier->verify($signature, @sources) };
    if ($@) {
        @ERROR = split(m{\n}xms, $@);
        return;
    }

    # Return the results.
    return $signer;
}

# Retrieve errors from the previous pgp_sign() or pgp_verify() call.
#
# Historically the pgp_error() return value in list context had newlines at
# the end of each line, so add them back in.
#
# Returns: A list of GnuPG output and error messages in list context
#          The block of GnuPG output and error message in scalar context
## no critic (Freenode::Wantarray)
sub pgp_error {
    my @error_lines = map { "$_\n" } @ERROR;
    return wantarray ? @error_lines : join(q{}, @error_lines);
}
## use critic

##############################################################################
# Module return value and documentation
##############################################################################

# Make sure the module returns true.
1;

__DATA__

=for stopwords
Allbery DSS GNUPGHOME GPG GPG1 Gierth Mitzelfelt OpenPGP PGPMoose PGPPATH
TMPDIR canonicalized d'Itri egd keyrings pgpverify ps signcontrol
KEYID --force-v3-sigs --allow-weak-digest-algos --homedir --textmode cleartext
cryptographic gpg gpg1 gpgv homedir interoperable tmpdir

=head1 NAME

PGP::Sign - Create detached PGP signatures for data, securely

=head1 SYNOPSIS

    use PGP::Sign;
    my $keyid = '<some-key-id>';
    my $passphrase = '<passphrase-for-key>';
    my @data = ('lines to', 'be signed');

    # Object-oriented API.
    my $pgp = PGP::Sign->new();
    my $signature = $pgp->sign($keyid, $passphrase, @data);
    my $signer = $pgp->verify($signature, @data);

    # Legacy API.
    $signature = pgp_sign($keyid, $passphrase, @data);
    $signer = pgp_verify($signature, undef, @data);
    my @errors = PGP::Sign::pgp_error();

=head1 REQUIREMENTS

Perl 5.20 or later, the IPC::Run module, and either GnuPG v1 or GnuPG v2.  It
is only tested on UNIX-derivative systems and is moderately unlikely to work
on Windows.

=head1 DESCRIPTION

This module supports only two OpenPGP operations: Generate and check detached
PGP signatures for arbitrary text data.  It doesn't do encryption, it doesn't
manage keyrings, it doesn't verify signatures, it just signs things and checks
signatures.  It was written to support Usenet applications like control
message generation and PGPMoose.

There are two APIs, an object-oriented one and a legacy function API.  The
function API is configured with global variables and has other legacy warts.
It will continue to be supported for backwards compatibility, but the
object-oriented API is recommended for all new code.  The object-oriented API
was added in PGP::Sign 1.00.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new PGP::Sign object.  This should be used for all subsequent API
calls.  ARGS should be a hash reference with one or more of the following
keys.

=over 4

=item home

The GnuPG home directory containing keyrings and other configuration (as
controlled with the B<--homedir> flag or the GNUPGHOME environment variable).
If not set, uses the GnuPG default.  This directory must contain keyrings with
the secret keys used for signing and the public keys used for verification,
and must be in the format expected by the GnuPG version used (see the C<style>
parameter).

=item munge

If set to a true value, PGP::Sign will strip trailing spaces (only spaces, not
arbitrary whitespace) when signing or verifying signatures.  This will make
the resulting signatures and verification compatible with programs that
generate or verify cleartext signatures, since OpenPGP implementations ignore
trailing spaces when generating or checking cleartext signatures.

=item path

The path to the GnuPG binary to use.  If not set, PGP::Sign defaults to
running B<gpg> (as found on the user's PATH) for a C<style> setting of "GPG"
and B<gpg1> (as found on the user's PATH) for a C<style> setting of "GPG1".

PGP::Sign does not support B<gpgv> (it passes options that it does not
understand).  This parameter should point to a full GnuPG implementation.

=item style

The style of OpenPGP backend to use, chosen from "GPG" for GnuPG v2 (the
default) and "GPG1" for GnuPG v1.

If set to "GPG1", PGP::Sign will pass the command-line flags for maximum
backwards compatibility, including forcing v3 signatures instead of the
current version.  This is interoperable with PGP 2.6.2, at the cost of using
deprecated protocols and cryptographic algorithms with known weaknesses.

=item tmpdir

The path to a temporary directory to use when verifying signatures.  PGP::Sign
has to write files to disk for signature verification and will do so in this
directory.  If not given, PGP::Sign will use File::Temp's default.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item sign(KEYID, PASSPHRASE, SOURCE[, SOURCE ...])

Create an OpenPGP signature over all the data contained in the SOURCE
parameters, using KEYID to make the signature.  PASSPHRASE is the passphrase
for this private key.  KEYID can be in any format accepted by GnuPG.

The data given in the SOURCE parameters can be given in a wide variety of
formats: scalar variables, arrays, references to scalars or arrays, globs or
references to globs (assumed to be an open file), IO::File objects, or code
references.

If given a code reference, that function will be repeatedly called to obtain
more data until it returns undef.  This allows passing in an anonymous sub
that transforms the data on the fly (escaping initial dashes, for instance)
without having to make an in-memory copy.

The returned signature is the ASCII-armored block with embedded newlines but
with the marker lines and all headers stripped.

PGP::Sign will always pass the B<--textmode> flag to GnuPG to force treatment
of all input data as text and canonicalize line endings before generating the
signature.  If configured with the "GPG1" style, PGP::Sign will also pass the
B<--force-v3-sigs> and B<--allow-weak-digest-algos> flags to allow use of old
PGP keys and generate signatures that are compatible with old versions of PGP.

On error, sign() will call croak().

=item verify(SIGNATURE, SOURCE[, SOURCE ...])

Verify a signature.  PGP::Sign will attempt to verify the signature in
detached mode.  The signature must be in the same format as returned by
sign(): an ASCII-armored block with embedded newlines but with the marker
lines and all headers stripped.  verify() accepts data sources in the SOURCE
parameters in the same formats accepted by sign().

verify() returns the user ID of the signer, not the fingerprint or hex key ID.
If the signature does not verify, verify() will return the empty string.  For
other errors, it will call croak().

As with sign(), PGP::Sign will always pass the B<--textmode> flag to GnuPG.
It will also always pass B<--allow-weak-digest-algos> to allow verification
of old signatures.

=back

=head1 FUNCTIONS

The legacy function interface is supported for backwards compatibility with
earlier versions of PGP::Sign.  It is not recommended for any new code.
Prefer the object-oriented API.

pgp_sign() and pgp_verify() are exported by default.

=over 4

=item pgp_sign(KEYID, PASSPHRASE, SOURCE[, SOURCE ...])

Equivalent to creating a new PGP::Sign object and then calling its sign()
method with the given parameters.  The parameters to the object will be set
based on the global variables described in L</VARIABLES>.  The C<path>
parameter will be set to $PGP::Sign::PGPS.

When called in a scalar context, pgp_sign() returns the signature, the same as
the sign() method.  When called in an array context, pgp_sign() returns a
two-item list.  The second item is the fixed string "GnuPG".  Historically,
this was the version of the OpenPGP implementation, taken from the Version
header of the signature, but this header is no longer set by GnuPG and had no
practical use, so pgp_sign() now always returns that fixed value.

On error, pgp_sign() returns undef or an empty list, depending on context.  To
get the corresponding errors, call pgp_error().

=item pgp_verify(SIGNATURE, VERSION, SOURCE[, SOURCE ...])

Equivalent to creating a new PGP::Sign object and then calling its verify()
method with the SIGNATURE and SOURCE parameters.  The parameters to the object
will be set based on the global variables described in L</VARIABLES>.  The
C<path> parameter will be set to $PGP::Sign::PGPV.

The VERSION parameter may be anything and is ignored.

pgp_verify() returns the user ID of the signer (not the hex key ID or
fingerprint) on success, an empty string if the signature is invalid, and
undef on any other error.  On error, pgp_sign() returns undef or an empty
list, depending on context.  To get the corresponding errors, call
pgp_error().

=item pgp_error()

Return the errors encountered by the last pgp_sign() or pgp_verify() call, or
undef or the empty list depending on context if there were no error.  A bad
signature passed to pgp_verify() is not considered an error for this purpose.

In an array context, a list of lines (including the ending newlines) is
returned.  In a scalar context, a string with embedded newlines is returned.

This function is not exported by default and must be explicitly requested.

=back

=head1 VARIABLES

The following variables control the behavior of the legacy function interface.
They are not used for the object-oriented API, which replaces them with
parameters to the new() class method.

=over 4

=item $PGP::Sign::MUNGE

If set to a true value, PGP::Sign will strip trailing spaces (only spaces, not
arbitrary whitespace) when signing or verifying signatures.  This will make
the resulting signatures and verification compatible with programs that
generate or verify cleartext signatures, since OpenPGP implementations ignore
trailing spaces when generating or checking cleartext signatures.

=item $PGP::Sign::PGPPATH

The GnuPG home directory containing keyrings and other configuration (as
controlled with the B<--homedir> flag or the GNUPGHOME environment variable).
If not set, uses the GnuPG default.  This directory must contain keyrings with
the secret keys used for signing and the public keys used for verification,
and must be in the format expected by the GnuPG version used (see
$PGP::Sign::PGPSTYLE).

=item $PGP::Sign::PGPSTYLE

What style of command line arguments and responses to expect from PGP.  Must
be either "GPG" for GnuPG v2 or "GPG1" for GnuPG v1.  The default is "GPG".

If set to "GPG1", PGP::Sign will pass the command-line flags for maximum
backwards compatibility, including forcing v3 signatures instead of the
current version.  This is interoperable with PGP 2.6.2, at the cost of using
deprecated protocols and cryptographic algorithms with known weaknesses.

=item $PGP::Sign::PGPS

The path to the program used by pgp_sign().  If not set, PGP::Sign defaults to
running B<gpg> (as found on the user's PATH) if $PGP::Sign::PGPSTYLE is set to
"GPG" and B<gpg1> (as found on the user's PATH) if $PGP::Sign::PGPSTYLE is set
to "GPG1".

=item $PGP::Sign::PGPV

The path to the program used by pgp_verify().  If not set, PGP::Sign defaults
to running B<gpg> (as found on the user's PATH) if $PGP::Sign::PGPSTYLE is set
to "GPG" and B<gpg1> (as found on the user's PATH) if $PGP::Sign::PGPSTYLE is
set to "GPG1".

PGP::Sign does not support B<gpgv> (it passes options that it does not
understand).  This variable should point to a full GnuPG implementation.

=item $PGP::Sign::TMPDIR

The directory in which temporary files are created.  Defaults to whatever
directory File::Temp chooses to use by default.

=back

=head1 ENVIRONMENT

All environment variables that GnuPG normally honors will be passed along to
GnuPG and will likely have their expected effects.  This includes GNUPGHOME,
unless it is overridden by setting the C<path> parameter to the new()
constructor or $PGP::Sign::PGPPATH for the legacy interface.

=head1 DIAGNOSTICS

Error messages thrown by croak() or (for the legacy interface) are mostly the
output from GnuPG or from IPC::Run if it failed to run GnuPG.  The exceptions
are:

=over 4

=item Execution of %s failed with status %s

GnuPG failed and returned the given status code.

=item No signature returned by GnuPG

We tried to generate a signature but, although GnuPG succeeded, the output
didn't contain anything that looked like a signature.

=item print failed: %s

When writing out the data for signing or verification, print failed with the
given error.

=item Unknown OpenPGP backend style %s

The parameter to the C<style> option of the new() constructor, or the setting
of $PGP::Sign::PGPSTYLE, is not one of the recognized values.

=back

=head1 BUGS

The verify() method returns a user ID, which is a poor choice and may be
insecure unless used very carefully.  PGP::Sign should support an option to
return richer information about the signature verification, including the long
hex key ID.

PGP::Sign does not currently work with binary data, as it unconditionally
forces text mode using the B<--textmode> option.

There is no way to tell PGP::Sign to not allow unsafe digest algorithms when
generating or verifying signatures.

The whitespace munging support addresses the most common difference between
cleartext and detached signatures, but does not deal with all of the escaping
issues that are different between those two modes.  It's likely that
extracting a cleartext signature and verifying it with this module or using a
signature from this module as a cleartext signature will not work in all
cases.

=head1 CAVEATS

This module is fairly good at what it does, but it doesn't do very much.  At
one point, I had plans to provide more options and more configurability in the
future, particularly the ability to handle binary data, that would probably
mean API changes.  I'm not sure at this point whether that will ever happen.

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 1997-2000, 2002, 2004, 2018, 2020 Russ Allbery <rra@cpan.org>

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

gpg(1), gpg1(1), L<File::Temp>

L<RFC 4880|https://tools.ietf.org/html/rfc4880>, which is the current
specification for the OpenPGP message format.

The current version of PGP::Sign is available from CPAN, or directly from its
web site at L<https://www.eyrie.org/~eagle/software/pgp-sign/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
