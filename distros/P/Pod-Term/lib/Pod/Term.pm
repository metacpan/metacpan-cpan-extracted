package Pod::Term;

use strict;
use warnings;
use Pod::Simple;
use base 'Pod::Simple';
use Term::ANSIColor 'colored';
use Clone 'clone';
use Carp;
use Hash::Merge;

our $VERSION = 0.02;

sub _default_prop_map{
    return {       
        head1 => {
            display => 'block',
            stacking => 'revert',
            indent => 0,
            after_indent => 2,
            color => 'on_blue',
            bottom_spacing => 2
        },

        head2 => {
            display => 'block',
            stacking => 'revert',
            indent => 0,
            after_indent => 2,
            color => 'blue',
            bottom_spacing => 2
        },

        head3 => {
            display => 'block',
            stacking => 'revert',
            indent => 0,
            after_indent => 2,
            color => 'magenta',
            bottom_spacing => 2
        },

        head4 => {
            display => 'block',
            stacking => 'revert',
            indent => 0,
            after_indent => 2,
            color => 'bright_magenta',
            bottom_spacing => 2
        },

        'over-text' => {
            display => 'block',
            stacking => 'nest',
            indent => 2
        },

        'over-number' => {
            display => 'block',
            stacking => 'nest',
            indent => 2
        },

        'over-bullet' => {
            display => 'block',
            stacking => 'nest',
            indent => 2,
            bottom_spacing => 1
        },

        'item-text' => {
            display => 'block',
            stacking => 'spot',
            color => 'yellow',
            indent => 0,
            after_indent => 2,
            bottom_spacing => 2
        },

        'item-number' => {
            display => 'block',
            stacking => 'nest',
            color => 'yellow',
            prepend => { 
                text => '@number. ',
                color => 'red'
            },
            bottom_spacing => 2
        },

        'item-bullet' => {
            display => 'block',
            stacking => 'nest',
            color => 'yellow',
            prepend => {
                text => '* ',
                color => 'red'
            },
            bottom_spacing => 1
        },

        'B' => {
            display => 'inline',
            color => 'bright_yellow'
        },

        'C' => {
            display => 'inline',
            color => 'cyan'
        },

        'I' => {
            display => 'inline',
            color => 'bright_white'
        },

        'L' => {
            display => 'inline',
            color => 'bright_green'
        },

        'E' => {
            display => 'inline',
            color => 'white'
        },

        'F' => {
            display => 'inline',
            color => 'bright_white'
        },

        'S' => {
            display => 'inline',
            color => 'cyan',
            wrap => 'verbatim'
        },

        'Para' => {
            display => 'block',
            stacking => 'nest',
            color => 'white',
            bottom_spacing => 2,
        },

        'Verbatim' => {
            display => 'block',
            stacking => 'nest',
            color => 'cyan',
            bottom_spacing => 2,
            wrap => 'verbatim'
        },

        'Document' => {
            display => 'block',
            stacking => 'nest',
            indent => 2
        }
    };
}

sub _default_globals {
    return {
        max_cols => 76,
        base_color => 'white'
    };
}



sub globals{
    my ($self,$globals) = @_;

    confess "Expected a hash ref but got $globals" if defined $globals && ref $globals ne ref {};

    if ( $globals ){
        $self->{globals} = $globals;
    }

    $self->{globals} ||= $self->_default_globals;
    return $self->{globals};
}



sub prop_map{
    my ($self,$prop_map) = @_;

    confess "Expected a hash ref but got $prop_map" if defined $prop_map && ref $prop_map ne ref {};

    if ( $prop_map ){
        $self->{prop_map} = $prop_map;
    }

    $self->{prop_map} ||= $self->_default_prop_map;
    return $self->{prop_map};
}


sub set_props{
    my ($self,$props) = @_;

    confess "Need a hash ref of properties to set" unless $props;
    confess "Expected a hash ref but got $props" if ref $props ne ref {};

    my $merger = Hash::Merge->new('LEFT_PRECEDENT');
    my $prop_map = $merger->merge( $props, $self->prop_map );
    $self->prop_map( $prop_map );
}



sub set_prop{
    my ($self,$element_name,$prop_name,$value) = @_;

    confess "set_prop needs: element_name, prop_name, value" unless $element_name && $prop_name && $value;
    $self->prop_map->{$element_name}{$prop_name} = $value;

}


sub _stack{
    my ($self,$stack) = @_;

    confess "Expected an array ref but got $stack" if defined $stack && ref $stack ne ref [];

    if ( $stack ){
        $self->{stack} = $stack;
    }

    $self->{stack} ||= [];
    return $self->{stack};
}   

