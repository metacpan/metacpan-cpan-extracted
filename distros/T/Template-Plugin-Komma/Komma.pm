package Template::Plugin::Komma;
our $VERSION = '0.07';


use strict;
use warnings;

use base 'Template::Plugin';


# taken from Math::Round
my $half = 0.50000000000008;


sub new {
    my ($self, $context) = @_;

    $context->define_filter('komma',  \&komma,  '');
    $context->define_filter('komma0', \&komma0, '');
    $context->define_filter('komma2', \&komma2, '');

    return $self;
}

sub komma {
    my $number = shift;

    return undef unless defined $number;
    return '' if $number eq '';

    return _komma($number+0);
}

sub _komma {
    my $number = shift;
    my @number = split(/\./, $number);
    my $ready  = '';

    while ($number[0] =~ /([+-]*\d+)(\d{3})$/) {
        $number[0] = $1;
        $ready     = '.'.$2.$ready;
    }
    $ready = $number[0].$ready;

    if ($number[1]) {
        $ready .= ",$number[1]";
    }

    return $ready;
}

sub komma0 {
    my $number = shift;

    return undef unless defined $number;
    return '' if $number eq '';

    my $round = ($number < 0) ? -$half : $half;
    return _komma(int($number + $round));
}

sub komma2 {
    my $number = shift;

    return undef unless defined $number;
    return '' if $number eq '';

    # round two digits after the dot
    my $round = ($number < 0) ? -$half : $half;
    $number   = int($number * 100 + $round);

    # eventually fill with zeros
    while (length $number < 3) {
        $number = "0".$number;
    }

    # insert dot
    $number =~ s/(\d\d)$/\.$1/;

    return _komma($number);
}


1;
__END__

=head1 NAME

Template::Plugin::Komma - TT2 plugin to commify numbers (German format)

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  [% USE Komma %]
  Prozent:   [% 12.3    | komma %] %
  Einwohner: [% 1200000 | komma0 %]
  Preis:     [% 44.9    | komma2 %] EUR

  # Output:
  Prozent:   12,3 %
  Einwohner: 1.200.000
  Preis      44,90 EUR

=head1 DESCRIPTION

This plugin is the German version of L<Template::Plugin::Comma>.
It installs 3 filters: C<komma>, C<komma0> and C<komma2>.

C<komma> outputs the number with ',' as decimal point and '.' as
thousand separator.

C<komma0> rounds the number to an integer and outputs the number
with thousend separators.

C<komma2> rounds the number to 2 digits after the point
(Nachkommastellen). This is especially useful for currency amounts.

=head1 NOTE

The interface is a little bit different to L<Template::Plugin::Comma>,
C<komma> expects a number as parameter (C<comma> can be feeded with
a whole line of text and only the numbers are converted.)

=head1 AUTHOR

Uwe Voelker E<lt>uwe.voelker@gmx.deE<gt>

Based on L<Template::Plugin::Comma> by
Yoshiki Kurihara E<lt>kurihara@cpan.orgE<gt> and
Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Template::Plugin::Comma>,
L<Template::Plugin::Number::Format>

=cut