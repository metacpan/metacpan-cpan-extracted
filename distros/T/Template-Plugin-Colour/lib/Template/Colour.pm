package Template::Colour;

use Template::Colour::Class
    debug     => 0,
    base      => 'Badger::Base',
    constants => 'HASH SCHEME WHITE BLACK',
    utils     => 'is_object',
    import    => 'class',
    messages  => {
        bad_param => 'invalid %s parameter(s): %s',
        no_param  => 'missing %s colour parameter: %s',
    };

use Template::Colour::RGB;
use Template::Colour::HSV;
use POSIX 'floor';

our $VERSION = 0.05;
our @SCHEME  = qw( 
    black darkest darker dark mid light lighter lightest white 
    pale wash dull bold bright
);
our $SPACES  = {
    RGB => 'Template::Colour::RGB',
    HSV => 'Template::Colour::HSV',
};

class->methods(
    # create methods for each of the scheme variants
    map {
        my $name = $_;              # lexical copy for closure
        $_ => sub {
            shift->scheme->{ $name };
        }
    }
    @SCHEME
);


sub new {
    my $class = shift;
    my ($config, $space);

    if (@_ == 1) {
        # single argument is either an existing colour object which we copy...
        return $_[0]->copy() 
            if is_object(ref $class || $class, $_[0]);

        # ... or a hash ref of named parameters...
        #   e.g { rgb => '#rrggbb' }, { rgb => [r, g, b] },  hsv => [h, s, v] }
        # ... or a single RGB argument
        #   e.g. [r, g, b], '#rrggbb'
        $config = ref $_[0] eq HASH ? shift : { rgb => shift };
    }
    elsif (@_ == 2) {
        # two arguments are (colour-space => $value), 
        #   e.g. (rgb => '#rrggbb'), (rgb => [r, g, b]), (hsv => [h, s, v])
        $config = { @_ };
    }
    elsif (@_ == 3) {                      
        # three arguments are (r, g, b)
        $config->{ rgb } = [ @_ ];
    }
    elsif (@_) {
        # four or more arguments are named parameters
        $config = { @_ };
    }
    else {
        # How much more black can this be?  The answer is none.  None more black.
        $config = { rgb => [0, 0, 0] };
    }
    
    if ($space = $config->{ rgb } || $config->{ RGB }) {
        # explicit RGB specification (rgb => ...)
        return $class->RGB($space);
    }
    elsif ($space = $config->{ hsv } || $config->{ HSV }) {
        # explicit HSV specification (hsv => ...)
        return $class->HSV($space);
    }
    elsif (exists $config->{ hue }) {
        # implicit HSV specification (hue => $h, ...) 
        return $class->HSV($config);
    }
    else {
        # if we don't get an explicit RGB or HSV colour space then we 
        # default to RGB to handle the (red => $r, green => $g, blue => $b) case
        return $class->RGB($config);
    }
}

sub RGB {
    my $self = shift;
    return $self->class->hash_value( SPACES => 'RGB' )->new(@_);
}

sub HSV {
    my $self = shift;
    return $self->class->hash_value( SPACES => 'HSV' )->new(@_);
}

sub copy {
    # should be redefined by subclasses
    return $_[0];
}

sub adjust {
    my $self = shift;
    return $self->not_implemented();
}

sub range {
    my $self = shift;
    return $self->not_implemented();
}

sub tints {
    my $self  = shift;
    my $steps = shift || 4;
    return $self->range($steps, @_ && $_[0] ? @_ : WHITE);
}

sub shades {
    my $self  = shift;
    my $steps = shift || 4;
    my @black = @_ && $_[0] ? @_ : BLACK;
    return $self->range($steps, @black);
}

sub scheme {
    my $self   = shift;

    # return the cached scheme if we have one and no args are defined
    return $self->[SCHEME]
        if $self->[SCHEME]
        && ! @_;

    my $args   = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $shades = $self->shades(4, $args->{ black });        # black to col
    my $tints  = $self->tints(4, $args->{ white });         # col to white
    my $washes = $tints->[3]->tints(3, $args->{ white });   # pale washes
    my $scheme = { };

    # remove the base colour and white from washes
    shift(@$washes);
    pop(@$washes);
    
    # remove base colour from shades to avoid duplication with same in tints
    shift(@$shades);

    @$scheme{ @SCHEME } = ( 
        # black, darkest, darker, dark
        reverse(@$shades), 
        # mid light lighter lightest white
        @$tints,
        # pale, wash
        @$washes,
        # dull
        $self->copy->hsv->adjust(sat => '-10%', value => '-10%'),
        # bold
        $self->copy->hsv->adjust(sat => '+10%', value => '-10%'),
        # bright
        $self->copy->hsv->adjust(sat => '+10%', value => '+10%'),
    );
    return $scheme;
}

sub variations {
    my $self   = shift;
    my $args   = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $scheme = { };
    while (my($name, $values) = each %$args) {
        $scheme->{ $name } = $self->copy->update($values);
    }
    return $scheme;
}

#------------------------------------------------------------------------
# min($r, $g, $b)
# 
# Returns minimum value from arguments, used for colour space conversion.
#------------------------------------------------------------------------

sub min { 
    my $self = shift;
    my $min  = shift; 
    foreach my $v (@_) {
        $min = $v if $v < $min;
    }
    return $min; 
}


#------------------------------------------------------------------------
# max($r, $g, $b)
# 
# Returns maximum value from arguments, used for colour space conversion.
#------------------------------------------------------------------------

