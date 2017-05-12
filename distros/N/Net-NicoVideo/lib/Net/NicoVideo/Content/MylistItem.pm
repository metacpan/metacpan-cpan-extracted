package Net::NicoVideo::Content::MylistItem;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Content Class::Accessor::Fast);
use HTML::Parser 3.00;

use vars qw(@Members);
@Members = qw(
item_type
item_id
description
token
);

__PACKAGE__->mk_accessors(@Members);

sub members { # implement
    my @copy = @Members;
    @copy;
}

sub parse { # implement
    my $self = shift;
    $self->load($_[0]) if( defined $_[0] );

    my $content = $self->_decoded_content;

    # take NicoAPI.token
    if( $content =~ /NicoAPI\.token\s*=\s*"([-\w]+)"/ ){
        $self->token( $1 );
    }

    # take item_type and item_id using HTML::Parser
    my $item_type   = undef;
    my $item_id     = undef;
    my $description = undef;
    my $p;
    $p = HTML::Parser->new(
        api_version => 3,
        start_h => [ sub {
                my ($tagname, $attr) = @_;
                if( lc($tagname) eq 'input' ){
                    if( exists $attr->{name} and lc($attr->{name}) eq 'item_type' ){
                        $item_type  = $attr->{value};
                    }
                    if( exists $attr->{name} and lc($attr->{name}) eq 'item_id' ){
                        $item_id    = $attr->{value};
                    }
                    if( exists $attr->{name} and lc($attr->{name}) eq 'description' ){
                        $description= $attr->{value};
                    }
                }
                $p->eof if( defined $item_type and defined $item_id and defined $description );
            }, 'tagname, attr']);
    $p->parse($content);
    $self->item_type( $item_type );
    $self->item_id( $item_id );
    $self->description( $description );

    # status
    if( defined $self->item_id and defined $self->item_type ){
        $self->set_status_success;
    }else{
        $self->set_status_error;
    }
    
    return $self;
}


1;
__END__

=pod

=head1 NAME

Net::NicoVideo::Content::MylistItem - item_type and item_id by video_id

=head1 SYNOPSIS

    Net::NicoVideo::Content::MylistItem->new({
        item_type   => 0,
        item_id     => 'sm00000000',
        description => 'mylist comment',
        token       => '12345678-1234567890-abcdef0123456789abcdef0123456789abcdef01',
        });

=head1 DESCRIPTION

Parsed content of the page L<http://www.nicovideo.jp/mylist_add/video/${video_id}>.

An important thing that this page is having "item_type" and "item_id" for specific $video_id,
and "token" to update Mylist.

=head1 SEE ALSO

L<Net::NicoVideo::Content>

L<Net::NicoVideo::Response::MylistItem>

=cut
