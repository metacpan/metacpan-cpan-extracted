package Rapi::Blog::DB::Component::SafeResult;

use strict;
use warnings;
 
use parent 'DBIx::Class::Core';
use RapidApp::Util ':all';

our $ALLOW = 0;

sub _caller_not_allowed {
	my $self = shift;
	return 0 if ($ALLOW);
	return $self->_caller_is_template;
}

sub _caller_is_template {
	if(my $c = RapidApp->active_request_context) {
		return 1 if($c->controller('RapidApp::Template')->Access->currently_viewing_template);
	}
	return 0;
}

sub insert {
	my $self = shift;
	$self->_caller_not_allowed and die "INSERT denied";
	$self->next::method(@_)
}

sub update {
	my $self = shift;
	$self->_caller_not_allowed and die "UPDATE denied";
	$self->next::method(@_)
}

sub delete {
	my $self = shift;
	$self->_caller_not_allowed and die "DELETE denied";
	$self->next::method(@_)
}


1;