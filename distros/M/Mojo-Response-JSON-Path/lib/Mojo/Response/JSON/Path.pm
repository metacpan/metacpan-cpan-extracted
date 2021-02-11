package Mojo::Response::JSON::Path;

# ABSTRACT: use JSON::Path for searching JSON responses

use Class::Method::Modifiers qw/install_modifier/;
use Mojo::Message;
use JSON::Path;

sub import {
    my $class = shift;

    install_modifier "Mojo::Message", 'around', 'json',
	sub {
	    my $orig = shift;
	    my $self = shift;

	    if (@_) {
		return JSON::Path->new($_[0])->value($orig->($self));
	    } else {
		return $orig->($self);
	    }
	};
}

1

