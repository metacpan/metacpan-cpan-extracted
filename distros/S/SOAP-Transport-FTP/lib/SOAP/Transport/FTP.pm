# ======================================================================
#
# Copyright (C) 2000-2001 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: FTP.pm 353 2010-03-17 21:08:34Z kutterma $
#
# ======================================================================

package SOAP::Transport::FTP;

use strict;
use warnings;

our $VERSION = 0.711;

use Net::FTP;
use IO::File;
use URI;

# ======================================================================

package SOAP::Transport::FTP::Client;
our $VERSION = 0.711;
use SOAP::Lite;
our @ISA = qw(SOAP::Client);

sub new {
    my $class = shift;
    return $class if ref $class;

    my(@arg_from, @method_from);
    while (@_) {
        $class->can($_[0])
            ? push(@method_from, shift() => shift)
            : push(@arg_from, shift)
    }
    my $self = bless {@arg_from} => $class;
    while (@method_from) {
        my($method, $param_ref) = splice(@method_from,0,2);
        $self->$method(ref $param_ref eq 'ARRAY' ? @$param_ref : $param_ref)
    }
    return $self;
}

sub send_receive {
    my($self, %parameters) = @_;
    my($envelope, $endpoint, $action) =
        @parameters{qw(envelope endpoint action)};

    $endpoint ||= $self->endpoint; # ftp://login:password@ftp.something/dir/file

    my $uri = URI->new($endpoint);
    my($server, $auth) = reverse split /@/, $uri->authority;
    my $dir = substr($uri->path, 1, rindex($uri->path, '/'));
    my $file = substr($uri->path, rindex($uri->path, '/')+1);

    eval {
        my $ftp = Net::FTP->new($server, %$self) or die "Can't connect to $server: $@\n";
        $ftp->login(split /:/, $auth)            or die "Couldn't login\n";
        $dir and ($ftp->cwd($dir)
            or $ftp->mkdir($dir, 'recurse') and $ftp->cwd($dir)
                or die "Couldn't change directory to '$dir'\n");

        my $FH = IO::File->new_tmpfile; print $FH $envelope; $FH->flush; $FH->seek(0,0);
        $ftp->put($FH => $file)                  or die "Couldn't put file '$file'\n";
        $ftp->quit;
    };

    (my $code = $@) =~ s/\n$//;

    $self->code($code);
    $self->message($code);
    $self->is_success(!defined $code || $code eq '');
    $self->status($code);

    return;
}

# ======================================================================

1;


__END__

=head1 SOAP::Transport::FTP

FTP Client support for SOAP::Lite.

The SOAP::Transport::FTP module is automatically loaded by the
SOAP::Transport portion of the client structure. It is brought in when an
endpoint is specified via the proxy method that starts with the characters,
ftp://. This module provides only a client class.

=head2 SOAP::Transport::FTP::Client

Inherits from: L<SOAP::Client>.

Support is provided for clients to connect to FTP servers using SOAP. The
methods defined within the class are just the basic new and send_receive.

=head1 BUGS

This module is currently unmaintained, so if you find a bug, it's yours -
you probably have to fix it yourself. You could also become maintainer -
just send an email to mkutter@cpan.org

=head1 AUTHORS

Paul Kulchenko (paulclinger@yahoo.com)

Randy J. Ray (rjray@blackperl.com)

Byrne Reese (byrne@majordojo.com)

Martin Kutter (martin.kutter@fen-net.de)

=cut
