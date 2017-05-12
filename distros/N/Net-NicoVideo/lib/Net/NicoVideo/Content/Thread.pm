package Net::NicoVideo::Content::Chat;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Class::Accessor::Fast);

use vars qw(@Members);
@Members = qw(
thread
no
vpos
date
mail
user_id
anonymity
value
);
__PACKAGE__->mk_accessors(@Members);

sub members {
    @Members;
}


package Net::NicoVideo::Content::ViewCounter;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.27_01';

use base qw(Class::Accessor::Fast);

use vars qw(@Members);
@Members = qw(
video
id
mylist
);
__PACKAGE__->mk_accessors(@Members);

sub members {
    @Members;
}

package Net::NicoVideo::Content::Thread;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.27_01';

use base qw(Net::NicoVideo::Content Class::Accessor::Fast);
use XML::TreePP;

use vars qw(@Members);
@Members = qw(
resultcode
thread
last_res
ticket
revision
fork
server_time

view_counter
chats
);
__PACKAGE__->mk_accessors(@Members);

sub members { # implement
    @Members;
}

sub parse { # implement
    my $self = shift;
    $self->load($_[0]) if( defined $_[0] );

    my $tree = XML::TreePP->new( force_array => 'chat' )
                ->parse($self->_decoded_content);
    
    my @chats = ();
    for my $c ( @{$tree->{packet}->{chat}} ){
        push @chats, Net::NicoVideo::Content::Chat->new({
            thread      => $c->{-thread},
            no          => $c->{-no},
            vpos        => $c->{-vpos},
            date        => $c->{-date},
            mail        => $c->{-mail},
            user_id     => $c->{-user_id},
            anonymity   => $c->{-anonymity},
            value       => $c->{'#text'},
            });
    }

    my $v = $tree->{packet}->{view_counter};
    my $vc = Net::NicoVideo::Content::ViewCounter->new({
        video       => $v->{-video},
        id          => $v->{-id},
        mylist      => $v->{-mylist},
        });
    
    my $t = $tree->{packet}->{thread};
    $self->resultcode(  $t->{-resultcode}   );
    $self->thread(      $t->{-thread}       );
    $self->last_res(    $t->{-last_res}     );
    $self->ticket(      $t->{-ticket}       );
    $self->revision(    $t->{-revision}     );
    $self->fork(        $t->{-fork}         );
    $self->server_time( $t->{-server_time}  );
    $self->view_counter($vc                 );
    $self->chats(       \@chats             );
    
    # status
    if( defined $self->resultcode ){
        $self->set_status_success;
    }else{
        $self->set_status_error;
    }
    
    return $self;
}

sub count {
    my $self = shift;
    scalar @{$self->chats};
}

sub get_comments {
    my $self = shift;
    wantarray ? @{$self->chats} : $self->chats;
}

1;
__END__
