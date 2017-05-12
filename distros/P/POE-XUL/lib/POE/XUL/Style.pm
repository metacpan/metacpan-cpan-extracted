package POE::XUL::Style;
# $Id$
# Copyright Philip Gwyn 2008-2010.  All rights reserved.

use strict;
use warnings;

use Scalar::Util qw( refaddr );

use Carp;

use overload '""' => sub { $_[0]->as_string }, 
             '+'  => sub { refaddr $_[0] },
             'bool' => sub { 1 },
             fallback => 1;

use constant DEBUG => 0;

our $VERSION = '0.0601';

my %EQUIV = qw(
    border-top border
    border-left border
    border-bottom border
    border-right border
    overflow-x overflow
    overflow-y overflow
    -moz-outline outline
);

my %SUBSET = (          # property ... offsets 
    'margin-top'    => [ 'margin', 0, 0, 0, 0 ],
    'margin-right'  => [ 'margin', 0, 1, 1, 1 ],
    'margin-bottom' => [ 'margin', 0, 0, 2, 2 ],
    'margin-left'   => [ 'margin', 0, 1, 1, 3 ],
    'padding-top'    => [ 'padding', 0, 0, 0, 0 ],
    'padding-right'  => [ 'padding', 0, 1, 1, 1 ],
    'padding-bottom' => [ 'padding', 0, 0, 2, 2 ],
    'padding-left'   => [ 'padding', 0, 1, 1, 3 ],
    'border-width' => [ 'border', 0, 0, 0 ],
    'border-style' => [ 'border', 1, 1, 1 ],
    'border-color' => [ 'border', 2, 2, 2 ],
    'border-top-width' => [ 'border-top', 0, 0, 0 ],
    'border-top-style' => [ 'border-top', 1, 1, 1 ],
    'border-top-color' => [ 'border-top', 2, 2, 2 ],
    'border-right-width' => [ 'border-right', 0, 0, 0 ],
    'border-right-style' => [ 'border-right', 1, 1, 1 ],
    'border-right-color' => [ 'border-right', 2, 2, 2 ],
    'border-bottom-width' => [ 'border-bottom', 0, 0, 0 ],
    'border-bottom-style' => [ 'border-bottom', 1, 1, 1 ],
    'border-bottom-color' => [ 'border-bottom', 2, 2, 2 ],
    'border-left-width' => [ 'border-left', 0, 0, 0 ],
    'border-left-style' => [ 'border-left', 1, 1, 1 ],
    'border-left-color' => [ 'border-left', 2, 2, 2 ],
    'outline-width' => [ 'outline', 0, 0, 0 ],
    'outline-style' => [ 'outline', 1, 1, 1 ],
    'outline-color' => [ 'outline', 2, 2, 2 ],
    '-moz-outline-width' => [ '-moz-outline', 0, 0, 0 ],
    '-moz-outline-style' => [ '-moz-outline', 1, 1, 1 ],
    '-moz-outline-color' => [ '-moz-outline', 2, 2, 2 ],
    'list-style-type'     => [ 'list-style', 0, 0, 0 ],
    'list-style-position' => [ 'list-style', 1, 1, 1 ],
    'list-style-image'    => [ 'list-style', 2, 2, 2 ],
    # http://developer.mozilla.org/en/docs/CSS:-moz-border-radius says:
    # "If fewer than 4 values are given, the list of values is repeated
    # to fill the remaining values."
    # I take this to mean:
    # 1       -> tl=1 tr=1 br=1 bl=1
    # 1 2     -> tl=1 tr=2 br=1 bl=2
    # 1 2 3   -> tl=1 tr=2 br=3 bl=1
    '-moz-border-radius-topleft'     => [ '-moz-border-radius', 0, 0, 0, 0 ],
    '-moz-border-radius-topright'    => [ '-moz-border-radius', 0, 1, 1, 1 ],
    '-moz-border-radius-bottomright' => [ '-moz-border-radius', 0, 0, 2, 2 ],
    '-moz-border-radius-bottomleft'  => [ '-moz-border-radius', 0, 1, 0, 3 ],
);

