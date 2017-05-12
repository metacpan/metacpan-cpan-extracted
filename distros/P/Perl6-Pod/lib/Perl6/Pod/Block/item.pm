#===============================================================================
#
#  DESCRIPTION: ordered and unordered lists
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Block::item;

=pod

=head1 NAME

Perl6::Pod::Block::item - lists

=head1 SYNOPSIS

     =item  Happy
     =item  Dopey
     =item  Sleepy

     =item1  Animal
     =item2     Vertebrate
     =item2     Invertebrate

=head1 DESCRIPTION

Lists in Pod are specified as a series of contiguous C<=item> blocks. No
special "container" directives or other delimiters are required to
enclose the entire list. For example:

     The seven suspects are:

     =item  Happy
     =item  Dopey
     =item  Sleepy
     =item  Bashful
     =item  Sneezy
     =item  Grumpy
     =item  Keyser Soze

List items have one implicit level of nesting:

Lists may be multi-level, with items at each level specified using the
C<=item1>, C<=item2>, C<=item3>, etc. blocks. Note that C<=item> is just
an abbreviation for C<=item1>. For example:

     =item1  Animal
     =item2     Vertebrate
     =item2     Invertebrate

     =item1  Phase
     =item2     Solid
     =item2     Liquid
     =item2     Gas
     =item2     Chocolate

Note that item blocks within the same list are not physically nested.
That is, lower-level items should I<not> be specified inside
higher-level items:

    =comment WRONG...
    =begin item1          --------------
    The choices are:                    |
    =item2 Liberty        ==< Level 2   |==<  Level 1
    =item2 Death          ==< Level 2   |
    =item2 Beer           ==< Level 2   |
    =end item1            --------------

    =comment CORRECT...
    =begin item1          ---------------
    The choices are:                     |==< Level 1
    =end item1            ---------------
    =item2 Liberty        ==================< Level 2
    =item2 Death          ==================< Level 2
    =item2 Beer           ==================< Level 2

=head2 Ordered lists

An item is part of an ordered list if the item has a C<:numbered>
configuration option:

     =for item1 :numbered
     Visito
    
     =for item2 :numbered
     Veni
   
     =for item2 :numbered
     Vidi
  
     =for item2 :numbered
     Vici

Alternatively, if the first word of the item consists of a single C<#>
character, the item is treated as having a C<:numbered> option:

     =item1  # Visito
     =item2     # Veni
     =item2     # Vidi
     =item2     # Vici


To specify an I<unnumbered> list item that starts with a literal C<#>, either
make the octothorpe verbatim:


    =item V<#> introduces a comment

or explicitly mark the item itself as being unnumbered:

    =for item :!numbered
    # introduces a comment

=head2 Unordered lists

List items that are not C<:numbered> are treated as defining unordered
lists. Typically, such lists are rendered with bullets. For example:

    =item1 Reading
    =item2 Writing
    =item3 'Rithmetic

=head2 Multi-paragraph list items

Use the delimited form of the C<=item> block to specify items that
contain multiple paragraphs. For example:

     Let's consider two common proverbs:
  
     =begin item :numbered
     I<The rain in Spain falls mainly on the plain.>
  
     This is a common myth and an unconscionable slur on the Spanish
     people, the majority of whom are extremely attractive.
     =end item
  
     =begin item :numbered
     I<The early bird gets the worm.>
 
     In deciding whether to become an early riser, it is worth
     considering whether you would actually enjoy annelids
     for breakfast.
     =end item

     As you can see, folk wisdom is often of dubious value.

=head2 Definition lists

    =defn  MAD
    Affected with a high degree of intellectual independence.

    =defn  MEEKNESS
    Uncommon patience in planning a revenge that is worth while.

    =defn
    MORAL
    Conforming to a local and mutable standard of right.
    Having the quality of general expediency.

=head1 METHODS

=cut

