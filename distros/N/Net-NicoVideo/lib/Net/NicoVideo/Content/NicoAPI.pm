package Net::NicoVideo::Content::NicoAPI;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Content Class::Accessor::Fast);
use JSON 2.01;

use vars qw(@Members);
@Members = qw(
id
mylistgroup
mylistitem
error
status
);

__PACKAGE__->mk_accessors(@Members);

sub members { # implement
    @Members;
}

sub parse { # implement
    my $self = shift;
    $self->load($_[0]) if( defined $_[0] );

    my $json = decode_json( $self->_decoded_content );

    # member "status" exists in all case
    $self->status( $json->{status} );

    # member "error" exists when error occurs in all case
    $self->error( Net::NicoVideo::Content::NicoAPI::Error->new($json->{error}) )
        if( $json->{error} );

    # member "id" in a case /mylist/add
    $self->id( $json->{id} )
        if( exists $json->{id} );

    # member "mylistgroup" in case /mylistgroup/list or /mylistgroup/get
    my @mg = ();
    if( exists $json->{mylistgroup} ){
        if( ref( $json->{mylistgroup} ) ne 'ARRAY' ){
            $json->{mylistgroup} = [$json->{mylistgroup}];
        }
        for my $mg ( @{$json->{mylistgroup}} ){
            push @mg, Net::NicoVideo::Content::NicoAPI::MylistGroup->new($mg);
        }
        $self->mylistgroup(\@mg);
    }

    # TODO member "mylistitem"
    my @mi = ();
    if( exists $json->{mylistitem} ){
        if( ref( $json->{mylistitem} ) ne 'ARRAY' ){
            $json->{mylistitem} = [$json->{mylistitem}];
        }
        for my $mi ( @{$json->{mylistitem}} ){
            my $item = Net::NicoVideo::Content::NicoAPI::MylistItem->new($mi);
            $item->item_data( Net::NicoVideo::Content::NicoAPI::MylistItem::ItemData->new($mi->{item_data}) );
            push @mi, $item;
        }
        $self->mylistitem(\@mi);
    }

    # status
    if( $self->is_status_ok ){
        $self->set_status_success;
    }else{
        $self->set_status_error;
    }
    
    return $self;
}

sub is_status_ok {
    my $self = shift;
    $self->status and lc($self->status) eq 'ok';
}

sub error_code {
    my $self = shift;
    $self->error and $self->error->code;
}

sub error_description {
    my $self = shift;
    $self->error and $self->error->description;
}

sub is_error_noauth {
    my $self = shift;
    $self->error and $self->error->code and uc($self->error->code) eq 'NOAUTH';
}


package Net::NicoVideo::Content::NicoAPI::Error;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Class::Accessor::Fast);
use vars qw(@Members);
@Members = qw(
code
description
);

__PACKAGE__->mk_accessors(@Members);

sub members {
    @Members;
}


package Net::NicoVideo::Content::NicoAPI::MylistGroup;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Class::Accessor::Fast);
use vars qw(@Members);
@Members = qw(
id
user_id
name
description
public
default_sort
create_time
update_time
sort_order
icon_id
);

__PACKAGE__->mk_accessors(@Members);

sub members {
    @Members;
}


package Net::NicoVideo::Content::NicoAPI::MylistItem;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Class::Accessor::Fast);
use vars qw(@Members);
@Members = qw(
item_type
item_id
description
item_data
watch
create_time
update_time
);

__PACKAGE__->mk_accessors(@Members);

sub members {
    @Members;
}


package Net::NicoVideo::Content::NicoAPI::MylistItem::ItemData;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Class::Accessor::Fast);
use vars qw(@Members);
@Members = qw(
video_id
title
thumbnail_url
first_retrieve
update_time
view_counter
mylist_counter
num_res
group_type
length_seconds
deleted
last_res_body
watch_id
);

__PACKAGE__->mk_accessors(@Members);

sub members {
    @Members;
}


1;
__END__
