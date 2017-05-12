package Net::DAS::LT;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw(lt)],
        public => {
            host => 'das.domreg.lt',
            port => 4343,
        },
        dispatch => [ \&query, \&parse ],
    };
}

sub query {
    my $d = shift;
    return "get 1.0 " . $d;
}

sub parse {
    chomp( my $i = uc(shift) );
    return 1 if $i =~ m/.*STATUS:\sAVAILABLE/;
    return 0 if $i =~ m/.*STATUS:\sREGISTERED/;
    return (-100);
}

1;

=pod

=head1 NAME

Net::DAS::LT - Net::DAS .LT extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
