package Net::LMTP2;
$Net::LMTP2::VERSION = '0.2';
# ABSTRACT: A client class for the LMTP protocol
use strict;
use warnings;

use base 'Net::SMTP';
use Net::Cmd;



sub hello {
    my $me     = shift;
    my $domain = shift || "localhost.localdomain";
    my $ok     = $me->_LHLO($domain);
    my @msg    = $me->message;

    if ($ok) {
        my $h = ${*$me}{'net_smtp_esmtp'} = {};
        foreach my $ln (@msg) {
            $h->{uc $1} = $2 if $ln =~ /([-\w]+)\b[= \t]*([^\n]*)/;
        }
    }
    elsif ($me->status == CMD_ERROR) {
        @msg = $me->message if $ok = $me->_HELO($domain);
  }


    return unless $ok;
    ${*$me}{net_smtp_hello_domain} = $domain;
    $msg[0] =~ /\A\s*(\S+)/;
    return ($1 || " ");

}



sub _EHLO { shift->unsupported(@_);}
sub _HELO { shift->unsupported(@_);}
sub _LHLO { shift->command("LHLO", @_)->response() == CMD_OK }
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LMTP2 - A client class for the LMTP protocol

=head1 VERSION

version 0.2

=head1 DESCRIPTION

This module provides an interface to LMTP servers. It inherits from Net::SMTP. In crontast to Net::LMTP it is actually working.

=head1 USAGE

Just look at Net::SMTP, this is just a derived class and providing 
its own hello function as this is the main difference between SMTP and
LMTP.

=head1 AUTHOR

Domink Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
