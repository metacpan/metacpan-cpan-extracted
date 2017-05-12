package Parse::SSH2::PublicKey;

use strict;
use warnings;
use autodie qw/open close/;
use Moo;
use MIME::Base64;
use Carp qw/confess/;
no warnings qw/substr uninitialized/;

our $VERSION = 0.01;

=head1 NAME

Parse::SSH2::PublicKey - Parse SSH2 public keys in either SECSH or OpenSSH format.

=head1 VERSION

Version 0.01

=cut

=head1 PURPOSE

Different implementations of SSH (OpenSSH, SSH Tectia, PuTTY, etc) use different key formats. For example, for public key authentication, OpenSSH will accept an authorized_keys file that holds all keys, whereas the ssh.com proprietary implementation wants an authorized_keys/ *directory* with a file for each key!

This module was created to assist sysadmins in converting from one SSH implementation to another.

=head1 SYNOPSIS

    use Parse::SSH2::PublicKey;

    my $auth_key = "$ENV{HOME}/.ssh/authorized_keys";
    my @keys = Parse::SSH2::PublicKey->parse_file($auth_key);

    for my $k ( @keys ) {
        print $k->secsh();
        # or ->openssh()
    }

    ...

    my $dir  = "$ENV{HOME}/.ssh2/authorized_keys/";
    my @files = glob("$dir/*pub");
    my @keys = map { Parse::SSH2::PublicKey->parse_file($_) } @files;

    for my $k ( @keys ) {
        print $k->openssh();
    }

=cut

has key => (
    is  => 'ro',
    isa => sub {},
    default => sub { '' },
);

has type => (
    is  => 'ro',
    isa => sub {
        my $t = shift;
        confess "type must be 'public' or 'private'"
            unless grep { $t eq $_ } qw (public private);
    },
    default => sub { '' },
);

has encryption => (
    is  => 'ro',
    isa => sub {
        my $enc = shift;
        confess "must be 'ssh-rsa' or 'ssh-dss'"
            unless grep { $enc eq $_ } qw/ssh-rsa ssh-dss/;
    },
    default => sub { '' },
);

has headers => (
    is => 'ro',
    isa => sub { die "'headers' attribute must be a hashref." unless (ref $_[0] eq 'HASH'); },
    default => sub { return {} },
);

has header_order => (
    is => 'ro',
    isa => sub { die "'header_order' attribute must be an arrayref." unless (ref $_[0] eq 'ARRAY'); },
    default => sub { return [] },
);

=head1 METHODS 

=head2 new()

Creates an Parse::SSH2::PublicKey object. Not intended to be used directly.
Instead, this is called internally by parse(),
which returns an array of objects.

=head2 parse()

Accepts a block of text and parses out SSH2 public keys in both OpenSSH and SECSH format.
Returns an *array* of Parse::SSH2::PublicKey objects. Class method to be used instead of new().

=cut

sub parse {
    my $class = shift;
    my $data  = shift;

    my @objs;

    while ( length($data) > 0 ) {

        my $entire_key;

        # OpenSSH format -- all on one line.
        if ( $data =~ m%((ssh-rsa|ssh-dss)\ ([A-Z0-9a-z/+=]+)\s*([^\n]*))%gsmx ) {
            $entire_key = $1;

            # TODO: pull encryption from base64 key data, not here... just to be safe.
            my $encryption = $2;
            my $key = $3;
            my $comment = $4;
            my $type   = 'public';

            my ($headers, $header_order);
            if ( defined $comment ) {
                push @$header_order, 'Comment';
                $headers->{ 'Comment' } = $comment;
            }

            push @objs, $class->new( key     => $key,
                                     #comment => $headers->{Comment} || '',
                                     type    => $type,
                                     #subject => '',
                                     header_order => $header_order,
                                     headers => $headers,
                                     encryption => $encryption );

        }

        # SECSH pubkey format
        elsif ( $data =~ m/(----\ BEGIN\ SSH2\ PUBLIC\ KEY\ ----(?:\n|\r|\f)
                           (.*?)(?:\n|\r|\f)
                           ----\ END\ SSH2\ PUBLIC\ KEY\ ----)/gsmx ) {
            $entire_key = $1;
            my $type = 'public';
            my $keydata = $2;

            my ($key, $header_order, $headers) = _extract_secsh_key_headers( $keydata );

            # ==================================================================
            # TODO: this needs to be factored out into a separate subroutine
            # which decodes ALL the base64 key data (modulus and exponent also)
            my $octets = decode_base64( $key );
            my $dlen = unpack("N4", substr($octets,0,4));
            my $encryption = unpack("A" . $dlen, substr($octets, 4, $dlen));
            # ==================================================================

            push @objs, $class->new( key     => $key,
                                     #comment => $headers->{Comment} || '',
                                     type    => $type,
                                     #subject => $headers->{Subject} || '',
                                     header_order => $header_order,
                                     headers => $headers,
                                     encryption => $encryption );
        }

        # note: OpenSSH private keys are parsed & removed from $data,
        # but objects are not created
        elsif ( $data =~ m/(-+BEGIN\ (DSA|RSA)\ PRIVATE\ KEY-+(?:\n|\r|\f)
                           (.*?)(?:\n|\r|\f)
                           -+END\ (DSA|RSA)\ PRIVATE\ KEY-+)/gsmx ) {
            $entire_key = $1;
            my $encryption = $2;
            my $keydata = $3;
            my $type = 'private';

            my ($key, $header_order, $headers) = _extract_secsh_key_headers( $keydata );

            $encryption = ($encryption eq 'RSA') ? 'ssh-rsa' :
                          ($encryption eq 'DSA') ? 'ssh-dss' : '';
            # Because the regex match requires RSA or DSA for this value,
            # $encryption should never get set to the empty string here.
        }
        else {
            # no keys found and/or invalid key data
            last;
        }

        $data =~ s/\Q$entire_key\E(?:\n|\f|\r)?//gsmx;
    }

    return @objs;
}

