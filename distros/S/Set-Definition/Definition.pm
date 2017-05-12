#!/usr/bin/perl -w
package Set::Definition;

use strict;
use Class::Core qw/:all/;
use Data::Dumper;

use vars qw( $VERSION );
$VERSION = "0.01";

=head1 NAME

Set::Definition - Class to handle simple logical set unions and intersections.

=head1 VERSION

0.01

=cut

sub construct {
    my ( $core, $def ) = @_;
    my $text  = $def->{'text'};
    my $parts = expr_to_parts( $text );
    my $arr   = parse_arr( $parts );
    my $obj = $arr->[0];
    my $parsed;
    if( ref( $obj ) eq 'HASH' ) {
      $def->{'ob'} = $obj;
      $parsed = $obj->{'parsed'};
    }
    else {
      $parsed = [ $obj ];
      $def->{'ob'} = { parsed => $parsed, join => '|' };
    }
    $def->{'groups'} = uniq_parts( {}, $parsed );
}

# Return the groups mentioned in the expression
sub expr_groups {
    my ( $core, $def ) = @_;
    return $def->{'groups'};
}

sub contains {
    my ( $core, $def, $mem ) = @_;
    my $member     = $mem || $core->get('member');
    my $obj        = $def->{'ob'};
    my $check_list = $def->{'groups'};
    my $membership = $def->check_membership( hash => $check_list, user => $member );
    #print Dumper( $membership );
    return eval_hash( $membership, $obj );
}

sub members {
    my ( $core, $def ) = @_;
    
    my $obj        = $def->{'ob'};
    my $check_list = $def->{'groups'};
    
    # get the membership of the groups that we depend on
    my $membership = $def->get_membership( hash => $check_list );
    #print "Membership\n";
    #print Dumper( $membership );
    #print "Call to members\n";
    return eval_hash_members( $membership, $obj );
}

sub expr_to_parts {
    my $expr = shift;
    $expr =~ s/ //g;
    if( $expr !~ m/^\(/ || $expr !~ m/\)$/ ) { $expr = "($expr)"; }
    my @parts = split(/([&|()])/, $expr );
    my @ref;
    for my $part ( @parts ) {
        next if( !$part );
        push( @ref, $part );
    }
    return \@ref;
}

sub eval_hash {
    my ( $user_membership, $hash ) = @_;
    my $parsed = $hash->{'parsed'};
    my $join   = $hash->{'join'};
    #print Dumper( { parsed => $parsed, join => $join } );
    for my $item ( @$parsed ) {
        my $cur = ( ref( $item ) eq 'HASH' ) ? eval_hash( $user_membership, $item ) : $user_membership->{ $item };
        $cur = 0 if( ! defined $cur );
        return 0 if( $join eq '&' && !$cur );
        return 1 if( $join eq '|' && $cur );
    }
    return 1 if( $join eq '&' );
    return 0;
}

sub eval_hash_members {
    my ( $membership, $hash ) = @_;
    my $parsed = $hash->{'parsed'};
    my $join   = $hash->{'join'};
    
    my $a = $parsed->[0];
    my $b = $parsed->[1];
    #print Dumper( $a );
    #print Dumper( $b );
    my $alist = ( ref( $a ) eq 'HASH' ) ? eval_hash_members( $membership, $a ) : $membership->{ $a };
    
    if( !defined $b ) {
      return $alist;
    }
    my $blist = ( ref( $b ) eq 'HASH' ) ? eval_hash_members( $membership, $b ) : $membership->{ $b };
    if( $join eq '&' ) {
        #print Dumper( $alist );
        #print Dumper( $blist );
        return intersect_groups( $alist, $blist );
    }
    if( $join eq '|' ) {
        #print Dumper( $alist );
        #print Dumper( $blist );
        return join_groups( $alist, $blist );
    }
}

sub array_to_hash {
    my $arr = shift;
    #my %hash = map { ($a, 1) } @$arr;
    my %hash;
    for my $key ( @$arr ) {
        $hash{ $key } = 1;
    }
    return \%hash;
}

sub intersect_groups {
    my ( $a, $b ) = @_;
    my $bhash = array_to_hash( $b );
    my @res;
    for my $key ( @$a ) {
        push( @res, $key ) if( $bhash->{ $key } );
    }
    return \@res;
}

sub join_groups {
    my ( $a, $b ) = @_;
    my %res;
    for my $key ( @$a ) { $res{ $key } = 1; }
    for my $key ( @$b ) { $res{ $key } = 1; }
    my @arr = keys %res;
    return \@arr;
}

