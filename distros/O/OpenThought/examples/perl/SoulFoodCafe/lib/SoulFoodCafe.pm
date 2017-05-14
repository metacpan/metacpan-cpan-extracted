package SoulFoodCafe;

use strict;
use lib "/home/eric/code/openthought2/lib";
use base 'CGI::Application';
use OpenThought();
use Apache::Session::File;

sub setup {
    my $self = shift;

    $self->run_modes([ qw(
            open_store
            show_storefront
            get_info
            get_menu
            add_item
            remove_item
            check_order
            checkout
            good_bye
    )]);

    $self->start_mode('open_store');
    $self->mode_param('run_mode');

}

sub cgiapp_init {
    my $self = shift;
    my $q    = $self->query;

    $self->param( 'OpenThought' => OpenThought->new() );

    my $session_id = $q->param('_session_id');
    my %session;

    if ( $session_id ) {
        $session_id =~ m/^(\w+)$/;
        $session_id = $1;
    }
    else {
        $session_id = undef;
    }

    tie %session, 'Apache::Session::File', $session_id, {
        Directory     => '/tmp/',
        LockDirectory => '/tmp/',
        Transaction   => 1
    };

    $self->param( 'session' => \%session );
    $session{SoulFoodCafe} || $self->_gen_menu_info();
}


sub teardown {
    my $self = shift;

}


sub open_store {
    my $self = shift;

    return $self->show_storefront;

}

sub get_menu {
    my $self = shift;
    my $OT   = $self->param('OpenThought');

    my $data;
    $data->{menu}       = $self->_get_menu_items();
    $data->{dinner}     = $self->_get_dinner();
    $data->{total_cost} = $self->_get_total_cost();

    $OT->param($data);
    return $OT->response();
}

sub add_item {
    my $self = shift;
    my $q    = $self->query;
    my $OT   = $self->param('OpenThought');

    my $menu_item = $q->param('menu');

    if ($menu_item eq "" ) {
        my $message   = "You have not selected an item!";
        my $javascript = "alert('$message')";

        $OT->javascript($javascript);
        return $OT->response();
    }
    else {
        my $added_item  = $self->_add_dinner_item( $menu_item );
        my $data;
        $data->{dinner}     = $added_item;
        $data->{total_cost} = $self->_get_total_cost;

        $OT->param($data);
        return $OT->response();
    }
}

sub remove_item {
    my $self = shift;
    my $q    = $self->query;
    my $OT   = $self->param('OpenThought');

    my $dinner_item = $q->param('dinner');

    if ($dinner_item eq "" ) {
        my $message   = "You have not selected an item!";
        my $javascript = "alert('$message')";

        $OT->javascript($javascript);
        return $OT->response();
    }
    else {
        my $removed_item  = $self->_remove_dinner_item( $dinner_item );

        my $data;

        $data->{dinner}     = $self->_get_dinner() if $removed_item;
        $data->{total_cost} = $self->_get_total_cost;

        $OT->param($data);
        $OT->focus("dinner");
        return $OT->response();
    }
}

sub show_storefront {
    my $self = shift;
    my $session = $self->param('session');

    my $template;

    # load_tmpl() uses HTML::Template to load a template document
    my $template_path = $self->_get_template_path;

    $template = $self->load_tmpl( "${template_path}/storefront.html" );
    $template->param({ session_id => $session->{_session_id} });

    return $template->output;
}


sub get_info {
    my $self    = shift;
    my $q       = $self->query;
    my $OT      = $self->param('OpenThought');

    my $menu      = $q->param('menu');
    my $meal_info = $self->_get_menu_info( $menu );

    #return $OT->parse_and_output({ auto_param => $meal_info, { data_mode => "auto" } });
    $OT->param( $meal_info );
    $OT->focus( "menu" );

    return $OT->response();
}

sub check_order {
    my $self = shift;
    my $q    = $self->query;
    my $OT   = $self->param('OpenThought');

    if ( $self->_get_dinner and @{ $self->_get_dinner } > 0 ) {
        my $session = $self->param('session');
        $OT->url( 'index.pl' => {
                                  run_mode => "checkout",
                                  _session_id => $session->{_session_id},
                                });
        return $OT->response();
    }
    else {
        my $message   = "You have not chosen your dinner!\\n" .
                        "Might I suggest the fried chicken?";
        my $javascript = "alert('$message')";

        $OT->javascript($javascript);
        return $OT->response();
    }

}

