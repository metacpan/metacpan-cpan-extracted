package Net::Async::Slack::Message;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION

use Scalar::Util qw(weaken);
use JSON::MaybeXS;

my $json = JSON::MaybeXS->new;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    weaken $self->{slack};
    $self
}

sub slack { shift->{slack} }
sub channel { shift->{channel} }
sub thread_ts { shift->{thread_ts} }

sub update {
    my ($self, %args) = @_;
    die 'You need to pass either text or attachments' unless $args{text} || $args{attachments};

    $args{text} //= '';
    my @content;
    push @content, token => $self->slack->token;
    push @content, channel => $self->channel;
    push @content, ts => $self->thread_ts;

    push @content, text => $args{text} if defined $args{text};
    push @content, attachments => $json->encode($args{attachments}) if $args{attachments};
    $args{as_user} //= 'true';
    push @content, $_ => $args{$_} for grep exists $args{$_}, qw(parse link_names unfurl_links unfurl_media as_user reply_broadcast);
    $self->slack->http_post(
        $self->slack->endpoint(
            'chat.update',
        ),
        \@content,
    )
}

1;
