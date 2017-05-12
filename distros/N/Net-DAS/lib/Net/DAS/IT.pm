package Net::DAS::IT;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw(it co.it)],
        public => {
            host => 'das.nic.it',
            port => 4343,
        },
    };
}

1;

=pod

=head1 NAME

Net::DAS::IT - Net::DAS .IT extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
