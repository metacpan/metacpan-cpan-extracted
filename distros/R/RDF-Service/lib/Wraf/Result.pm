#  $Id: Result.pm,v 1.2 2000/12/21 19:33:49 aigan Exp $  -*-perl-*-

package Wraf::Result;

#=====================================================================
#
# DESCRIPTION
#   Class for storing the result of actions for display in TT2
#   templates
#
# AUTHOR
#   Jonas Liljegren   <jonas@paranormal.se>
#
# COPYRIGHT
#   Copyright (C) 2000 Jonas Liljegren.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#=====================================================================

use strict;
use vars qw( $error_types );
use Data::Dumper;
use RDF::Service::Cache qw( $Level );

sub new
{
    my( $class ) = @_;
    my $self =
    {
	part => [],
	error => 0,
	info => {},
    };

    return bless {}, $class;
}

sub parts
{
    return $_[0]->{'part'};
}

sub message
{
    my( $self, $message ) = @_;

    push @{$self->{'part'}}, {'message' => $message};
}

sub exception
{
    my( $self ) = @_;

#    warn("Exception: ".Dumper($@, \@_)."\n");

    if( $dbi::errstr )
    {
	return $self->error('dbi', $dbi::errstr);
    }
    elsif(  ref($@) )
    {
	return $self->error(@{$@});
    }
    else
    {
	return $self->error('action', $@);
    }
}

sub error
{
    my( $self, $type, $message ) = @_;

#    warn("Error call: ".Dumper(\@_)."\n");

    $error_types ||=
    {
	'dbi'        => 
	    {
		'title'   => 'Database error',
		'border'  => 'red',
		'bg'      => 'AAAAAA',
	    },
	'incomplete' =>
	    {
		'title'   => 'Form incomplete',
		'bg'      => 'yellow',
	    },
	'template'   => 
	    {
		'title'   => 'Template error',
	    },
	'action'     => 
	    {
		'title'   => 'Action error',
		'bg'      => 'red',
	    },
    };
    
    my $params = $error_types->{$type} || {};

    $params->{'type'} ||= $type;
    $params->{'title'} ||= "\u$type error";
    $params->{'message'} = $message;

    push @{$self->{'part'}}, $params;
    $self->{'error'}++;
}

1;
