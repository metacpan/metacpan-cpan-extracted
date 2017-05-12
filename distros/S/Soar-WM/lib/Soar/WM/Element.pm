#
# This file is part of Soar-WM
#
# This software is copyright (c) 2012 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Soar::WM::Element;
use strict;
use warnings;

our $VERSION = '0.04'; # VERSION
# ABSTRACT: Work with Soar working memory elements

use Carp;

sub new {
    my ( $class, $wm, $id ) = @_;
    if ( !exists $wm->{$id} ) {
        carp 'Given ID doesn\'t exist in given working memory';
        return;
    }

    my $self = bless {
        wm   => $wm,
        id   => $id,
        node => $wm->{$id},
    }, $class;
    return $self;
}

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub atts {
    my ($self) = @_;
    my @atts = keys %{ $self->{node} };
    return \@atts;
}

sub vals {
    my ( $self, $query ) = @_;
    if ( !$query ) {
        carp 'missing argument attribute name';
        return;
    }
	return [] unless exists $self->{node}->{$query};
    my @values = @{ $self->{node}->{$query} };
	
    #find ones that are links and change them into WME instances
    for ( 0 .. $#values ) {
        if ( exists $self->{wm}->{ $values[$_] } ) {
            $values[$_] = __PACKAGE__->new( $self->{wm}, $values[$_] );
        }
    }
    return \@values;
}

sub children {
    my ($self , %args) = @_;
	
	my @children;
	for my $key ( keys %{$self->{node}} ){
		push @children, @{ $self->{node}->{$key} };
	}
	
    #find ones that are links and change them into WME instances
    for ( 0 .. $#children ) {
        if ( exists $self->{wm}->{ $children[$_] } ) {
            $children[$_] = __PACKAGE__->new( $self->{wm}, $children[$_] );
        }
    }
	my $retVal;
	if($args{links_only}){
		my @links = grep {ref($_) eq 'Soar::WM::Element'} @children;
		$retVal = \@links;
	}else{
		$retVal = \@children;
	}
    return $retVal;
}

sub first_val {
    my ( $self, $query ) = @_;
    if ( !$query ) {
        carp 'missing argument attribute name';
        return;
    }
	return unless exists $self->{node}->{$query};

    # grab only the first value
    my $value = ${ $self->{node}->{$query} }[0];

	if(not defined $value){
		return;
	}
	
    #if value is a link, change it into a WME instance
    if ( exists $self->{wm}->{$value} ) {
        $value = __PACKAGE__->new( $self->{wm}, $value );
    }
    return $value;
}

sub num_links {
    my ($self) = @_;
    my $count = 0;

    #iterate values of each attribute; a child will have its own entry in WM
    for my $att ( @{ $self->atts } ) {
        for my $val ( @{ $self->{node}->{$att} } ) {
            $count++
              if ( exists $self->{wm}->{$val} );
        }
    }
    return $count;
}

1;

__END__

=pod

=head1 NAME

Soar::WM::Element - Work with Soar working memory elements

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Soar::WM qw(wm_root);
 my $root = wm_root(<<ENDWM);
 (S1 ^foo bar ^foo buzz ^baz boo ^link S2 ^link S3)
 (S2 ^faz far 
    ^boo baz
    ^fuzz buzz)
 (S3 ^junk foo)
 ENDWM
 print $root->id; # 'S1'
 my $val = $root->first_val('link');
 print $val->id; # 'S2'
 print $val->first_val('faz'); # 'far'

=head1 DESCRIPTION

This module allows one to traverse working memory by accessing attributes and values of a single element at a time.

=head1 NAME

Soar::WM::Element - Perl extension for representing Soar working memory elements.

=head1 METHODS

=head2 C<new>

Creates a new instance of Soar::WM::Element. There are two required arguments:
1. An instance of L<Soar::WM> which is to contain this element
2. The WME ID of this element.
If the given ID does not exist in the given working memory, this method will croak.

=head2 C<id>

Returns the WME ID of the this element ('S1', 'W3', etc.)

=head2 C<atts>

Returns an array pointer containing the attributes present in this element.

=head2 C<vals>

Takes one required argument, an attribute name, and returns an array pointer containing all of the values of the given attribute
for this element. Any values that are names of other working memory elements will be blessed as new Soar::WM::Elements.

=head2 C<children>

The same as vals, but returns the value of every attribute as an array pointer. The optional parameter 'links_only => 1' will cause
the method to only return children which are links to other Soar::WM::Elements.

=head2 C<first_val>

Takes one required argument, an attribute name, and returns the first value of the given attribute for this element. 
If the values is the names of another working memory element, it will be blessed as a new Soar::WM::Element.

=head2 C<num_links>

Returns the number of values in all of this element's attributes which are names of other existing working memory elements.

=head1 SEE ALSO

The homepage for the Soar cognitive architecture is here: L<http://sitemaker.umich.edu/soar/home>.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nathan Glenn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
