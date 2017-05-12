package CollectionTests;

use Test::More;
use Data::Dumper;

##
## try adding
##
sub test_add {
    my $class = shift;
    my $ed    = shift;
    my $obj   = shift;
    my $name  = $ed->object_name;

    my $view = $ed->add( $obj );
    if (isa_ok( $view, 'Pangloss::Application::View', 'add' )) {
	if (isa_ok( $view->{$name}, $obj->class, " view->$name" )) {
	    ok( $view->{add}->{$name},   " view->add->$name" );
	    ok( $view->{$name}->{added}, " view->$name->added" );
	    ok( $view->{$name}->date,    " view->$name->date set" );
	}
	unlike( $view->{$name}->{error}, qr/./, " view->$name->error" ) or
	  diag( Dumper( $view->{$name}->{error} ) );
    }

    return $view;
}

sub test_add_existing {
    my $class = shift;
    my $ed    = shift;
    my $obj   = shift;
    my $name  = $ed->object_name;

    my $new_obj = $obj->clone;
    my $view    = $ed->add( $new_obj );
    if (isa_ok( $view, 'Pangloss::Application::View', 'add existing' )) {
	my $e = $view->{add}->{$name}->{error};
	if (ok( $e, " view->add->$name->error" )) {
	    ok( $e->isExists, " error->isExists" );
	} else {
	    diag( Dumper( $view ) );
	}
    }

    return $view;
}


##
## try listing collections
##
sub test_list {
    my $class = shift;
    my $ed    = shift;
    my $names = $ed->objects_name;

    my $view = $ed->list();
    if (isa_ok( $view, 'Pangloss::Application::View', 'list' )) {
	isa_ok( $view->{"$names\_collection"}, 'Pangloss::Collection',
		" view->$names\_collection" );
	if (isa_ok( $view->{$names}, 'ARRAY', " view->$names" )) {
	    ok( @{$view->{$names}}, ' contains some items' );
	} else {
	    diag( Dumper( $view ) );
	}
    }

    return $view;
}


##
## try getting a collection
##
sub test_get {
    my $class = shift;
    my $ed    = shift;
    my $obj   = shift;
    my $name  = $ed->object_name;

    my $view = $ed->get( $obj->key );
    if (isa_ok( $view, 'Pangloss::Application::View', 'get' )) {
	if (isa_ok( $view->{$name}, $obj->class, " view->$name" )) {
	    ok( $view->{get}->{$name}, " view->get->$name" );
	} else {
	    diag( $view->{$name}->{error} );
	}
    }

    return $view;
}

sub test_get_non_existent {
    my $class = shift;
    my $ed    = shift;
    my $obj   = shift;
    my $name  = $ed->object_name;

    my $view = $ed->get( 'non-existent' );
    if (isa_ok( $view, 'Pangloss::Application::View', 'get non-existent' )) {
	my $e = $view->{get}->{$name}->{error};
	if (ok( $e, " view->get->$name->error" )) {
	    ok( $e->isNonExistent, " error->isNonExistent" );
	} else {
	    diag( Dumper( $view ) );
	}
    }

    return $view;
}


##
## try modifying some details
##
sub test_modify {
    my $class   = shift;
    my $ed      = shift;
    my $obj     = shift;
    my $new_obj = shift;
    my $name    = $ed->object_name;

    my $view = $ed->modify( $obj->key, $new_obj );
    if (isa_ok( $view, 'Pangloss::Application::View', 'modify_collection 2' )) {
	if (isa_ok( $view->{$name}, $obj->class, " view->$name" )) {
	    ok( $view->{modify}->{$name},                " view->modify->$name" );
	    ok( $view->{$name}->{modified},              " view->$name->modified" );
	    is( $view->{$name}->key, $new_obj->key,      " view->$name->key as expected" );
	    is( $view->{$name}->creator, $obj->creator,  " view->$name->creator preserved" );
	}
	unlike( $view->{$name}->{error}, qr/./, " view->$name->error" ) or
	  diag( Dumper( $view->{$name}->{error} ) );
    }

    my $view2 = $ed->get( $new_obj->key );
    if (isa_ok( $view2, 'Pangloss::Application::View', 'objects updated after modify' )) {
	isa_ok( $view2->{$name}, $new_obj->class, " view->$name" );
    }

    return $view;
}


##
## try removing a collection
##
sub test_remove {
    my $class = shift;
    my $ed    = shift;
    my $obj   = shift;
    my $name  = $ed->object_name;

    my $view = $ed->remove( $obj->key );
    if (isa_ok( $view, 'Pangloss::Application::View', 'remove' )) {
	if (isa_ok( $view->{$name}, $obj->class, " view->$name" )) {
	    ok( $view->{remove}->{$name},  " view->remove->$name" );
	    ok( $view->{$name}->{removed}, " view->$name->removed" );
	}
	unlike( $view->{$name}->{error}, qr/./, " view->$name->error" ) or
	  diag( Dumper( $view->{$name}->{error} ) );
    }

    return $view;
}

sub test_remove_non_existent {
    my $class = shift;
    my $ed    = shift;
    my $name  = $ed->object_name;

    my $view = $ed->remove( 'non-existent' );
    if (isa_ok( $view, 'Pangloss::Application::View', 'remove non-existent' )) {
	my $e = $view->{remove}->{$name}->{error};
	if (ok( $e, " view->{remove}->$name->error" )) {
	    ok( $e->isNonExistent, " error->isNonExistent" );
	} else {
	    diag( Dumper( $view ) );
	}
    }

    return $view;
}

1;
