# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package OWL::LSID;

use strict;
use warnings;

use base 'URI::urn';


#
# new - Creates a new LS::ID object from a string
#
#   Parameters: A URI containing the LSID
#
#   Returns: An LS::ID object if successful,
#        undef if the URI is not in the correct form
#
sub new {
    my ($class, $uri) = @_;

    return undef unless _is_valid($uri);

    return bless \$uri, $class;
}


#
# _is_valid - Determines whether or not the LSID is a valid LSID
#
#   Returns: undef if the LSID is not valid,
#        true if the LSID is valid
#
sub _is_valid {
    my ($string) = @_;

    return $string =~ /^[uU][rR][nN]:[lL][sS][iI][dD]:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*(:[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\!\*\']*)?$/;
}


#
# _component -
#
sub _component {
    my $self = shift;
    my $index = shift;

    my @components = split(/:/, $self->nss());
    my $value = $components[$index];

    if (@_) {
        if (($index == 3 && $_[0] eq '') || ($_[0] =~ /^[A-Za-z0-9][\w\(\)\+\,\-\.\=\@\;\$\"\_\!\*\']*$/)) {
            $components[$index] = $_[0];
            $self->nss(join(':', @components));
            
            return 1;
        }
        else {
            return undef;
        }
    }

    return $value;
}


#
# _authority - Access to the raw authority component of the LSID
#
#   Returns: The raw string of the authority component
#
sub _authority {
    my $self = shift;
    return $self->_component(0, @_);
}


#
# authority - Access to the authority component of the LSID
#
#   Returns: The authority component
#
sub authority {
    my $self = shift;
    return lc $self->_authority(@_);
}


#
# _namespace -
#
sub _namespace {
    my $self = shift;
    return $self->_component(1, @_);
}


#
# namespace - Access to the namespace component of the LSID
#
#   Returns: The namespace component
#
sub namespace {
    my $self = shift;
    return $self->_namespace(@_);
}


#
# _object -
#
sub _object {
    my $self = shift;
    return $self->_component(2, @_);
}


#
# object - Access to the object component of the LSID
#
#   Returns: The object component
#
sub object {
    my $self = shift;
    return $self->_object(@_);
}


#
# _revision -
#
sub _revision {
    my $self = shift;
    return $self->_component(3, @_);
}


#
# revision - Access to the revision component of the LSID
#
#   Returns: The revision component
#
sub revision {
    my $self = shift;
    return $self->_revision(@_);
}


#
# canonical - Retrieves the canonicalized form of the LSID
#
#   Parameters:
#
#   Returns: The canonicalized LSID if successful,
#        undef if unsuccessful
#
sub canonical {

    my $self = shift;   
    my $nss = $self->nss;

    my $new = $self->SUPER::canonical();

    # If the scheme portion of the URN is not lowercase, e.g. "URN",
    # URI::canonical will reset the scheme to lc scheme, which in turn will
    # rebless the object as a URI::urn. In case this happens, we need to
    # rebless it as an LS::ID here.

    bless ($new, __PACKAGE__) if (ref $new ne __PACKAGE__);

    return $new if $nss !~ /[A-Z]/ && $nss !~ /:$/;

    $nss =~ s/:$//;

    $new = $new->clone() if $new == $self;
    $new->authority(lc($self->authority()));

    return $new;
}


1;

__END__
