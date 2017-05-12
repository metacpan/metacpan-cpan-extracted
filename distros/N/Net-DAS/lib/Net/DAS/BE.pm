package Net::DAS::BE;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw(be)],
        public => {
            host => 'das.dns.be',
            port => 4343,
        },
        dispatch => [ undef, undef ],
    };
}

1;

=pod

=head1 NAME

Net::DAS::BE - Net::DAS .BE extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