use strict;
use warnings;
use Data::Dumper;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
use Perl6::Pod::Utl;
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    #check if item numbered
    #    my $content = $self->{content}->[0];
    if ( $self->{content}->[0] =~ s/^(\s*\#\s*)// ) {

        #set numbered attr
        #TODO $self->set_attr;
        push @{ $self->{attr} },
          {
            ''      => ':numbered',
            'name'  => 'numbered',
            'type'  => 'bool',
            'items' => 1
          };
    }

    # for definition get TERM
    #The first non-blank line of content is treated as a term being defined,
    #and the remaining content is treated as the definition for the term
    if ( $self->item_type eq 'definition' ) {
        my $first_para = $self->{'content'}->[0];
        if ( $first_para =~ s/^\s*(.*)[\r\n]// ) {
            $self->{term} = $1;
        }
        $self->{'content'}->[0] = $first_para;
    }
    return $self;
}

sub item_type {
    my $self = shift;

    #determine item type
    my $pod_attr = $self->get_attr;

    #for defn block name
    return 'definition'
      if $self->name eq 'defn';

    my $type = 'unordered';
    if ( $self->is_numbered ) {
        $type = 'ordered';
    }
    $type;
}

sub is_numbered {
    my $self     = shift;
    my $pod_attr = $self->get_attr;
    return $pod_attr->{numbered} || 0;
}

sub item_level {
    my $self = shift;
    $self->{level} || 1;    #default 1 level for items
}

=head2 to_xhtml

=over 1

=item Unordered lists

  =item Milk
  =item Toilet Paper
  =item Cereal
  =item Bread

  # <ul> - unordered list; bullets
  <ul>
   <li>Milk</li>
   <li>Toilet Paper</li>
   <li>Cereal</li>
   <li>Bread</li>
  </ul>

=item Ordered
    
    =for item :numbered
    Find a Job
    =item # Get Money
    =item # Move Out

  # <ol> - ordered list; numbers (<ol start="4" > for :continued)
    <ol>
     <li>Find a Job</li>
     <li>Get Money</li>
     <li>Move Out</li>
    </ol>

=item  definition list; dictionary

     =defn Fromage
     French word for cheese.
     =defn Voiture
     French word for car.

    * <dl> - defines the start of the list
    * <dt> - definition term
    * <dd> - defining definition

    <dl>
     <dt><strong>Fromage</strong></dt>
     <dd>French word for cheese.</dd>
     <dt><strong>Voiture</strong></dt>
     <dd>French word for car.</dd>
    </dt>

L<http://www.tizag.com/htmlT/lists.php>

=back
   
=cut

sub get_item_sign {
    my $self = shift;
    my $el = shift;
    my $name = $el->name;
    return $name unless $name eq 'item';
    my $sign = join '_'=> $name, $el->item_level, $self->item_type;
    return $sign
}

sub to_xhtml {
    my ( $self, $to, $prev, $next ) = @_;
    my $w = $to->w;


    my ( $list_name, $items_name ) = @{
        {
            ordered    => [ 'ol', 'li' ],
            unordered  => [ 'ul', 'li' ],
            definition => [ 'dl', 'dd' ]
        }->{ $self->item_type }
      };
    if (!$prev || $self->get_item_sign($prev) ne $self->get_item_sign($self) ) {
        #nesting first (only 2> )
        unless (exists $self->get_attr->{nested}) {
            my $tonest = $self->item_level - 1 ;
            $w->start_nesting(  $tonest  ) if $tonest;
        }

        $w->raw("<$list_name>");
    }
    if ( $self->item_type eq 'definition' ) {
        $w->raw('<dt><strong>');
        $to->visit( Perl6::Pod::Utl::parse_para( $self->{term} ) );
        $w->raw('</strong></dt>')

    }

    #parse first para
    $self->{content}->[0] =
      Perl6::Pod::Utl::parse_para( $self->{content}->[0] );
    $w->raw("<$items_name>");
    $to->visit_childs($self);
    $w->raw("</$items_name>");
    if (!$next || $self->get_item_sign($next) ne $self->get_item_sign($self) ) {
        $w->raw("</$list_name>");
        unless (exists $self->get_attr->{nested}) {
            my $tonest = $self->item_level - 1  ;
            $w->stop_nesting(  $tonest  ) if $tonest;
        }

    }


}