sub max { 
    my $self = shift;
    my $max  = shift; 
    foreach my $v (@_) {
        $max = $v if $v > $max;
    }
    return $max; 
}


1;

__END__

=head1 NAME

Template::Colour - module for colour manipulation

=head1 SYNOPSIS

    use Template::Colour;
    
    # various ways to define a Red/Green/Blue (RGB) colour
    $orange = Template::Colour->new('#ff7f00');
    $orange = Template::Colour->new( rgb => '#ff7f00' );
    $orange = Template::Colour->new({ rgb => '#ff7f00' });
    $orange = Template::Colour->new( rgb => [255, 127, 0] );
    $orange = Template::Colour->new({ rgb => [255, 127, 0] });
    $orange = Template::Colour->new({
        red   => 255, 
        green => 127,
        blue  => 0,
    });
    
    # or go direct to the RGB method
    $orange = Template::Colour->RGB('#ff7f00');
    $orange = Template::Colour->RGB(255, 127, 0);
    # ...etc...
    
    # methods to fetch/modify the red, green and blue components
    print $orange->red();     # 255
    print $orange->green();   # 127
    print $orange->blue();    # 0
    
    # various ways to define a Hue/Saturation/Value (HSV) colour
    $orange = Template::Colour->new( hsv => [25, 255, 255] );
    $orange = Template::Colour->new({ hsv => [25, 255, 255] });
    $orange = Template::Colour->new({
        hue        =>  25,    # 0-359 degrees around colour wheel
        saturation => 255,    # 0-255
        value      => 255,    # 0-255
    });
    $orange = Template::Colour->new({
        hue =>  25,
        sat => 255,    # because life is too short for
        val => 255,    # typing long parameter names
    });
    
    print $orange->hue();        # 25
    print $orange->saturation(); # 255
    print $orange->sat();        # 255
    print $orange->value();      # 255
    print $orange->val();        # 255
    
    # convert freely between colour spaces
    $orange = $orange->rgb();    # $orange is now RGB
    $orange = $orange->hsv();    # $orange is now HSV

=head1 DESCRIPTION

This module allows you to define and manipulate colours using the RGB
(red, green, blue) and HSV (hue, saturation, value) colour spaces.

It delegates to the Template::Colour::RGB and Template::Colour::HSV
modules to do all the hard work.

=head1 METHODS

=head2 new(@args)

Creates a new colour object by delegation to either of the L<RGB()> 
or L<HSV()> methods, depending on the arguments passed.

See the L<SYNOPSIS> above for examples of use.

=head2 RGB(@args)

Creates a new L<Template::Colour::RGB> object using the Red/Green/Blue
(RGB) colour space.

=head2 HSV(@args)

Creates a new L<Template::Colour::HSV> colour object using the
Hue/Saturation/Value (HSV) colour space.

=head1 COLOUR SPACE CONVERSION ALGORITHMS

The algorithms used to covert between the RGB and HSV colour spaces
are based on the the C Code in "Computer Graphics -- Principles and
Practice,", Foley et al, 1996, p. 592-593.

Due to a limitation in the particular implementation chosen (to use
integers rather than floating point numbers to represent RGB and HSV
components), the conversion between colour spaces is not totally
symmetrical.  That is, if you convert a colour from RGB to HSV and
then back again, you may not get back exactly the same colour you
started with.

=head1 EXAMPLES

=head2 What Colour is Orange?

Everyone needs to know what colour orange is in RGB and HSV.

I find the easiest way to remember is that its Hue is 30 degrees,
with full Saturation and Value.  

    use Template::Colour;
    my $orange = Template::Colour( hsv => [30, 255, 255] );

Use the 'rgb' method to convert it to RGB, and 'html' to display it
as an HTML formatted hex string.

    my $html_hex = $orange->rgb->html();

As it happens, orange is pretty easy to remember in RGB, too. It's
C<#ff7f00> which is full red (C<ff>), half green (C<7f>) and no blue
(C<00>). It just goes to reinforce the widely held belief that orange
really is one of the best colours ever. Whoever invented it should
probably get an award of some kind, or maybe even a pony.

=head2 How Do I Make a Nice Colour Scheme?

Let's start with orange, shall we?

    my $orange = Template::Colour->HSV(30, 255, 255);

Now copy it twice to create a lighter (more white) version by reducing
the saturation, and a darker version (more black) by reducing the value.

    [% lighter = orange.copy( saturation = 127 );
       darker  = orange.copy( value = 127 );
    %]

Now you can convert them to RGB for display in your HTML page.

    [% orange.html  %]  => #ff7f00
    [% lighter.html %]  => #ffbf80 
    [% darker.html  %]  => #7f3f00

If you want a strongly contrasting colour, then shift the hue 180 degrees
around the colour wheel.  In this case, going from 30 to 210 to give a 
nice shade of blue.

    [% contrast = orange.copy( hue = 210 ).html %]  => #007fff

=head2 How Much More Black Could This Be?

How much more black could this be?

    [% black = Colour.RGB %]        # defaults to 0, 0, 0

The answer is none. None more black.

=head1 VERSION

This is version 0.04 of the Template::Plugin::Colour module set.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Written using algorithms from "Computer Graphics -- Principles and Practice", 
Foley et al, 1996, p. 592-593.

=head1 SEE ALSO

L<Template::Colour::RGB>, L<Template::Colour::HSV>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