=head2 parse_file()

Convenience method which opens a file and calls C<parse> on the contents.

=cut 

sub parse_file {
    my $class  = shift;
    my $infile = shift;

    open (my $in , '<', $infile);
    # now handled by autodie

    my $data = do { local $/; <$in> };
    close $in;
    return $class->parse( $data );
}

=head2 secsh()

Returns an SSH public key in SECSH format (as specified in RFC4716).
Preserves headers and the order of headers.

See L<http://tools.ietf.org/html/rfc4716>.

=cut 

sub secsh {
    my $self = shift;

    my $str;
    if ( $self->type eq 'public' ) {
        $str = "---- BEGIN SSH2 PUBLIC KEY ----\n";
        my @headers = @{$self->header_order()};
        if ( scalar(@headers) ) {
            for my $h ( @headers ) {
                $str .= join("\\\n", split(/\n/, _chop_long_string(
                        $h . ': ' . $self->headers->{$h}, 70 ))) . "\n";
            }
        }
        $str .= _chop_long_string( $self->key, 70 ) . "\n";
        $str .= "---- END SSH2 PUBLIC KEY ----\n";
    }

    # TODO: remove support for private keys...
    elsif ( $self->type eq 'private' ) {
        $str = "---- BEGIN SSH2 ENCRYPTED PRIVATE KEY ----\n";

        # Not sure if 'Proc-Type' and 'DEK-Info' are valid headers
        # for Tectia private keys...

        my @headers = @{$self->header_order()};
        @headers = grep { !/Proc-Type/ && !/DEK-Info/ } @headers;
        if ( scalar(@headers) ) {
            for my $h ( @headers ) {
                $str .= join("\\\n", split(/\n/, _chop_long_string(
                        $h . ': ' . $self->headers->{$h}, 70 ))) . "\n";
            }
        }

        $str .= _chop_long_string( $self->key, 70 ) . "\n";
        $str .= "---- END SSH2 ENCRYPTED PRIVATE KEY ----\n";
    }

    return $str;
}


=head2 openssh()

Returns an SSH public key in OpenSSH format. Preserves 'comment' field
parsed from either SECSH or OpenSSH.

=cut 

sub openssh {
    my $self = shift;

    my $str;

    if ( $self->type eq 'public' ) {
        $str  = $self->encryption . ' ' .
                $self->key        . ' ' .
                $self->comment    . "\n";
    }

    # TODO: remove support for private keys...
    elsif ( $self->type eq 'private' ) {
        $str = "-----BEGIN " . $self->encryption . " PRIVATE KEY-----\n";

        # Not sure if 'Comment' and 'Subject' are valid headers
        # for OpenSSH private keys...

        my @headers = @{$self->header_order()};
        @headers = grep { !/Comment/ && !/Subject/ } @headers;
        if ( scalar(@headers) ) {
            for my $h ( @headers ) {
                $str .= join("\\\n", split(/\n/, _chop_long_string(
                        $h . ': ' . $self->headers->{$h}, 64 ))) . "\n";
            }
            $str .= "\n";
        }
        $str .= _chop_long_string( $self->key, 64 ) . "\n";
        $str .= "-----END " . $self->encryption . " PRIVATE KEY-----\n";
    }

    return $str;
}

=head2 comment()

Convenience method for $k->headers->{Comment}. Returns the Comment header value or the empty string.