sub check_membership {
    my ( $core, $def ) = @_;
    my $hash = $core->get('hash');
    my $user = $core->get('user');
    
    my $res = {};
    for my $key ( keys %$hash ) {
        my $ingroup_ref = $def->{'ingroup_callback'};
        my $temp = $res->{ $key } = &$ingroup_ref( $key, $user, $def );
        $res->{ "!$key" } = $temp ? 0 : 1;
    }
    return $res;
}

sub get_membership {
    my ( $core, $def ) = @_;
    my $hash = $core->get('hash');
    
    my $res = {};
    for my $key ( keys %$hash ) {
        my $ingroup_ref = $def->{'ingroup_callback'};
        my $members = &$ingroup_ref( $key, undef, $def );
        $res->{ $key } = $members;
    }
    return $res;
}

# Find the parts mentioned in @$arr, and put them in the hash %$res
sub uniq_parts {
    my ( $res, $arr ) = @_;
    for my $item ( @$arr ) {
        if( ref( $item ) eq 'HASH' ) {
            uniq_parts( $res, $item->{'parsed'} );
        }
        else {
            my $temp = $item; 
            $temp =~ s/^!//;
            $res->{ $temp } = 1;
        }
    }
    return $res;
}

sub parse_arr {
    my $in = shift;
    my $sub = 0;
    my $depth = 0;
    my $out = [];
    for my $part ( @$in ) {
        next if( !$part );
        my $ref = ref( $part );
         
        if( $ref ne 'HASH' ) { # is a name or a connector
            if( $part eq '(' ) {
                if( !$depth ) {
                    $sub = { parts => [] };
                    $depth++;
                    next;
                }
                
                $depth++;
            }
            elsif( $part eq ')' ) {
                $depth--;
                if( !$depth ) {
                    my $parsed = parse_arr( $sub->{'parts'} );
                    push( @$out, treat_arr( $parsed ) );
                    $sub = 0;
                    next;
                }
            }
        }
        
        if( $sub ) {
            if( $depth == 1 ) {
                if( $part eq '&' || $part eq '|' ) {
                    $sub->{'join'} = $part;
                }
            }
            push( @{$sub->{'parts'}}, $part );
        }
        else {
            push( @$out, $part );
        }
    }
    
    return $out;
}

sub treat_arr {
    my ( $arr, $lev ) = @_;
    my $len = $#$arr;
    return $arr->[0] if( $len == 0 );
    my @res;
    my $join = $lev ? '|' : '&';
    for( my $i = 0; $i <= $len; $i++ ) {
        my $part = $arr->[ $i ];
        if( $i % 2 && $part eq $join ) {
            push( @res, { parsed => [ pop( @res ), $arr->[ ++$i ] ], join => $join } );
            next;
        }
        push( @res, $part );
    }
    return $lev ? $res[0] : treat_arr( \@res, 1 );
}

1;

__END__

=head1 SYNOPSIS

  use Set::Definition;
  
  my $hash = { a => [ 1, 2, 3 ], b => [ 2, 3, 5 ] };
  my $set = Set::Definition->new( text => "a & b", ingroup_callback => \&in_group, hash => $hash );
  
  my $members = $set->members(); # will be [ 2, 3 ]
  my $has2 = $set->contains( 2 ); # will be true
  my $has5 = $set->contains( 5 ); # will be false
  
  sub in_group {
    my ( $group_name, $item, $options ) = @_;
    my $hash = $options->{'hash'};
    my $gp = $hash->{ $group_name };
    if( !$item ) {
        return $gp if( defined $gp );
        return [];
    }
    for my $member ( @$gp ) {
        return 1 if( $member eq $item );
    }
  }

=head1 DESCRIPTION

Set::Definition allows you to define a logical set that contains members by way your own custom function
that checks if an item is a member of a named set, and/or gives the list of all items in a named set.

A boolean expression is accepted when creating the set, which defines how the named sets should be joined
together logically.

Any additional parameters passed during construction will be passed to your callback function in the
'options' hash. Eg:

  my $set = Set::Definition->new( text => 'a & b', ingroup_callback => \&your_func, [parameters to go in options] );
  
  sub your_func {
    my ( $group_name, $item, $options ) = @_;
    # options is now a hash containing your parameters
  }

=head2 Accepted Boolean Expressions

The expression accepted can contains parantheses, as well as the '!' character to respresent set exclusion.
All of the following are valid expressions:

=over 2

=item * apples | oranges

=item * fruits & red

=item * fruits & red & !apples

=item * ( flying | birds ) & !airplanes

=item * ( a & b & ( c | d ) ) | ( f & !e )

=back

=head2 Using contains() with members()

Note that some expressions may work for the 'contains', but it may not make sense to call the members() function.
Example:

=over 2

=item * !a
( unless you have decided a domain, how do you know everything not in a )

=back

=head1 LICENSE

  Copyright (C) 2013 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut