package Net::DAS::RO;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [ 'ro', map { $_ . '.ro' } qw/arts com firm info org rec store tm www nt/ ],
        public => {
            host => 'whois.rotld.ro',    # rest2-test.rotld.ro
            port => 4343,
        },
        registrar => {
            host => 'whois.rotld.ro',    # rest2-test.rotld.ro
            port => 4343,
        },
        nl       => "\r\n",
        dispatch => [ undef, undef ],
    };
}

1;

=pod

=head1 NAME

Net::DAS::RO - Net::DAS .RO extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