=cut 

sub comment {
    my $self = shift;
    return $self->headers->{Comment} || '';
}

=head2 subject()

Convenience method for $k->headers->{Subject}. Returns the Subject header value or the empty string.

=cut 

sub subject {
    my $self = shift;
    return $self->headers->{Subject} || '';
}

=head1 ATTRIBUTES

=head2 encryption

Either 'ssh-rsa' or 'ssh-dss', for RSA and DSA keys, respectively.

=head2 header_order

Order of headers parsed from SECSH-format keys. See also
L<http://tools.ietf.org/html/rfc4716>.

=head2 headers

Hashref containing headers parsed from SECSH-format keys.
See also L<http://tools.ietf.org/html/rfc4716>.

=head2 key

The actual base64-encoded key data.

=head2 type

Either 'public' or 'private', but private keys aren't currently
supported. Obsolete. (Or perhaps ahead of it's time.)

=cut

# internal method, not intended for use outside this module
# Breaks long string into chunks of MAXLEN length,
# separated by "\n"
sub _chop_long_string {
    my $string = shift;
    my $maxlen = shift;

    my @lines;
    my $index = 0;
    while ( my $line = substr($string, $index, $maxlen) ) {
        push @lines, $line;
        $index += $maxlen;
    }
    return join("\n", @lines);
}


# internal method, not intended for use outside this module
sub _extract_secsh_key_headers {
    my $data = shift;
    my %headers;
    my @header_order;

    # Match all up to a "\n" not prefixed with a '\' char
    # -- a "\\\n" sequence should be ignored/slurped.
    # This regex uses negative look-behind.
    while ( $data =~ m/^((?:\w|-)+):\ (.*?)(?<!\\)\n/gsmx )
    {
        my $header_tag = $1;
        my $header_val = $2;

        # Don't change \\\n to '' here, because we need this
        # to match the header for stripping it from the key
        # data below.
        $headers{ $header_tag } = $header_val;
        push @header_order, $header_tag;
    }

    for my $h ( keys %headers ) {
        # strip headers from main key data,
        # now that they have been saved in %headers
        $data =~ s/\Q$h: $headers{$h}\E(?:\n|\f|\r)//gsm;
    }

    # NOW strip the '\\\n' from the header values
    $_ =~ s/\\(\n|\f|\r)//g for values %headers;

    (my $key = $data) =~ s/\n|\f|\r//g;

    return ($key, \@header_order, \%headers);
}


1;

__END__

=head1 EXAMPLE USAGE

=head2 OpenSSH to SSH Tectia

    #! /usr/bin/perl -w
    # Sample script to prepare for a move from OpenSSH
    # to the ssh.com commercial implementation

    use strict;
    use feature qw/say/;
    use File::Slurp qw(read_file write_file);
    use File::Temp qw(tempdir);
    use Parse::SSH2::PublicKey;

    my @keys = Parse::SSH2::PublicKey->parse_file("$ENV{HOME}/.ssh/authorized_keys");

    my $dir = tempdir( CLEANUP => 0 );

    my $count = 0;
    for my $k ( @keys ) {
        my $filename = $dir . '/' . 'key' . ($count+1) . '.pub';
        ++$count if write_file( $filename, $k->secsh );
    }

    say "Wrote $count SECSH format key files to dir [$dir]";
    say "Now move $dir into place at \$HOME/.ssh2/authorized_keys/";


=head2 OpenSSH to SSH Tectia

    #! /usr/bin/perl -w
    # Sample script to convert from ssh.com implementation
    # to OpenSSH

    use strict;
    use feature qw/say/;
    use Parse::SSH2::PublicKey;

    my $ssh_authkeys_dir = "$ENV{HOME}/.ssh2/authorized_keys/";
    my @files = glob("$ssh_authkeys_dir/*pub");
    my @keys = map { Parse::SSH2::PublicKey->parse_file($_) } @files;

    # output can be redirected to a file, e.g. '$HOME/.ssh/authorized_keys'
    for my $k ( @keys ) {
        print $k->openssh();
    }


=head1 AUTHOR

Nathan Marley, C<< <nathan.marley at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-ssh2-publickey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-SSH2-PublicKey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::SSH2::PublicKey


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-SSH2-PublicKey>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-SSH2-PublicKey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-SSH2-PublicKey>

=item * MetaCPAN

L<https://metacpan.org/dist/Parse-SSH2-PublicKey>

=item * GitHub

L<https://github.com/nmarley/Parse-SSH2-PublicKey>

=back

=head1 SEE ALSO

L<The Secure Shell (SSH) Public Key File Format|http://tools.ietf.org/html/rfc4716>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nathan Marley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


