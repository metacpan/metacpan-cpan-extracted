package Net::DAS::NO;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw(no)],
        public => {
            host => 'whois.norid.no',
            port => 79,
        },
        dispatch => [ undef, \&parse ],
    };
}

sub parse {
    chomp( my $i = uc(shift) );
    return 1 if uc($i) =~ m/IS AVAILABLE/;
    return 0 if uc($i) =~ m/IS DELEGATED/;
    return (-100);    # failed to determine/parse
}

1;

=pod

=head1 NAME

Net::DAS::NO - Net::DAS .NO extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
