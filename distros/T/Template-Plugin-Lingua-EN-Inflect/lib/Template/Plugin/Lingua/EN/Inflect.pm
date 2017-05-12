package Template::Plugin::Lingua::EN::Inflect;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = 0.04;

require Template::Plugin;
use base qw(Template::Plugin);
use Lingua::EN::Inflect qw( inflect );

sub new {
    my ($class, $context, $options) = @_;
    my $filter_factory;
    my $plugin;

    if ($options) {
        # create a closure to generate filters with additional options
        $filter_factory = sub {
            my $context = shift;
            my $filtopt = ref $_[-1] eq 'HASH' ? pop : {};
            @$filtopt{ keys %$options } = values %$options;
            return sub {
                tt_inflect(@_, $filtopt);
            };
        };

        # and a closure to represent the plugin
        $plugin = sub {
            my $plugopt = ref $_[-1] eq 'HASH' ? pop : {};
            @$plugopt{ keys %$options } = values %$options;
            tt_inflect(@_, $plugopt);
        };
    } else {
        # simple filter factory closure (no legacy options from constructor)
        $filter_factory = sub {
            my $context = shift;
            my $filtopt = ref $_[-1] eq 'HASH' ? pop : {};
            return sub {
                tt_inflect(@_, $filtopt);
            };
        };

        # plugin without options can be static
        $plugin = \&tt_inflect;
    }

    # now define the filter and return the plugin
    $context->define_filter('inflect', [ $filter_factory => 1 ]);
    return bless $plugin, $class;
}

sub tt_inflect {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    my $number = $options->{ number };
    Lingua::EN::Inflect::NUM($number) if $number;
    my $out = inflect(join('', @_));
    return $out;
}

sub classical   { shift; return Lingua::EN::Inflect::classical(@_); }
sub def_noun    { shift; return Lingua::EN::Inflect::def_noun(@_);  }
sub def_verb    { shift; return Lingua::EN::Inflect::def_verb(@_);  }
sub def_adj     { shift; return Lingua::EN::Inflect::def_adj(@_);   }
sub def_a       { shift; return Lingua::EN::Inflect::def_a(@_);     }
sub def_an      { shift; return Lingua::EN::Inflect::def_an(@_);    }
sub A           { shift; return Lingua::EN::Inflect::A(@_);         }
sub AN          { shift; return Lingua::EN::Inflect::AN(@_);        }
sub NO          { shift; return Lingua::EN::Inflect::NO(@_);        }
sub NUM  	    { shift; return Lingua::EN::Inflect::NUM(@_);       }
sub NUMWORDS	{ shift; return Lingua::EN::Inflect::NUMWORDS(@_);  }
sub ORD         { return Lingua::EN::Inflect::ORD($_[1]);           }
sub PART_PRES	{ shift; return Lingua::EN::Inflect::PART_PRES(@_); }
sub PL          { shift; return Lingua::EN::Inflect::PL(@_);        }
sub PL_N        { shift; return Lingua::EN::Inflect::PL_N(@_);      }
sub PL_V        { shift; return Lingua::EN::Inflect::PL_V(@_);      }
sub PL_ADJ      { shift; return Lingua::EN::Inflect::PL_ADJ(@_);    }
sub PL_eq       { shift; return Lingua::EN::Inflect::PL_eq(@_);     }
sub PL_N_eq     { shift; return Lingua::EN::Inflect::PL_N_eq(@_);   }
sub PL_V_eq     { shift; return Lingua::EN::Inflect::PL_V_eq(@_);   }
sub PL_ADJ_eq   { shift; return Lingua::EN::Inflect::PL_ADJ_eq(@_); }

1;

__END__

=head1 NAME

Template::Plugin::Lingua::EN::Inflect - Interface to Lingua::EN::Inflect module

=head1 SYNOPSIS

  [% USE infl = Lingua.EN.Inflect; -%]
  [% FILTER inflect(number => 42); -%]
    There PL_V(was) NO(error).
    PL_ADJ(This) PL_N(error) PL_V(was) fatal.
  [% END; -%]

  [% "... and "; infl.ORD(9); "ly..." %]

  # Output:
  #   There were 42 errors.
  #   These errors were fatal.
  #   ... and 9thly...

=head1 DESCRIPTION

The Lingua::EN::Inflect is an interface to Damian Conway's
Linua::EN::Inflect Perl module, which provides plural inflections,
"a"/"an" selection for English words, and manipulation of numbers as words.

The plugin provides an 'inflect' filter, which can be used to
interpolate inflections in a string.  The NUM() function sets a
persistent default value to be used whenever an optional number
argument is omitted.  The number to be used for a particular
invocation of 'inflect' can also be specified with a 'number' option.

