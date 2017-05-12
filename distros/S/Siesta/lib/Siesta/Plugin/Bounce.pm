use strict;
package Siesta::Plugin::Bounce;
use Siesta::Plugin;
use base 'Siesta::Plugin';
use Mail::DeliveryStatus::BounceParser;

# suggested usage  set_plugins( bounce => qw( Bounce ) );

sub description {
    'simple bounce handler';
}

sub process {
    my $self = shift;
    my $mail = shift;
    my $list = $self->list;

    my $deferred = $mail->defer(who => $list->owner,
                                why => "bounce");

    my $bounce = Mail::DeliveryStatus::BounceParser->new( $mail->as_string );
    my @addresses = grep { $_ } map { $_->get('email') } $bounce->reports;

    Siesta->log("bounce: ". $list->name . " " . join (', ', @addresses));

    if (grep { $_ eq $list->owner->email } @addresses) {
        # deep deep badness
        Siesta->log("holy shit, a listadmins mail is bouncing, so we can't tell them about it!");
        return;
    }
    $mail->reply( to      => $list->owner->email,
                  subject => $list->name . " bouncing subscriber(s)",
                  body    => join("\n", @addresses) );
    return;
}

1;
