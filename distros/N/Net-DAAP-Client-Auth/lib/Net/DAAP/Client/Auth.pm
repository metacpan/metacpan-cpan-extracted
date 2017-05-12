package Net::DAAP::Client::Auth;
use strict;
use Net::DAAP::Client 0.4;
use vars qw( $VERSION @ISA );
use Carp;
$VERSION = 1.21;
@ISA = qw( Net::DAAP::Client );

sub new {
    my $class = shift;
    carp "Net::DAAP::Client::Auth->new deprecated in favour of Net::DAAP::Client->new";
    $class->SUPER::new(@_);
}

1;
__END__

=head1 NAME

Net::DAAP::Client::Auth - obsolete extension to Net::DAAP::Client

=head1 SYNOPSIS

  See Net::DAAP::Client

=head1 DESCRIPTION


Before the grand unification of Net::DAAP::Client and
Net::DAAP::Client::Auth this distribution was a bag of slightly
suspect hacks to force client validation into Net::DAAP::Client.

As of release 0.4 of Net::DAAP::Client this code has been integrated
and into the mainline, and you should use that.  This module is a
mostly empty subclass to encourage you to upgrade and amend your
scripts.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Net::DAAP::Client

=cut
