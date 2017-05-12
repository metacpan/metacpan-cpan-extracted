#!/usr/bin/perl -w
# Cursor.pm
#
#

package SDL::Cursor;
use strict;
use SDL::sdlpl;


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	my %options = @_;
	$self->{-data} = $options{-data};
	$self->{-mask} = $options{-mask};
	$self->{-x} = $options{-x};
	$self->{-y} = $options{-y};
	$self->{-cursor} = SDL::sdlpl::sdl_new_cursor($self->{-data},$self->{-mask},
				$self->{-x},$self->{-y});
	bless $self, $class;
	return $self;
}

sub DESTROY {
	my $self = shift;
	SDL::sdlpl::sdl_free_cursor($self->{-cursor});
}

sub warp {
	my ($self,$x,$y) = @_;
	SDL::sdlpl::sdl_warp_mouse($x,$y);
}

sub use {
	my $self = shift;
	SDL::sdlpl::sdl_set_cursor($self->{-cursor});
}

sub get {
	return SDL::sdlpl::sdl_get_cursor();
}

sub show {
	my $self = shift;
	my $toggle = shift || 0;
	return SDL::sdlpl::sdl_show_cursor($toggle);
}

1;

__END__;

=head1 NAME

SDL::Cursor - a SDL perl extension

=head1 SYNOPSIS

 $cursor = new SDL::Cursor 	-data => new SDL::Surface "cursor.png", 
				-mask => new SDL::Surface "mask.png",
				-x => 0, -y => 0;


=head1 DESCRIPTION

	To create a new cursor, create a new instance of the Cursor
class passing it two surfaces as shown in the example.  The x and
y values indicate the position of the hot-spot for clicking.

To move the cursor to a position on the screen use the warp method
passing the values of x and y.  The warp function does not require
an instance to have been created, and can be safely used directly.

	SDL::Cursor::warp(x,y);
	$cursor->warp(200,200);

Similary, to toggle the visible status of the cursor use the show method:

	SDL::Cursor::show(0);	# this hides the cursor
	$cursor->show(1);	# make the cursor visible

If you have created a new Cursor, to set it as the active cursor use
the method 'use':

	$cursor->use();

Finally, if you are using more than one instance of a SDL_Cursor *,
you may find the get method useful for finding out the current 
cursor.  

	SDL::Cursor::get();
	$cursor->get();

NB: This will not return the value of that instance, but rather the
instance currently in use;
	

=head1 AUTHOR

David J. Goehrig

=head1 SEE ALSO

perl(1) SDL::Surface(3).

=cut	
