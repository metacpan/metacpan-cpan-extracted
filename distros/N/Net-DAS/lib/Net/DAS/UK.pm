package Net::DAS::UK;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw (uk co.uk ltd.uk me.uk net.uk org.uk plc.uk sch.uk)],
        public => {
            host => 'dac.nic.uk',    #'testbed-dac.nominet.org.uk',
            port => 2043,
        },
        registrar => {
            host => 'dac.nic.uk',
            port => 3043,
        },
        delay     => 3000000,
        dispatch  => [ undef, \&parse ],
        close_cmd => '#exit',
    };
}

sub parse {
    chomp( my $i = uc(shift) );
    return (-2) if $i =~ m/IP ADDRESS (.*) NOT REGISTERED/;
    $i =~ m/^([\w.]*),(\w)(,.*)?/;
    return 1  if $2 eq 'N';
    return 0  if $2 eq 'Y';
    return -3 if $2 eq 'B';
    return (-100);
}

1;

=pod

=head1 NAME

Net::DAS::UK - Net::DAS .UK extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
