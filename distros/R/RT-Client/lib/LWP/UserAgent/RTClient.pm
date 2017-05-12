package LWP::UserAgent::RTClient;

use strict;
our @ISA = 'LWP::UserAgent';
use Digest::MD5 ();
use LWP::UserAgent ();

=head1 NAME

LWP::UserAgent::RTClient - User Agent for RT-Atom authentication

=head1 SYNOPSIS

(internal use only)

=head1 DESCRIPTION

No user-serviceable parts inside.

=cut

my %ClientOf;

sub new {
    my ($class, $client) = @_;
    my $ua = $client->{ua};
    my $new_ua = bless($ua, $class);
    $ClientOf{$new_ua} = $client;
    return $new_ua;
}

sub get_basic_credentials {
    my ($self, $realm, $url, $proxy) = @_;
    my $client = $ClientOf{$self} or die "Cannot find $self";
    return $client->username, Digest::MD5::md5_hex(
        join(':',
            $client->username,
            $realm,
            Digest::MD5::md5_hex($client->password)
        )
    );
}

sub DESTROY {
    my $self = shift;
    delete $ClientOf{$self};
}

1;

=head1 SEE ALSO

L<RT::Client>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
