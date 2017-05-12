package Template::Plugin::Lingua::EN::Numbers;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = 0.02;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Lingua::EN::Numbers             qw( num2en num2en_ordinal );
use Lingua::EN::Numbers::Years      qw( year2en );
use Lingua::EN::Numbers::Ordinate   qw( ordinate );

$Template::Stash::SCALAR_OPS->{'num2en'}            = \&_num2en;
$Template::Stash::SCALAR_OPS->{'num2en_ordinal'}    = \&_num2en_ordinal;
$Template::Stash::SCALAR_OPS->{'year2en'}           = \&_year2en;
$Template::Stash::SCALAR_OPS->{'ordinate'}          = \&_ordinate;

sub new {
    my ($class, $context, $options) = @_;

    # now define the filter and return the plugin
    $context->define_filter('num2en',           \&_num2en);
    $context->define_filter('num2en_ordinal',   \&_num2en_ordinal);
    $context->define_filter('year2en',          \&_year2en);
    $context->define_filter('ordinate',         \&_ordinate);
    return bless {}, $class;
}

sub _num2en {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return num2en(join('', @_));
}

sub _num2en_ordinal {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return num2en_ordinal(join('', @_));
}

sub _year2en {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return year2en(join('', @_));
}

sub _ordinate {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return ordinate(join('', @_));
}

1;

__END__

=head1 NAME

Template::Plugin::Lingua::EN::Numbers - TT2 interface to Lingua::EN::Numbers module

=head1 SYNOPSIS

  [% USE Lingua.EN.Numbers -%]
  [% checksum = content FILTER num2en -%]
  [% checksum = content FILTER num2en_ordinal -%]
  [% checksum = content FILTER year2en -%]
  [% checksum = content FILTER ordinate -%]
  [% checksum = content.num2en -%]
  [% checksum = content.num2en_ordinal -%]
  [% checksum = content.year2en -%]
  [% checksum = content.ordinate -%]

=head1 DESCRIPTION

The I<Lingua::EN::Numbers> Template Toolkit plugin provides access to the
Lingua::EN::Numbers, Lingua::EN::Numbers::Years and 
Lingua::EN::Numbers::Ordinate module functions, to translate number values to
their names.

When you invoke

  [% USE Lingua.EN.Numbers %]

the following filters (and vmethods of the same name) are installed
into the current context:

=over 4

=item C<num2en>

Converts a number (such as 123) into English text (such as "one hundred and 
twenty-three").

=item C<num2en_ordinal>

Converts a number into the ordinal form in words, so 54 becomes "fifty-fourth".

=item C<year2en>

Converts a number (such as 1984) into English text (such as "nineteen 
eighty-four").

=item C<ordinate>

Converts a number (such as 3) into ordinal form (such as "3rd").

=back

=head1 SEE ALSO

L<Lingua::EN::Numbers>, L<Lingua::EN::Numbers::Years>, 
L<Lingua::EN::Numbers::Ordinate>, L<Template>, C<Template::Plugin>

=head1 AUTHOR

  Barbie <barbie@cpan.org>  2014

=head1 ACKNOWLEDGEMENTS

Andrew Ford for writing L<Template::Plugin::Lingua::EN::Inflect>, which 
inspired this module.

Neil Bowers for taking over Sean M Burke's 
Lingua::EN::Numbers(::(Years|Ordinate))?, modules, and giving me the idea to 
add to my new Template Toolkit plugins collection, which I've recently taken 
over from Andrew Ford.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2014-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
