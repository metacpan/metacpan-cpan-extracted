#============================================================= -*-Perl-*-
#
# Template::Plugin::Autoformat
#
# DESCRIPTION
#   Plugin interface to Damian Conway's Text::Autoformat module.
#
# AUTHORS
#   Robert McArthur <mcarthur@dstc.edu.au>
#     - original plugin code
#
#   Andy Wardley    <abw@wardley.org>
#     - added FILTER registration, support for forms and some additional
#       documentation
#
# COPYRIGHT
#   Copyright (C) 2000-2008 Robert McArthur, Andy Wardley.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::Autoformat;

use strict;
use warnings;
use base 'Template::Plugin';
use Text::Autoformat;

our $VERSION = '2.77';

sub new {
    my ( $class, $context, $options ) = @_;
    my $filter_factory;
    my $plugin;

    if ($options) {

        # create a closure to generate filters with additional options
        $filter_factory = sub {
            my $context = shift;
            my $filtopt = ref $_[-1] eq 'HASH' ? pop : {};
            @$filtopt{ keys %$options } = values %$options;
            return sub {
                _tt_autoformat( @_, $filtopt );
            };
        };

        # and a closure to represent the plugin
        $plugin = sub {
            my $plugopt = ref $_[-1] eq 'HASH' ? pop : {};
            @$plugopt{ keys %$options } = values %$options;
            _tt_autoformat( @_, $plugopt );
        };
    }
    else {
        # simple filter factory closure (no legacy options from constructor)
        $filter_factory = sub {
            my $context = shift;
            my $filtopt = ref $_[-1] eq 'HASH' ? pop : {};
            return sub {
                _tt_autoformat( @_, $filtopt );
            };
        };

        # plugin without options can be static
        $plugin = \&_tt_autoformat;
    }

    # now define the filter and return the plugin
    $context->define_filter( 'Autoformat', [ $filter_factory => 1 ] );
    return $plugin;
}

sub _tt_autoformat {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    my $form = $options->{form};
    my $out
        = $form
        ? Text::Autoformat::form( $options, $form, @_ )
        : Text::Autoformat::autoformat( join( '', @_ ), $options );
    return $out;
}

1;

__END__

=head1 NAME

Template::Plugin::Autoformat - Interface to Text::Autoformat module

=head1 SYNOPSIS

    [% USE Autoformat(options) %]
    
    [% Autoformat(text, more_text, ..., options) %]
    
    [% FILTER Autoformat(options) %]
       a block of text
    [% END %]

=head1 EXAMPLES

    # define some text for the examples
    [% text = BLOCK %]
       Be not afeard.  The isle is full of noises, sounds and sweet 
       airs that give delight but hurt not.
    [% END %]

    # pass options to constructor...
    [% USE Autoformat(case => 'upper') %]
    [% Autoformat(text) %]
    
    # and/or pass options to the Autoformat subroutine itself
    [% USE Autoformat %]
    [% Autoformat(text, case => 'upper') %]
    
    # using the Autoformat filter
    [% USE Autoformat(left => 10, right => 30) %]
    [% FILTER Autoformat %]
       Be not afeard.  The isle is full of noises, sounds and sweet 
       airs that give delight but hurt not.
    [% END %]

    # another filter example with configuration options
    [% USE Autoformat %]
    [% FILTER Autoformat(left => 20) %]
       Be not afeard.  The isle is full of noises, sounds and sweet 
       airs that give delight but hurt not.
    [% END %]

    # another FILTER example, defining a 'poetry' filter alias
    [% USE Autoformat %]
    [% text FILTER poetry = Autoformat(left => 20, right => 40) %]
    
    # reuse the 'poetry' filter alias
    [% text FILTER poetry %]

    # shorthand form ('|' is an alias for 'FILTER')
    [% text | Autoformat %]

    # using forms
    [% USE Autoformat(form => '>>>>.<<<', numeric => 'AllPlaces') %]
    [% Autoformat(10, 20.32, 11.35) %]

=head1 DESCRIPTION

This L<Template Toolkit|Template> plugin module is an interface to Damian
Conway's C<Text::Autoformat> Perl module which provides advanced text wrapping
and formatting.

B<NOTE> as of version 2.75 the usage has changed to initial cap C<Autoformat>
instead of the previous C<autoformat>. This brings it into alignment with
standard plugin syntax.

Configuration options may be passed to the plugin constructor via the 
C<USE> directive.

    [% USE Autoformat(right => 30) %]

The Autoformat subroutine can then be called, passing in text items which 
will be wrapped and formatted according to the current configuration.

    [% Autoformat('The cat sat on the mat') %]

Additional configuration items can be passed to the Autoformat subroutine
and will be merged with any existing configuration specified via the 
constructor.

    [% Autoformat(text, left => 20) %]

Configuration options are passed directly to the C<Text::Autoformat> plugin.
At the time of writing, the basic configuration items are:

    left        left margin (default: 1)
    right       right margin (default 72)
    justify     justification as one of 'left', 'right', 'full'
                or 'centre' (default: left)
    case        case conversion as one of 'lower', 'upper',
                'sentence', 'title', or 'highlight' (default: none)
    squeeze     squeeze whitespace (default: enabled)

The plugin also accepts a C<form> item which can be used to define a 
format string.  When a form is defined, the plugin will call the 
underlying C<form()> subroutine in preference to C<Autoformat()>.

    [% USE Autoformat(form => '>>>>.<<') %]
    [% Autoformat(123.45, 666, 3.14) %]

Additional configuration items relevant to forms can also be specified.

    [% USE Autoformat(form => '>>>>.<<', numeric => 'AllPlaces') %]
    [% Autoformat(123.45, 666, 3.14) %]

These can also be passed directly to the Autoformat subroutine.

    [% USE Autoformat %]
    [% Autoformat( 123.45, 666, 3.14,
                   form    => '>>>>.<<', 
                   numeric => 'AllPlaces' )
    %]

See L<Text::Autoformat> for further details.

=head1 AUTHORS

Robert McArthur wrote the original plugin code, with some modifications and
additions from Andy Wardley.

Damian Conway wrote the L<Text::Autoformat> module which does all the clever
stuff.

The module was moved out of the L<Template Toolkit|Template> core and into
a separate distribution in December 2008.  Peter Karman is the current 
maintainer.

=head1 COPYRIGHT

Copyright (C) 2000-2015 Robert McArthur & Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Template::Plugin>, L<Text::Autoformat>

