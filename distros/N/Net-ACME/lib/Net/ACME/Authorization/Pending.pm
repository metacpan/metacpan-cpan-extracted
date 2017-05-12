package Net::ACME::Authorization::Pending;

=encoding utf-8

=head1 NAME

Net::ACME::Authorization::Pending - pending ACME authorization

=head1 SYNOPSIS

    use Net::ACME::Authorization::Pending ();

    my $authz_p = Net::ACME::Authorization::Pending->new(
        uri => 'http://url/to/poll/for/authz',
        challenges => \@challenge_objects,
        combinations => [
            [ 2 ],
            [ 1 ],
            [ 0 ],
        ],
    );

    for my $cmb ( $authz_p->combinations() ) {

        #An example of only doing “http-01”:
        next if @$cmb > 1;
        next if $cmb->[0]->type() ne 'http-01';

        #Prepare for the challenge …

        #Assume we instantiated Net::ACME above …
        $acme->do_challenge($cmb->[0]);

        while (1) {
            if ($authz_p->is_time_to_poll()) {
                my $poll = $authz_p->poll();

                last if $poll->status() eq 'valid';

                if ($poll->status() eq 'invalid') {
                    my $completed_challenge = ($poll->challenges())[0];
                    print $completed_challenge->error()->detail() . $/;
                    die "Failed authorization!$/";
                }

            }

            sleep 1;
        }

        last;
    }

=cut

#NOTE: For now, this assumes a domain name.
#Might be useful moving forward to separate out other types
#of authz as per ACME spec expansion. (As of April 2016 only
#domain names are handled.)

use strict;
use warnings;

use parent qw( Net::ACME::RetryAfter );

use Call::Context ();

use Net::ACME::Authorization ();
use Net::ACME::Challenge     ();
use Net::ACME::Error         ();
use Net::ACME::X             ();

my $PENDING_CLASS = 'Net::ACME::Challenge::Pending';

sub new {
    my ( $class, %opts ) = @_;

    my $self = {
        _uri => $opts{'uri'} || die('Need “uri”!'),
        _challenges   => $opts{'challenges'},
        _combinations => $opts{'combinations'},
    };

    if ( !@{ $opts{'challenges'} } ) {
        die Net::ACME::X::create( 'Empty', { name => 'challenges' } );
    }

    for my $c ( 0 .. $#{ $opts{'challenges'} } ) {
        my $challenge = $opts{'challenges'}[$c];

        if ( !$challenge->isa($PENDING_CLASS) ) {
            die "Challenge $c ($challenge) is not an instance of “$PENDING_CLASS”!";
        }
    }

    bless $self, $class;

    return $self;
}

sub combinations {
    my ($self) = @_;

    Call::Context::must_be_list();

    return map {
        [ map { $self->{'_challenges'}[$_] } @$_ ]
    } @{ $self->{'_combinations'} };
}

sub _handle_non_202_poll {
    my ( $self, $resp ) = @_;

    $resp->die_because_unexpected() if $resp->status() != 200;

    my $payload = $resp->content_struct();

    my @challenge_objs;

    for my $c ( @{ $payload->{'challenges'} } ) {

        #We only care here about challenges that have been resolved.
        next if $c->{'status'} eq 'pending';

        my $err = $c->{'error'};
        $err &&= Net::ACME::Error->new(%$err);

        push @challenge_objs, Net::ACME::Challenge->new(
            status => $c->{'status'},
            error  => $err,
        );
    }

    return Net::ACME::Authorization->new(
        status     => $payload->{'status'},
        challenges => \@challenge_objs,
    );
}

1;
