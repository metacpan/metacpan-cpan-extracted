package Net::Twitter::Diff;

use warnings;
use strict;
use Moose;
extends 'Net::Twitter::Core';
with 'Net::Twitter::Role::API::REST';

use Array::Diff;

our $VERSION = '0.12';

sub xfollowing {
    my $self = shift;
    my $id   = shift;

    my $cursor = -1;
    my @data = ();
    while(1){
        my $args = { cursor => $cursor } ;
        $args->{id} = $id if $id;
        my $res = $self->following( $args );
        push @data , @{ $res->{users} };

        $cursor = $res->{next_cursor};
        last if $cursor == 0;
    }

    return \@data;
}

sub xfollowers {
    my $self = shift;

    my $cursor = -1;
    my @data   = ();
    while(1){
        my $res = $self->followers({ cursor => $cursor });
        push @data , @{ $res->{users} };

        $cursor = $res->{next_cursor};
        last if $cursor == 0;
    }

    return \@data;
}

sub diff {
    my $self = shift;
    my $args = shift;

    my $res = {};
    my @following = map { $_->{screen_name} } @{$self->xfollowing};
    my @followers = map { $_->{screen_name} } @{$self->xfollowers};

    my $diff = Array::Diff->diff( [ sort @followers ] , [ sort @following ] );

    $res->{not_following} = $diff->deleted;
    $res->{not_followed}  = $diff->added;
    my @communicated = ();
    my $not_followed_ref = {};
    for my $user ( @{  $res->{not_followed} } ) {
           $not_followed_ref->{ $user } = 1;
    }

    for my $screen_name ( @following ) {
        if ( !defined $not_followed_ref->{ $screen_name  } ) {
            push @communicated , $screen_name;
        }
    }

    $res->{communicated} = \@communicated;

    return $res;
}


sub comp_following {
    my $self = shift;
    my $id   = shift;

    my $res = {};
    my $me_ref = $self->xfollowing();
    my $him_ref = $self->xfollowing( $id );

    my $me  = [];
    my $him = [];
    my $me_hash = {};
    for my $item ( @{ $me_ref } ) {
        push @{ $me } , $item->{screen_name};
        $me_hash->{ $item->{screen_name} } = 1;
    }

    for my $item ( @{ $him_ref } ) {
        push @{ $him } , $item->{screen_name};
    }

    my $diff = Array::Diff->diff( [sort @$me ], [ sort @$him ] );

    $res->{only_me} = $diff->deleted;
    $res->{not_me}  = $diff->added;
    my @communicated = ();

    for my $screen_name ( @{ $him } ) {
        if ( defined $me_hash->{ $screen_name  } ) {
            push @communicated , $screen_name;
        }
    }

    $res->{share} = \@communicated;

    return $res;
}

1;

=head1 NAME

Net::Twitter::Diff - Twitter Diff

=head1 SYNOPSIS

    use Net::Twitter::Diff;

    my $diff = Net::Twitter::Diff->new(  username => '******' , password => '******');

    my $res = $diff->diff();

    # get screen_names who you are not following but they are.
    print Dumper $res->{not_following};

    # get screen_names who they are not following but you are.
    print Dumper $res->{not_followed};

    # get screen_names who you are following them and also they follow you.
    print Dumper $res->{communicated};


    my $res2 = $diff->comp_following( 'somebody_twitter_name' );

    # only you are following
    print Dumper $res2->{only_me} ;

    # you are not following but somebody_twitter_name are following
    print Dumper $res2->{not_me} ;

    # both you and somebody_twitter_name are following
    print Dumper $res2->{share} ;


=head1 DESCRIPTION

Handy when you want to know relationshops between your followers and followings
and when you wnat to compare your following and somebody's.

=head1 METHOD

=head2 diff

run diff

response hash

=over 4

=item B<not_following>

get screen_names who you are not following but they are.

=item B<not_followed>

get screen_names who they are not following but you are.

=item B<communicated>

get screen_names who you are following them and also they follow you.

=back

=head2 comp_following( $twitter_id )

compaire your following and somebody's

response hash

=over 4

=item B<only_me>

only you are following

=item B<not_me>

you are not following but somebody is following

=item B<share>

both you and somebody are following.

=back

=head2 xfollowing

can get more that 100 followings.

=head2 xfollowers

can get more that 100 followers.

=head1 SEE ALSO

L<Net::Twitter>

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=cut