sub to_docbook {

    #setup first number for ordered lists
    # 'continuation' docbook attribute
    # http://www.docbook.org/tdg/en/html/orderedlist.html
    #        if ( exists $attr->{number_value} ) {
    #            unless ( exists $rattr->{number_start} ) {
    #                $rattr->{number_start} = $attr->{number_value};
    #            }
    #        }
    my ( $self, $to, $prev, $next ) = @_;
    my $w = $to->w;

    my ( $list_name, $items_name ) = @{
        {
            ordered    => [ 'orderedlist',  'listitem' ],
            unordered  => [ 'itemizedlist', 'listitem' ],
            definition => [ 'variablelist', 'listitem' ]
        }->{ $self->item_type }
      };
    if (!$prev || $self->get_item_sign($prev) ne $self->get_item_sign($self) ) {
        #nesting first (only 2> )
        unless (exists $self->get_attr->{nested}) {
            my $tonest = $self->item_level - 1 ;
            $w->start_nesting(  $tonest  ) if $tonest;
        }

        $w->raw("<$list_name>");
    }

            

    if ( $self->item_type eq 'definition' ) {
        $w->raw('<varlistentry>');
        $to->visit( Perl6::Pod::Utl::parse_para( $self->{term} ) );
        $w->raw('</varlistentry>')

    }

    #parse first para
    $self->{content}->[0] =
      Perl6::Pod::Utl::parse_para( $self->{content}->[0] );
    if ( ( $self->item_type eq 'unordered'  )
                    && 
            ( $self->item_level > 1 )
    ) {
    #marker
    #get list from http://www.sagehill.net/docbookxsl/Itemizedlists.html
    my @markers = qw/bullet opencircle box /;
    my $marker  = $markers[ ($self->item_level - 1) % 3  ];
    $w->raw("<$items_name mark='$marker'>");
    } else {
     $w->raw("<$items_name>");
    }
    $to->visit_childs($self);
    $w->raw("</$items_name>");

    if (!$next || $self->get_item_sign($next) ne $self->get_item_sign($self) ) {
        $w->raw("</$list_name>");
        unless (exists $self->get_attr->{nested}) {
            my $tonest = $self->item_level - 1  ;
            $w->stop_nesting(  $tonest  ) if $tonest;
        }

    }

}

sub to_latex {
    my ( $self, $to, $prev, $next ) = @_;
    my $w = $to->w;

    my ( $list_name, $items_name ) = @{
        {
            ordered    => [ 'enumerate',  'item' ],
            unordered  => [ 'itemize', 'item' ],
            definition => [ 'description', 'item' ]
        }->{ $self->item_type }
      };
    if (!$prev || $self->get_item_sign($prev) ne $self->get_item_sign($self) ) {
        #nesting first (only 2> )
        unless (exists $self->get_attr->{nested}) {
            my $tonest = $self->item_level - 1 ;
            $w->start_nesting(  $tonest  ) if $tonest;
        }

    $w->say('\begin{' . $list_name . '}');
    }

    $w->raw('\item');

    if ( $self->item_type eq 'definition' ) {
        $w->raw('[');
        $self->visit( Perl6::Pod::Utl::parse_para( $self->{term} ) );
        $w->raw(']')

    }
    $w->raw(' ');#space

    #parse first para
    $self->{content}->[0] =
      Perl6::Pod::Utl::parse_para( $self->{content}->[0] );
    $to->visit_childs($self);
    if ( $self->get_attr->{pause} ) {
        $w->say('\pause');
    }

    if (!$next || $self->get_item_sign($next) ne $self->get_item_sign($self) ) {
        $w->say('\end{' . $list_name . '}');
        unless (exists $self->get_attr->{nested}) {
            my $tonest = $self->item_level - 1  ;
            $w->stop_nesting(  $tonest  ) if $tonest;
        }

   }
}

1;
__END__


=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

