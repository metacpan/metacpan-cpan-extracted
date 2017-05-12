package Net::DAS::GENT;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw(gent)],
        public => {
            host => 'whois.nic.gent',
            port => 4343,
        },
    };
}

1;

=pod

=head1 NAME

Net::DAS::GENT - Net::DAS .GENT extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
