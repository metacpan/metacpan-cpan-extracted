package POE::Component::IRC::Plugin::WrapExample;

use strict;
use warnings;

# VERSION

use lib qw{lib ../lib};

use base 'POE::Component::IRC::Plugin::BasePoCoWrap';
use POE::Component::WWW::Google::PageRank;

sub _make_default_args {
    return (
        response_event   => 'irc_google_rank',
        trigger          => qr/^rank\s+(?=\S)/i,
    );
}

sub _make_poco {
    return POE::Component::WWW::Google::PageRank->spawn(
        debug => shift->{debug},
    );
}

sub _make_response_message {
    my $self   = shift;
    my $in_ref = shift;
    return [ exists $in_ref->{error} ? $in_ref->{error} : $in_ref->{rank} ];
}

sub _make_response_event {
    my $self = shift;
    my $in_ref = shift;

    return {
        ( exists $in_ref->{error}
            ? ( error => $in_ref->{error} )
            : ( result => $in_ref->{rank} )
        ),

        map { $_ => $in_ref->{"_$_"} }
            qw( who channel  message  type ),
    }
}

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    $self->{poco}->rank( {
            event       => '_poco_done',
            page        => delete $data_ref->{what},
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}

1;

__END__