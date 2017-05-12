package Template::Plugin::Lingua::EN::Fractions;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = 0.02;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Lingua::EN::Fractions qw( fraction2words );

$Template::Stash::SCALAR_OPS->{'fraction2words'} = \&_fraction2words;

sub new {
    my ($class, $context, $options) = @_;

    # now define the filter and return the plugin
    $context->define_filter('fraction2words', \&_fraction2words);
    return bless {}, $class;
}

sub _fraction2words {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return fraction2words(join('', @_));
}

1;

__END__

=head1 NAME

Template::Plugin::Lingua::EN::Fractions - TT2 interface to Lingua::EN::Fractions module

=head1 SYNOPSIS

  [% USE Lingua.EN.Fractions -%]
  [% checksum = content FILTER fraction2words -%]
  [% checksum = content.fraction2words -%]

=head1 DESCRIPTION

The I<Lingua::EN::Fractions> Template Toolkit plugin provides access to the
Lingua::EN::Fractions module functions, to translate number values to their
names.

When you invoke

  [% USE Lingua.EN.Fractions %]

the following filters (and vmethods of the same name) are installed
into the current context:

=over 4

=item C<fraction2words>

Converts a fraction (such as 3/4) into English text (such as "three quarters").

=back

=head1 SEE ALSO

L<Lingua::EN::Fractions>, L<Template>, C<Template::Plugin>

=head1 AUTHOR

  Barbie <barbie@cpan.org>  2014

=head1 ACKNOWLEDGEMENTS

Andrew Ford for writing Template::Plugin::Lingua::EN::Inflect, which inspired
this module.

Neil Bowers for creating Lingua::EN::Fractions, and giving me the idea to add 
another distribution to my new Template Toolkit plugins collection, which I've
recently taken over from Andrew Ford.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2014-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
