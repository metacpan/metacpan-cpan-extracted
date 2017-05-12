package Perl::Dist::Asset::Website;

use strict;
use Carp         'croak';
use Params::Util qw{ _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	name
	url
	icon_file
	icon_index
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# If we have an icon, default to the first one in it
	if ( defined $self->icon_file and ! defined $self->icon_index ) {
		$self->{icon_index} = 0;
	}

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Did not provide a name");
	}
	unless ( _STRING($self->url) ) {
		croak("Did not provide a URL");
	}

	return $self;
}

sub file {
	$_[0]->name . '.url';
}

sub content {
	my $self    = shift;
	my @content = "[InternetShortcut]\n";
	push @content, "URL=" . $self->url;
	if ( $self->icon_file ) {
		push @content, "IconFile=" . $self->icon_file;
	}
	if ( $self->icon_index ) {
		push @content, "IconIndex=" . $self->icon_index;
	}
	return join '', map { "$_\n" } @content;
}

sub write {
	my $self = shift;
	my $to   = shift;
	open( WEBSITE, ">$to" )      or die "open($to): $!";
	print WEBSITE $self->content or die "print($to): $!";
	close WEBSITE                or die "close($to): $!";
	return 1;
}

1;
