package Net::DNS::LivedoorDomain::DDNS;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use Net::DNS::LivedoorDomain::DDNS::Response;

our $VERSION = '0.01';

use constant DDNS_URL => 'http://domain.livedoor.com/webapp/dice/update';

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self;
}

sub update {
    my $self = shift;
    my %args = (
                username => undef,
                password => undef,
                hostname => undef,
                ip => undef,
                @_,
            );
    croak 'username is required' unless $args{username};
    croak 'password is required' unless $args{password};
    croak 'hostname is required' unless $args{hostname};

    my $header = HTTP::Headers->new;
    $header->authorization_basic($args{username}, $args{password});
    my $query = join '&',
        map { sprintf "%s=%s", $_, $args{$_} if defined $args{$_} }
            qw/hostname ip/;
    my $req = HTTP::Request->new('GET' => DDNS_URL .'?'. $query, $header);
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
    return Net::DNS::LivedoorDomain::DDNS::Response->new($res);
}

1;

__END__

=head1 NAME

Net::DNS::LivedoorDomain::DDNS - Update your livedoor DOMAIN (http://domain.livedoor.com/) DynamicDNS records.

=head1 SYNOPSIS

  use Net::DNS::LivedoorDomain::DDNS;
  my $ddns = Net::DNS::LivedoorDomain::DDNS->new;
  my $ret  = $ddns->update(
                           username => 'livedoorID',
                           password => '********',
                           hostname => 'www.example.com',
                           ip => '192.0.2.2',
                       );

=head1 METHODS

=head2 new

Create a new Object.

=head2 update(%config)

Update your DynamicDNS record. %config parameters are:

=over 4

C<username> - livedoor Domain Dynamic DNS Password. (Required)

C<password> - livedoor Domain Dynamic DNS Password. (Required)

C<hostname> - Homain name being updated. (Required)

C<ip> - The IP address to be updated. if empty, your current ip is used. (Optional)

=head1 DESCRIPTION

This module help you to update your livedoor DOMAIN (http://domain.livedoor.com/) DynamicDNS record(s).

=head1 SEE ALSO

L<http://domain.livedoor.com/>

=head1 AUTHOR

Masahito Yoshida E<lt>masahito@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Masahito Yoshida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