For the full gory details of the inflection functionality refer to the
L<Lingua::EN::Inflect> manual.

=head1 OBJECT METHODS

=over 4

=item C<infl.A($string, $opt_number)>

prepends the appropriate indefinite article to a word, depending on
its pronunciation.  If the second argument is provided and its value
is numeric and not 1 then the value of the second argument is used
instead.

e.g. C<infl.A("idea")> returns C<"an idea">

=item C<AN($string, $opt_number)>

synonym for C<A()>

=item C<NO($string, $opt_arg)>

given a word and an optional count, returns the count followed by the 
correctly inflected word

=item C<NUM($string, $opt_arg)>

sets a persistent I<default number> value, which is subsequently used
whenever an optional second I<number> argument is omitted.  The
default value thus set can subsequently be removed by calling C<NUM()>
with no arguments.  C<NUM()> normally returns its first argument,
however if C<NUM()> is called with a second argument that is defined
and evaluates to false then C<NUM()> returns an empty string.

=item C<NUMWORDS($string, $opt_arg)>

takes a number (cardinal or ordinal) and returns an English represen-
tation of that number. In a scalar context a string is returned. In a
list context each comma-separated chunk is returned as a separate
element.

=item C<ORD($number)>

takes a single argument and forms its ordinal equivalent.  If the
argument isn't a numerical integer, it just adds "-th".

=item C<PART_PRES($string, $opt_arg)>

returns the present participle for a third person singluar verb

    PART_PRES("runs");		# returns "running"

=item C<PL($string, $opt_arg)>

returns the plural of a I<singular> English noun, pronoun, verb or adjective.

=item C<PL_N($string, $opt_arg)>

returns the plural of a I<singular> English noun or pronoun.

=item C<PL_V($string, $opt_arg)>

returns the plural conjugation of the I<singular> form of a conjugated verb.

=item C<PL_ADJ($string, $opt_arg)>

returns the plural form of a I<singular> form of certain types of adjectives.

=item C<PL_eq($string, $opt_arg)>

=item C<PL_N_eq($string, $opt_arg)>

=item C<PL_V_eq($string, $opt_arg)>

=item C<PL_ADJ_eq($string, $opt_arg)>

=item C<classical($string, $opt_arg)>

=item C<def_noun($string, $opt_arg)>

=item C<def_verb($string, $opt_arg)>

=item C<def_adj($string, $opt_arg)>

=item C<def_a($string, $opt_arg)>

=item C<def_an($string, $opt_arg)>

=back

=head1 INTERNAL METHODS

=over 4

=item C<tt_inflect($string, $opt_arg)>

The underlying inflect filter.

=back

=head1 TODO

Finish off documenting the object methods.

Provide tests for all methods in the test suite.

It would also be nice to have methods that spelled out numbers that
were less than a certain threshold and that formatted large numbers
with commas, for example:

     inflect("There PL_V(was) NO(error).", number => 0);
     # outputs: "There were no errors."

     inflect("There PL_V(was) NO(error).", number => 1);
     # outputs: "There was one errors."

     inflect("There PL_V(was) NO(error).", number => 3);
     # outputs: "There were three errors."

     inflect("There PL_V(was) NO(error).", number => 1042);
     # outputs: "There were 1,042 errors."

This would require changes to the L<Lingua::EN::Inflect> module.
 
=head1 SEE ALSO

L<Lingua::EN::Inflect>, L<Template>, C<Template::Plugin>

=head1 DEDICATION

This distribution was originally created by Andrew Ford. Sadly in early 2014,
Andrew was diagnosed with Pancreatic Cancer and passed away peacfully at home
on 25th April 2014.

One of his wishes was for his OpenSource work to continue. At his funeral, many
of his colleagues and friends, spoke of how he felt like a person of the world, 
and how he embrace the idea of OpenSource being for the benefit of the world.

Anyone wishing to donate in memory of Andrew, please consider the following
charities:

=over

=item Dignity in Dying - L<http://www.dignityindying.org.uk/>

=item Marie Curie Cancer Care - L<http://www.mariecurie.org.uk/>

=back

=head1 AUTHOR

  Original Author:    Andrew Ford               2005-2014
  Current Maintainer: Barbie <barbie@cpan.org>  2014

=head1 ACKNOWLEDGEMENTS

Andrew Ford wrote the original plugin code (basing it heavily on the 
Template::Plugin::Autoformat code).

Damian Conway E<lt>damian@conway.orgE<gt> wrote the
Lingua::EN::Inflect module, which does all the clever stuff.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2005-2014 Andrew Ford
Copyright (C) 2014-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
