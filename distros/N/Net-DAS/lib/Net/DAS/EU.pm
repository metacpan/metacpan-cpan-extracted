package Net::DAS::EU;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw(eu)],
        public => {
            host => 'das.eu',
            port => 4343,
        },
        registrar => {
            host => 'das.registry.eu',
            port => 4343,
        },
        dispatch => [ undef, undef ],
    };
}

1;

=pod

=head1 NAME

Net::DAS::EU - Net::DAS .EU extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
