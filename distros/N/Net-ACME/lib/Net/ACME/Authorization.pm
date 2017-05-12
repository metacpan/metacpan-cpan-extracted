package Net::ACME::Authorization;

=pod

=encoding utf-8

=head1 NAME

Net::ACME::Authorization - fulfilled ACME authorization object

=head1 SYNOPSIS

    use Net::ACME::Authorization ();

    my $authz = Net::ACME::Authorization->new(
        status => 'valid',  #or “invalid”
        challenges => [ @list_of_challenge_objects ],
    );

    my @challenge_objs = $authz->challenges();

    my $payload;
    while (!$cert) {
        if ($need_retry->is_time_to_poll()) {
            $cert = $need_retry->poll();
        }

        sleep 1;
    }

=cut

#NOTE: For now, this assumes a domain name.
#Might be useful moving forward to separate out other types
#of authz as per ACME spec expansion. (As of April 2016 only
#domain names are handled.)

use strict;
use warnings;

use Call::Context ();

use Net::ACME::Utils ();
use Net::ACME::X ();

my $CHALLENGE_CLASS = 'Net::ACME::Challenge';

sub new {
    my ( $class, %opts ) = @_;

    my $self = {
        _status => $opts{'status'} || die('Need “status”!'),
        _challenges => $opts{'challenges'},
    };

    if ( $opts{'challenges'} ) {
        for my $c ( 0 .. $#{ $opts{'challenges'} } ) {
            my $challenge = $opts{'challenges'}[$c];

            if ( !Net::ACME::Utils::thing_isa($challenge, $CHALLENGE_CLASS) ) {
                die Net::ACME::X::create( 'InvalidParameter', "“challenges” index $c ($challenge) is not an instance of “$CHALLENGE_CLASS”!" );
            }
        }
    }

    return bless $self, $class;
}

sub status {
    my ($self) = @_;
    return $self->{'_status'};
}

sub challenges {
    my ($self) = @_;

    Call::Context::must_be_list();

    return @{ $self->{'_challenges'} };
}

1;
