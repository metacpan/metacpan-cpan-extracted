use strict;
package Siesta::Message;
use Siesta;
use Siesta::Deferred;
use Mail::Address;
use Carp qw( carp croak );
use Storable qw(dclone);
use base qw( Email::Simple Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( plugins ));

=head1 NAME

Siesta::Message - a message in the system

=head1 METHODS

=cut

# make a bunch of header-based accessors
for (qw( to_raw from_raw subject )) {
    my $header = $_;
    my $sub_name = $header;
    $header   =~ s/_raw$//;
    my $sub = sub {
        my $self = shift;
        if (@_) {
            $self->header_set( $header, shift );
        }
        return $self->header( $header );
    };
    no strict 'refs';
    *{ $sub_name } = $sub;
}

sub new {
    my $referent = shift;
    my $class = ref $referent || $referent;
    my $data  = shift || "";

    if (ref $data eq 'GLOB') {
        $data = join '', <$data>;
    }
    # chomp out From_ lines from naughty MTAs
    $data =~ s/^From .+$//m;

    my $self = $class->SUPER::new( $data );
    $self->plugins( [] );
    return $self;
}


=head2 to

a list of addresses that the message was to

=cut

sub to {
    my $self = shift;
    map { $_->address } Mail::Address->parse( $self->header('To') );
}

=head2 from

the email address that the message was from

=cut

sub from {
    my $self = shift;

    ( map { $_->address } Mail::Address->parse( $self->header('From') ) )[0];
}

=head2 subject

=head2 reply

=cut

sub reply {
    my $self  = shift;
    my %args  = @_;

    my $new = Siesta::Message->new;
    $new->body_set( $args{body} || $self->body );
    $new->header_set( 'To',          $args{to}      || $self->from );
    $new->header_set( 'From',        $args{from}    || ( $self->to )[0] );
    $new->header_set( 'Subject',     $args{subject} ||
                        "Re: " . ( $self->subject || "Your mail" ) );
    $new->header_set( 'In-Reply-To', $self->header( 'Message-Id' ) );

    $new->send;
    Siesta->log("Message->reply sending" . $new->as_string, 10);
}

=head2 send

=cut

sub send {
    my $self = shift;
    return Siesta->sender->send( $self, @_ );
}

=head2 clone

=cut

sub clone {
    my $self = shift;

    return dclone $self;
}

=head2 defer

=cut

sub defer {
    my $self = shift;

    Siesta::Deferred->create({
        @_,
        plugins => join(',', @{ $self->plugins } ),
        message => $self,
    });
}


# XXX compatibility shim, excise soonest
sub resume {
    my $self = shift;
    my $id   = shift;

    carp "Siesta::Message->resume is deprected, use resume on a Siesta::Deferred object instead";
    my $deferred = Siesta::Deferred->retrieve( $id );
    $deferred->resume;
}

sub process {
    my $self = shift;

    while ( my $plugin = shift @{ $self->plugins } ) {
        # SIESTA_NON_STOP is used by 20fullsend.t to ensure
        # excercising of everything. it means "run the next plugin,
        # even if the last one said to stop"
        Siesta->log("... doing " . $plugin->name, 1);
        return if $plugin->process($self) && !$ENV{SIESTA_NON_STOP};
    }
}

1;
