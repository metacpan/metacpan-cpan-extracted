package Net::DAS::SI;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw(si)],
        public => {
            host => 'das.arnes.si',
            port => 4343,
        },
        dispatch => [ undef, \&parse ],
    };
}

sub parse {
    chomp( my $i = uc(shift) );
    return 1  if uc($i) =~ m/IS AVAILABLE/;
    return 0  if uc($i) =~ m/IS REGISTERED/;
    return -1 if uc($i) =~ m/IS FORBIDDEN/;
    return (-100);
}

1;

=pod

=head1 NAME

Net::DAS::SI - Net::DAS .SI extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
