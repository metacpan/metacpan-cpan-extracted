#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Author.pm,v 1.2 1998/03/09 03:18:15 ken Exp $
#

#
# `Author' is based loosely on the `vCard' specification,
# http://www.versit.com/
#

package Quilt::DO::Author;
use strict;

use Quilt;

# $self may be an Iter
sub name {
    my $self = shift; my $builder = shift; my $parent = shift;

    my $formatted_name = $self->formatted_name;
    if (defined $formatted_name	&& $#$formatted_name != -1) {
	$self->children_accept_formatted_name ($builder, $parent, @_);
	return;
    }

    my $given_name = $self->given_name;
    my $family_name = $self->family_name;
    if ((defined $given_name && $#$given_name != -1)
	|| (defined $family_name && $#$family_name != -1)) {
	$self->children_accept_given_name ($builder, $parent, @_);

	# push a space if both a given and a family name
	if ((defined $given_name && $#$given_name != -1)
	    && (defined $family_name && $#$family_name != -1)) {
	    $parent->push (" ");
	}

	$self->children_accept_family_name ($builder, $parent, @_);
	return;
    }

    my $other_name = $self->other_name;
    if (defined $other_name && $#$other_name != -1) {
	$self->children_accept_other_name ($builder, $parent, @_);
    }

    $self->children_accept ($builder, $parent, @_);
}

sub address {
    my ($self) = @_;
    my ($str) = undef;

    $str .= $self->{'postoffice_address'}->as_string() . "\n"
	if (defined $self->{'postoffice_address'});

    $str .= $self->{'street'}->as_string() . "\n"
	if (defined $self->{'street'});

    my ($locality, $region, $postalcode);
    $locality = $self->{'locality'}->as_string
	if (defined $self->{'locality'});
    $region = $self->{'region'}->as_string
	if (defined $self->{'region'});
    $postalcode = $self->{'postal_code'}->as_string
	if (defined $self->{'postal_code'});

    $str .= $locality   if (defined $locality);
    $str .= ", "        if (defined $locality && defined $region);
    $str .= $region     if (defined $region);
    $str .= "  "        if (defined $locality || defined $region);
    $str .= $postalcode if (defined $postalcode);
    $str .= "\n"        if (defined $locality || defined $region
			    || defined $postalcode);

    $str .= $self->{'country'}->as_string() . "\n"
	if (defined $self->{'country'});

    return $str;
}

package Quilt::DO::Author::Iter;

sub name {
    &Quilt::DO::Author::name;
}

1;