sub checkout {
    my $self = shift;
    my $session = $self->param('session');

    my $template_path = $self->_get_template_path;

    my $template = $self->load_tmpl( "${template_path}/checkout.html" );

    $template->param({ total_cost => $self->_get_total_cost,
                       session_id => $session->{_session_id} });

    return $template->output;
}

sub good_bye {
    my $self = shift;
    my $OT   = $self->param('OpenThought');

    my $message    = "Thanks for stopping by the Soul Food Cafe!";
    my $javascript = "alert('$message')";

    my $url = "http://openthought.net";

    $OT->javascript($javascript);
    $OT->url($url);
    return $OT->response();

}

sub _get_total_cost {
    my $self = shift;

    my $session = $self->param('session');

    return sprintf("%.2f", $session->{total_cost});
}

sub _add_dinner_item {
    my ( $self, $menu_id ) = @_;

    my $session = $self->param('session');

    my $add_item = [ $session->{menu}[$menu_id], $session->{unique_id}++ ];

    push @{ $session->{dinner} }, $add_item;
    $session->{total_cost} += $self->_get_menu_info( $menu_id )->{cost};

    $self->param('session' => $session );

    return $add_item;
}

sub _remove_dinner_item {
    my ( $self, $menu_item ) = @_;

    my $session = $self->param('session');

    my $remove_item;
    my $dinner         = $session->{dinner};
    $session->{dinner} = ();

    foreach my $item ( @{ $dinner } ) {
        if ( $item->[1] == $menu_item ) {
            $remove_item = $item;
            next;
        }

        push @{ $session->{dinner} }, $item;
    }

    return unless $remove_item;

    my $menu_id;
    for ( $menu_id = 0; $menu_id < @{ $session->{menu} }; $menu_id++ ) {
        last if $session->{menu}[$menu_id] eq $remove_item->[0];
    }

    $session->{total_cost} -= $self->_get_menu_info( $menu_id )->{cost};

    $self->param('session' => $session );

    return $remove_item;
}

sub _get_dinner {
    my $self = shift;

    my $session = $self->param('session');


#    if ( defined $session->{dinner} and
#         scalar @{ $session->{dinner} } > 0 ) {
        return $session->{dinner};
#    }
#    else {
#        return [ "-- Add Dinner Items --" ];
#    }
}

sub _get_menu_items {
    my $self = shift;

    my $session = $self->param('session');

    my $menu;

    for ( my $i=0; $i < @{ $session->{menu} }; $i++ ) {
        push @{ $menu }, [ $session->{menu}[$i], $i ];
    }

    return $menu;
}

sub _get_menu_info {
    my ( $self, $menu_item ) = @_;

    my $session = $self->param('session');

    return $session->{menu_info}[ $menu_item ];
}

sub _gen_menu_info {
    my $self    = shift;
    my $session = $self->param('session');

    # Generate menu information, but only if we haven't done it already
    unless ( exists $session->{SoulFoodCafe} and
             $session->{SoulFoodCafe} eq "open" ) {

        $session->{dinner} = ();
        $session->{total_cost} = 0;

        $session->{menu} = [
            "Fried Chicken",
            "Chicken Wings",
            "Chicken Nuggets",
            "Dry White Toast",
            "Dry Wheat Toast",
            "Coke",
            "Sprite",
        ];

        $session->{menu_info} = [
            {
                info => 'Best %*$# chicken in the state!',
                cost => '14.99',
            },
            {
                info => 'Hot wings',
                cost => '3.99',
            },
            {
                info => 'Tender chicken nuggets',
                cost => '1.69',
            },
            {
                info => 'Just plain white toast',
                cost => '1.30',
            },
            {
                info => 'Just plain wheat toast',
                cost => '1.30',
            },
            {
                info => 'A Coke',
                cost => '0.99',
            },
            {
                info => 'A Sprite',
                cost => '0.99',
            },
        ];

        $session->{unique_id} = 0;

        $session->{SoulFoodCafe} = "open";

        $self->param('session' => $session );
    }
}

sub _get_template_path {
    my $self = shift;

    return "$SoulFoodCafe::Path/templates";
}

1;
