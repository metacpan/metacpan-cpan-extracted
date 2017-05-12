package POOF::Encoder;

use 5.007;
use strict;
use base qw(POOF);
use Tie::IxHash;
use Class::ISA;
use Carp qw(confess);

our $VERSION = '1.0';

sub _init : Method Protected
{
    my $obj = shift;
    my %args = @_;
    
    my @dkeys = grep { defined $args{$_} } $obj->pGroup('Init');
    @$obj{ @dkeys } = @args{ @dkeys }; 
}

sub Object : Property Protected
{
    {
        'type' => 'POOF',
        'groups' => [qw(Init)],
    }
}

sub SeenProps : Property Public
{
    {
        'type' => 'hash',
        'default' => {},
    }
}

sub SeenGroups : Property Public
{
    {
        'type' => 'hash',
        'default' => {},
    }
}

sub CreateEncodedKeysForGroups : Method Public
{
    my ($obj,@groups) = @_;
    
    # reset the seen
    $obj->{'SeenProps'} = {};
    $obj->{'SeenGroups'} = {};
    
    my $p = 0;
    
    return
    (
        grep
        {
            ++$p % 2
        }
        $obj->CreateEncodingMap
        (
            $obj->{'Object'},
            [@groups]
        )
    );
}


sub CreateEncodedKeysAndTypesForGroups : Method Public
{
    my ($obj,@groups) = @_;
    
    # reset the seen
    $obj->{'SeenProps'} = {};
    $obj->{'SeenGroups'} = {};
    
    tie (my %fullmap, 'Tie::IxHash');
    
    %fullmap = $obj->CreateEncodingMap
    (
        $obj->{'Object'},
        [@groups]
    );
    
    my @tuples;
    
    map
    {
        push
        (
            @tuples,
            {
                'key' => $_,
                'obj' => $fullmap{$_}
            }
        )
    } keys %fullmap;

    return @tuples;
}

sub CreateEncodingMap : Method Protected
{
    my ($obj,$ref,$groups,$parent) = @_;
    tie (my %map, 'Tie::IxHash');
    
    # preventing warnings
    $parent ||= '';
    
    my @contained;
    
    foreach my $group (@{$groups})
    {
        
        # let's make sure we only process once
        next if $obj->{'SeenGroups'}->{ $parent ? "$parent-$group" : $group }++;
            
        my @props = eval { ($ref->pGroup($group)) };
        if($@)
        {
            warn "Error in Encoder: parent $parent\n$@\n";
            warn "ref: ",Dumper($ref),"\n";
        }
        
        foreach my $prop (@props)
        {
            # let's make sure we only process once if they are in multiple groups
            next if $obj->{'SeenProps'}->{ $parent ? "$parent-$prop" : $prop }++;
            
            if ($obj->_Relationship(ref($ref->{$prop}),'POOF::Collection') =~ /^(?:self|child)$/o)
            {
                # deal with the collection
                for(my $i=0; $i<= $#{$ref->{$prop}}; $i++)
                {
                    push
                    (
                        @contained,
                        [
                            $ref->{$prop}->[$i],   # new ref
                            $groups,               # groups to look at
                            "$parent-$prop-$i",    # new parent
                        ]
                    )
                }

                # let's instantiate one to have a place holder for new ones on the form
                push
                (
                    @contained,
                    [
                        $ref->{$prop}->[0]->pReInstantiateSelf
                        (
                            RaiseException=>$POOF::RAISE_EXCEPTION
                        ),                    # new ref
                        $groups,              # groups to look at
                        "$parent-$prop-|",    # new parent
                    ]
                );
                    
            }
            elsif($obj->IsPOOFObj($ref->{$prop},$prop) || ref($ref->{$prop}) eq 'HASH')
            {
                # deal with the nested object
                push
                (
                    @contained,
                    [
                        $ref->{$prop},      # new ref
                        $groups,            # groups to look at
                        (
                            $parent
                                ? "$parent-$prop"
                                : $prop
                        ),                  # new parent
                    ]
                );
            }
            elsif(not ref($ref->{$prop}))
            {
                # simple prop
                my $key = $parent ? "$parent-$prop" : $prop;
                
                $map{ $key } =
                {
                    'object'    => $ref,
                    'name'      => $prop,
                    'value'     => $ref->{$prop},
                    'class'     => ref($ref),
                    'type'      => $ref->pPropertyDefinition($prop)->{'type'},
                    'poof'      => $obj->IsPOOFObj($ref,$prop),
                    'error'     => $ref->pGetErrors->{$prop}
                };
            }
            else
            {
                warn "Error: $prop is not a simple property and I don't know what do to with it\n";
            }
        }
        
        # now let's recurse
        foreach my $args (@contained)
        {
            %map =
            (
                %map,
                $obj->CreateEncodingMap(@{$args})
            );
        }
    }
    return %map;
}


sub _Relationship
{
    my $obj = shift;
    my ($class1,$class2) = map { $_ ? ref $_ ? ref $_ : $_ : '' } @_;

    return 'self' if $class1 eq $class2;

    my %family1 = map { $_ => 1 } Class::ISA::super_path( $class1 );
    my %family2 = map { $_ => 1 } Class::ISA::super_path( $class2 );

    return
        exists $family1{ $class2 }
            ? 'child'
            : exists $family2{ $class1 } 
                ? 'parent' 
                : 'unrelated';
}

sub IsPOOFObj
{
    my ($obj,$ref,$prop) = @_;
    return
        $obj->_Relationship($ref, 'POOF') =~ /^(?:self|child)$/
            ? 1
            : 0;
}


1;
__END__

=head1 NAME

POOF::Encoder - Utility class used by POOF.

=head1 SYNOPSIS

It is not meant to be used directly.
  
=head1 SEE ALSO

POOF man page.

=head1 AUTHOR

Benny Millares <bmillares@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Benny Millares

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
