package Net::DAS::NU;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw(nu)],
        public => {
            host => 'free.iis.nu',
            port => 80,
        },
        dispatch => [ \&query, \&parse ],

    };
}

sub query {
    my $d = shift;
    return "GET /free?q=$d HTTP/1.1\n" . "host: free.iis.nu\n\n";

}

sub parse {
    chomp( my $i  = uc(shift) );
    chomp( my $dn = uc(shift) );
    return 1 if uc($i) =~ m/FREE $dn/;
    return 0 if uc($i) =~ m/OCCUPIED $dn/;
    return (-100);
}

1;

=pod

=head1 NAME

Net::DAS::NU - Net::DAS .NU extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