##############################################################
sub new
{
    my( $package, $init ) = @_;
    my $self = bless { properties => {}, text => [] }, $package;
    $self->parse( $init ) if $init;
    return $self;
}

##############################################################
sub as_string
{
    my( $self ) = @_;
    return join '', @{ $self->{text} };
}

##############################################################
sub parse
{
    my( $self, $string ) = @_;
    return unless defined $string;
    # TODO : add ; to last property text
    while( $string ) {
        # line starts with a comment
        if( $string =~ s,^(\s*/\*[^*]*\*+([^/*][^*]*\*+)*/\s*),,s ) {
            push @{ $self->{text} }, $1;
        }
        # line start with whitespace
        elsif( $string =~ s,^(\s+),,s ) {
            my $ws = $1;
            if( @{ $self->{text} } and  $self->{text}[-1] =~ /\s+$/ ) {
                $self->{text}[-1] .= $ws;
            }
            else {
                push @{ $self->{text} }, $ws;
            }
        }
        # property: value
        # Note this fails for property: "some; value"; please DON'T DO THAT
        elsif( $string =~ s,^((-?[_a-z][-_a-zA-Z]*)\s*:\s*(.*?)\s*(\Z|;\s*)),,is ) {
            push @{ $self->{text} }, $1;
            $self->{prop}{lc $2} = { 
                                  # name => lc( $2 ),
                                  text=>\$self->{text}[-1],
                                  value => $3
                                };
        }
    }
}

##############################################################
sub get
{
    my( $self, $key ) = @_;
    $key = lc $key;
    my $rv;
    if( $self->{prop}{ $key } ) {
        $rv = $self->{prop}{ $key }{value};
    }
    elsif( $EQUIV{$key} and $self->{prop}{ $EQUIV{$key} } ) {
        $rv = $self->{prop}{ $EQUIV{$key} }{value};
    }
    elsif( $SUBSET{ $key } ) {
        my $subset = $SUBSET{$key};
        my $value = $self->get( $subset->[0] );
        if( $value ) {
            my @values = split ' ', $value, $#$subset;
            my $n = 0+@values;
            $rv = $values[ $subset->[$n] ] if $n > 0;
        }
    }
    $rv = '' unless defined $rv;
    return $rv;
}


##############################################################
sub set
{
    my( $self, $key, $value ) = @_;
    $key = lc $key;
    my $prop = $self->{prop}{ $key };
    $value =~ s/;\s*$//;
    unless( $prop ) {
        # special case...
        return if !$value and $key eq 'display';

        $self->{text}[-1] .= ";" 
                if @{$self->{text}} and $self->{text}[-1] !~ m([;/]\s*$)s;
        push @{ $self->{text} }, "$key: $value;\n";
        $self->{prop}{ $key } = {  value => $value,
                                   # name => $key,
                                   text => \$self->{text}[-1]
                                };
    }
    else {
        # special case...
        if( !$value and $key eq 'display' ) {
            ${ $prop->{text} } = '';
            delete $self->{prop}{ lc $key };
        }
        else {
            ${ $prop->{text} } =~ s/\Q$prop->{value}/$value/;
            $prop->{value} = $value;
        }
    }
    $POE::XUL::Node::CM->after_style_change( $self, $key, $value )
            if $POE::XUL::Node::CM;
    return;
}

##############################################################
sub AUTOLOAD
{
    my( $self, $value ) = @_;
    my $key = our $AUTOLOAD;
    return if $key =~ /DESTROY$/;
	$key =~ s/^.*:://;

    $key =~ s/([A-Z])/-\L$1/g;
    if( 1 == @_ ) {
        return $self->get( $key );
    }
    else {
        return $self->set( $key, $value );
    }
    
}

1;

__END__

=head1 NAME

POE::XUL::Style - XUL style object

=head1 SYNOPSIS

    use POE::XUL::Node;

    my $node = Description( style   => "color: red; font-weight: bold", 
                            content => "YES!" 
                          );
    print $node->style->color;          # prints 'red'
    print $node->style->fontWeight;     # prints 'bold'

    $node->style->fontSize( '150%' );

    $node->style( "overflow: hidden;" );    # DOM spec tells us this is bad
    print $node->style->color;          # now it prints ''
    

=head1 DESCRIPTION

POE::XUL::Style is a DOM-like object that encapsulates the CSS style of a
XUL element. It uses L<POE::XUL::ChangeManager> to make sure all style are
mirrored in the browser's DOM.  However, style changes in the browser's DOM
are not mirrored in the POE::XUL app.

CSS parsing is round-trip safe;  All formating and comments are preserved.

The POE::XUL::Style object will I<stringize> as a full CSS declaration.
This means the old-school code that follows should still work.

    my $css = $node->style;
    $css .= "overflow-y: auto;"
                unless $css =~ s/(overflow-y: ).+?;/${1}auto/;
    $node->style( $css );

But please update your code to the following:

    $node->style->overflowY( 'auto' );

Isn't that much, much nicer?


=head1 EQUIVALENTS

If missing, the C<margin-top>, C<margin-left>, C<margin-right>,
C<margin-bottom> properties will be filled in from C<margin> property. 
The C<padding> and C<border> properties also support this.

    my $style = $node->style;
    $style->margin( '1px' );
    my $top = $style->marginTop();       # will be 1px

    $style->padding( '1px 3px 2px' );
    my $left = $style->marginLeft();     # will be 3px

    $style->border( 'thin solid red' );
    my $right = $style->borderRight();   # will be 'thin solid red'

What's more, the various sub-fields of the border property (C<-width>,
C<-style>, C<-color>) will be automaticaly found.

    $style->border( 'thin dotted black' );
    $style->borderBottom( '3px inset threedface' );
    my $topW = $style->borderTopWidth;        # will be 'thin'
    my $bottomS = $style->borderBottomStyle;  # will be 'inset'

The sub-fields of C<outline> and C<list-style> also support this:

    $style->outline( 'this dotted orange' );
    my $X = $style->outlineColor;       # will be 'orange'
    $style->listStyle( 'circle inside' );
    my $X = $style->outlinePosition;    # will be 'inside'

The C<overflow-x> and C<overflow-y> properties default to C<overflow>.

The C<-moz-border-radius-topleft>, C<-moz-border-radius-topright>, 
C<-moz-border-radius-bottomright> and C<-moz-border-radius-bottomleft>
properties default to sub-fields of C<-moz-border-radius>.

There are currently no equivalents for the C<font> property.


=head1 LIMITATIONS

=over 4

=item *

Setting a sub-fields of the border property will not modify the
corresponding border property.

    $style->borderBottom( '3px inset puce' );
    $style->borderBottomStyle( 'groove' );
    my $bottom = $style->borderBottom;  
    # $bottom will still be '3px inset puce', not '3px groove puce'

Likewise with C<padding> and C<margin>.

    $style->margin( '1px 5px 1px 0' );
    $style->marginRight( 0 );
    my $margin = $style->margin;      # still '1px 5px 1px 0'

=item *

If you set a sub-property, and then set the parent property,  the
sub-property is not changed to reflect the new parent.

    $style->marginRight( 0 );
    $style->margin( '1px 5px 1px 0' );
    my $R = $style->marginRight;      # still 0, not 5px

=item *

No attempt is made to ensure that values are valid.  The CSS spec limits
various values to a set of keywords, like C<inset, groove, solid>, etc for
C<border-style>.  Any value outside of the specification will be merrily
passed on to the browser.

=back

=head1 SEE ALSO

L<POE::XUL::Node>

L<http://developer.mozilla.org/en/docs/CSS>
has a good CSS reference.

L<http://www.w3.org/TR/CSS/>
the CSS specification.

=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 by Philip Gwyn.  All rights reserved;

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