sub _color{
    my ($self,$color) = @_;

    confess "Expected a string but got $color" if defined $color && ref $color ne ref '';

    if ( $color ){
        $self->{color} = $color
    }
    $self->{color} ||= $self->globals->{base_color};

    return $self->{color};
}   

sub _last_color{
    my ($self,$color) = @_;

    confess "Expected a string but got $color" if defined $color && ref $color ne ref '';

    if ( $color ){
        $self->{last_color} = $color;
    }

    $self->{last_color} ||= $self->_color;
    return $self->{last_color};
}


sub _blocks{
    my ($self,$blocks) = @_;

    confess "Expected an array ref but got $blocks" if defined $blocks && ref $blocks ne ref [];

    if ( $blocks ){
        $self->{blocks} = $blocks;
    }

    $self->{blocks} ||= [];
    return $self->{blocks};
}




sub _stack_start{
    my ($self,$element) = @_;

    my $stacking = $self->_get_prop($element,'stacking');

    if ( $stacking eq 'nest' ){

        push @{$self->_stack}, $element;

    } elsif ( $stacking eq 'spot' ){

        my @stack = @{$self->_stack};
        push @{$self->_stack}, $element unless $stack[$#stack] eq $element;

    } elsif ( $stacking eq 'revert' ){

        my @stack = @{$self->_stack};
        my ($i) = grep{ $self->_stack->[$_] eq $element } 0..$#stack;

        if ( defined $i ){

            my @new_stack = @stack[0..$i];
            $self->_stack( \@new_stack );

        } else {

            push @{$self->_stack}, $element;

        }
    }
}



sub _stack_end{
    my ($self, $element) = @_;

    my $stacking = $self->prop_map->{ $element }->{ stacking };

    if ( $stacking eq 'nest' ){

        pop @{$self->_stack};

    }
}





sub _calc_indent{
    my $self = shift;

    my $indent = 0;

    my @stack = @{$self->_stack};

    for my $i (0..$#stack){
    
        my $prop_set = $self->prop_map->{ $stack[$i] };
        $indent += $prop_set->{ indent } if $prop_set->{ indent };
        $indent += $prop_set->{ after_indent } if $prop_set->{after_indent} && $i != $#stack;

    }

    return $indent;
}




sub _insert{
    my ($self,$ins,$block) = @_;
       
    my $text = $ins->{text};
    $block ||= $self->_blocks->[0];

    if ( $block->{attr} ){

        my @frags = split( /\\\\/, $ins->{text} );
        for my $i (0..$#frags){

            $frags[$i] =~ s/(?<!\\)@(\w+)/${\$block->{attr}{$1}}/g;

        }
        $text = join('\\',@frags);
    }

    my $item = { text => $text };
    my $color = $ins->{color} || $self->_color;
    $item->{color} = $color if $color;
    push @{$block->{items}}, $item;

}



sub _color_start{
    my ($self,$element) = @_;

    my $att_set = $self->prop_map->{$element};

    $self->_last_color( $self->_color );        
    if ( $att_set->{color} ){
        $self->_color( $att_set->{color} );
    }
}


    

sub _color_end{
    my ($self,$element) = @_;

    my $color_cp = $self->_color;
    $self->_color( $self->_last_color );
    $self->_last_color( $color_cp );

}



sub _get_prop{
    my ($self,$element,$prop_name) = @_;

    my $prop;

    my $prop_set = $self->prop_map->{ $element };

    if ( $prop_set ){

        $prop = $prop_set->{$prop_name};

    }
    return $prop;
}




sub _handle_element_start{

    my ($self, $element, $attr) = @_;

    $self->_color_start( $element );

    my $display = $self->_get_prop( $element, 'display' );  

    if ( $display && $display eq 'block' ){

        my $top_spacing = $self->_get_prop( $element, 'top_spacing' ) || 0;
        print "\n" x $top_spacing if $top_spacing;


        my $indent = $self->_calc_indent;

        $self->_stack_start( $element );

        my $block = { items => [], indent => $indent, name => $element };
        $block->{attr} = clone $attr if $attr;
        $block->{wrap} = $self->_get_prop( $element, 'wrap' ) || 'normal';
        $block->{top_spacing} = $self->_get_prop( $element, 'top_spacing' ) || 0;
        $block->{bottom_spacing} = $self->_get_prop( $element, 'bottom_spacing' ) || 0;
        unshift @{$self->_blocks}, $block;

    }

    my $prepend = $self->_get_prop( $element, 'prepend' );
    $self->_insert( $prepend ) if $prepend;

}
    





sub _handle_element_end{
    my ($self, $element, $attr) = @_;;

    $self->_color_end( $element );

    my $append = $self->_get_prop( $element, 'append' );
    $self->_insert( $append ) if $append;

    my $display = $self->_get_prop( $element, 'display' );

    if ( $display && $display eq 'block' ){
        my $block = shift @{$self->_blocks};

        $block->{indent} = $self->_calc_indent;

        if ( $block->{wrap} && $block->{wrap} eq 'verbatim'){
            $self->_print_verbatim( $block );
        } else {
            $self->_print_block( $block );
        }
        print "\n" x $block->{bottom_spacing} if $block->{bottom_spacing};

        $self->_stack_end( $element );
    }
}



sub _handle_text{
    my ($self, $text) = @_;

    my $item = {
        text => $text
    };

    $item->{color} = $self->_color if $self->_color;

    push @{$self->_blocks->[0]->{items}},$item;

}





sub _print_block{
    my ($self,$block) = @_;

    my $items = clone $block->{items};
    my $in_body = 0;

    while (@$items){

        my $line = [];
        my $max_chars = $self->globals->{max_cols} - $block->{indent};
        my $chars_left = $max_chars;

        confess "Attempt to print block with an indent >= the maximum number of columns" if $chars_left < 1;
                
        my $item;

        do {

            $item = shift @$items;

            if ( $item ){

                if ( length( $item->{text} ) <= $chars_left ) {

                    push @$line, $item;
                    $chars_left -= length( $item->{text} );

                } else {

                    my $q_item;
                    ($item,$q_item) = $self->_break_item( $item, $chars_left, $max_chars );

                    if ( $item ){
                        push @$line, $item;
                        $chars_left -= length( $item->{text} );
                    }
                    unshift @$items, $q_item;

                }

            }

        } while ( $item );

        my $margin = ' ' x $block->{indent};
        my $line_str = '';

        foreach my $li ( @$line ){

            if ( $li->{text} !~ /^\s*$/s && $li->{color} ){
                $line_str .= colored( $li->{text}, $li->{color} );
            } else {
                $line_str .= $li->{text};
            }
        }


        $line_str = $margin.$line_str;
        $line_str = "\n".$line_str if $in_body;
        print $line_str;
        
        $in_body = 1;

    }

}



sub _print_verbatim{
    my ($self,$block) = @_;

    my $text = '';

    my $color;
    foreach my $item ( @{$block->{items}} ){

        $color ||= $item->{color};
        $text .= $item->{text};

    }

    return if $text =~ /^\s*$/;

    my $indent = $block->{indent} || 0;
    my $margin = ' ' x $indent;

    my @lines = split( /\n/,$text );
    push @lines,"" if $text =~ /\n$/;

    $text = '';
    for my $i (0..$#lines){

        my $line = $lines[$i];

        if ( $line =~ /^\s*$/ ){
            $line = '';
        } else {
            $line =~ s/^(.*)$/$margin$1/;
        }

        $text .= $line;
        $text .= "\n" unless $i == $#lines;
    }

    $text = colored( $text, $color ) if $color;
    print $text;
    
}





sub _break_item{
    my ($self,$item,$chars_left, $max_chars) = @_;

    my $text = $item->{text};
    my $start_length = length( $text );

    my $clipped;
    
    if ( $chars_left > 1 ){

        $text =~ s/^(.{0,$chars_left})\s+//s;

        $clipped = $1;

    }

    if (! $clipped && $chars_left == $max_chars ){
        $text =~ s/^(.{$chars_left})//s;
        $clipped = $1;
    }

    my $inc_item = undef;
    if ( $clipped ){

        $inc_item = {
            text => $clipped.' ',
            color => $item->{color}
        }
    
    }

    return ($inc_item,{
        text => $text,
        color => $item->{color},

    });

}

1;
__END__

=head1 NAME

Pod::Term - Yet another POD Parser for terminal (ie command line) output

=head1 SYNOPSIS

    use Pod::Term;

    my $pt = Pod::Term->new;

    $pt->globals({
        max_cols => 72,
        base_color => 'yellow'
    });

    Pod::Term->set_props({
        head1 => {
            indent => 2,
            after_indent => 4,
            bottom_spacing => 2,
            color => 'green'
        },
        'item-number' => {
            indent => 2,
            color => 'bright_cyan',
            prepend => {
                text => '@number -',
                color => 'blue'
            }
        }
    });

    $pt->parse_file( '/path/to/pod/file' );


=head1 DESCRIPTION
    
Despite the plethora of Pod parsing modules on CPAN I couldn't seem to coax any into meeting my presentation requirements for pod printed at the terminal. I never anticipated getting diverted onto writing a full-blown POD parser, but that is what ended up happening. My advice to anyone considering writing a POD parser - don't go there. Quantum mechanics is much less troublesome.

This is yet another POD parser. It inherits from L<POD::Simple> and so all L<Pod::Simple> methods I<should> be available (but Pod::Simple seems pretty complex under the hood and possibly in need of some maintenance. I am wondering if the advice to 'use Pod::Simple for all things Pod' is really the best? e.g. I was not able to get the C<output_string> method to work at all).

Like L<Pod::Text::Color>, L<Pod::Term> uses L<Term::ANSIColor> to set ANSI color values to POD elements. However I was not able to get L<Pod::Text::Color> to cleanly wrap colored text. It seems that L<Pod::Text::Color> attempts to wrap the text I<after> putting in the color characters, by trying to ignore those characters - I am not sure if it is the reason. I also couldn't seem to control the spacing, indents etc.

L<Pod::Term> wraps text before inserting color values, and should produce a nice clean wrap. It also offers a decent level of control over formatting, by allowing you to assign simple directives (C<indent>, C<top_spacing> etc.) to individual page elements (C<head1>, C<over> etc.) POD has never looked so good!


=head1 METHODS

Basically L<Pod::Term> formats according to whatever it finds in the C<prop_map> attribute. If you want to know what's in there by default, you can do something like:

    use Data::Dumper;
    use Pod::Term;

    my $pt = Pod::Term->new;
    print "prop_map contains: ".Dumper( $pt->prop_map )."\n";

You should find prop_map is a hashref which looks something like:

    {
        head1 => {
            display => 'block',
            stacking => 'revert',
            indent => 0,
            after_indent => 2,
            color => 'on_blue',
            bottom_spacing => 2
        },

        head2 => {
            display => 'block',
            stacking => 'revert',
            indent => 0,
            after_indent => 2,
            color => 'blue',
            bottom_spacing => 2
        }

        # ...
    
    }

with one entry per POD element type, (using the element names that are generated by C<Pod::Simple>.) So to adjust formatting, you can either directly replace the hashref in C<prop_map>:

    $pt->prop_map({
        
        # new property map hashref 

    });

or use one of the property adjuster methods C<set_prop> and C<set_props>. As the names suggest, the former sets just one property in the map, while the second can set many:

    $pt->set_prop( 'head1', 'indent', 2);

    $pt->set_props({
        head2 => {
            bottom_spacing => 2,
            color => 'bright_magenta'
        },
        Para => {
            top_spacing => 5,
            color => 'white'
        }
    });

Once you have specified your format options, you are ready to parse.

A quick method summary:

=over

=item prop_map

get/set the map of element properties (ie the hash of formatting options). This will use a set of default values if not explicitly set.

    my $current_prop_map = $pt->prop_map;       # get

    $pt->prop_map( $new_prop_map );             # set


=item set_prop

Set the value of an individual property in the map

    $pt->set_prop($element_name, $prop_name, $new_value );

    $pt->set_prop('head2', 'bottom_spacing', 3);


=item set_props

Set the values of several properties in the properties map at the same time. L<Pod::Text> uses L<Hash::Merge> to insert the new values.

    $pt->set_props({
        Document => {
            indent => 2,
            bottom_spacing => 2
        },            
        head1 => {
            indent => 4,
            color => 'red'
        }
    });

=item globals

globals is a hashref containing formatting which affects the whole document. Again it is a good idea to dump this to see the defaults and what is available for modification:

    use Data::Dumper;
    use Pod::Term;

    my $pt = Pod::Term->new;
    print "globals: ".Dumper( $pt->globals )."\n";

At the time of writing, it contains just 2 variables:

    {
        max_cols => 76,
        base_color => white
    }

but should I update the module but forget to update this documentation, then L<Data::Dumper> is your friend. 

Hopefully the 2 above global attributes are reasonably straightforward:

=over

=item max_cols

C<max_cols> is basically the number of columns to wrap to (except for 'Verbatim' sections - which are printed... verbatim, which means they can stray outside the wrapping margin if the POD author was being inconsiderate)

=item base_color

C<base_color> is the color to start out with and revert back to if no color is specified. However, it's best to set colors explicitly where possible to avoid surprises.

=back

=back

=head1 PROPERTY MAP VALUES

I've called these "properties" rather than "attributes" because L<Pod::Simple> uses "attributes" to mean something else. And "property map" is really a hashref which delegates properties to elements.

Some values I recommend you play with - and some I don't. Here are the ones that are fun to adjust:

=head2 properties which apply to "block" elements only

(see the L<display> property for what is meant by a C<block> element.)

=over

=item indent

The number of spaces to add to the indent when the element is parsed. Note indents are cumulative (in general - see C<stacking>). This indent happens I<before> the element gets printed.

=item after_indent

The number of spaces to add to the indent immediately I<after> the element is parsed. e.g. specifying  C<after_indent = 2> on a C<head1> element means a paragraph occurring immediately after your C<head1> title will be indented 2 spaces relative to the C<head1>.

=item top_spacing

How many lines to print immediately I<above> the element

=item bottom_spacing

How many lines to print immediately I<below> the element. Note that in many cases specifying 0 for this is not a good idea. You should probably make sure that either C<top_spacing> or C<bottom_spacing> are at least 1 for the elements which have text bodies, otherwise no linespace character will be printed between text blocks (and I'm afraid L<Pod::Term> does not neatly run paragraphs together in this situation).

=item color

The color to set to the element. L<Pod::Term> uses L<Term::ANSIColor> for colors. See the man page for L<Term::ANSIColor> for a list of available colors.

=back

=head2 properties applying to both C<inline> and C<block> elements

=over

=item prepend

prepend is really intended for list items. For example, you may want your bullets to start with a blue dash (-) etc. To do this, set your attribute thus:

    $pt->set_prop('item-bullet','prepend', {
        
        text => '*',
        color => '-'

    });

Note that the C<prepend> attribute should be a hashref containing C<text> at a minimum, and possibly C<color>. In theory you can use C<prepend> with any element - but in the case of 'over' elements in particular it will lead to unexpected effects. This is because parents of nested elements are rendered I<after> the child - so you would get your prepended text occurring at the end of your list, which is probably not what you want.

Both C<prepend> and C<append> should not contain newline characters. Blocks are defined to be lumps of text without return characters, so trying to C<prepend> or C<append> then will cause confusion. To add newline characters to the beginning and end of blocks, use C<top_spacing> and C<bottom_spacing>

=item append

Like C<prepend>, but occurs at the end of the element. See the documentation for C<prepend>.

=back

And now for the properties that you might want to leave alone. However it's important to understand what they do

=over

=item display

This is a CSS style property, which can take 2 values with names borrowed from CSS, C<inline> and C<block>. If you are familiar with both CSS and POD then it should be quite easy to work out which POD elements should be defined as C<inline> and which as C<block>. Formatting codes such as C<B> - which indicates bold text - obviously counts as an C<inline> element, while C<head1>, C<Para> etc are C<block> elements. The crucial difference being that C<block> elements expect to have line spacing between them, whereas inline follows the text. Things like top and bottom spacing only really make sense for block style elements, so setting a C<bottom_spacing> value on a C<B> element will not have any effect

=item stacking

stacking controls how the left indent is calculated on C<block> elements. Possible values are C<revert>, C<nest> and C<spot>. POD suffers from an identity crisis, since for the most part it presents as a series of elements which don't nest, but then incorporates the C<over> element which works as an envelope and can be nested to arbitrary depth, C<html> style.

There are the C<head1>, C<head2>... elements - which are expected to occur as a single set, and not within other sections. For these, it's probably best if each C<head1> has the same indent, and each C<head2> has the same indent within the same C<head1>. So these get C<stacking=revert>, meaning the indent level will fall back to what it was last time the same element was encountered. 

C<over> and C<item> elements typically get C<stacking=nest> meaning a newly encountered C<over> gets an increased indent (as long as the C<indent> property is set for the relevant C<over> element.)

C<spot> is more complex, and should be used with caution. It is an uncomfortable combination of C<revert> and C<nest>, reverting only if the last stacked element is the same as itself. Otherwise it will nest. The idea with C<spot> is to keep list items that may contain nested paragraphs in line with each other, rather than the next item after the paragraph indenting further. 

Stacking may be confusing, and it may be best to make sure you can't get what you want by altering other settings before getting too experimental with it.

=back

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::Text>, L<Pod::Text::Color>, L<Term::ANSIColor>

=head1 AUTHOR

Tom Gracey tomgracey@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Tom Gracey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


