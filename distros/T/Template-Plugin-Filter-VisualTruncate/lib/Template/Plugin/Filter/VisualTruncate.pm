package Template::Plugin::Filter::VisualTruncate;

use warnings;
use strict;

use base qw( Template::Plugin::Filter );

use UNIVERSAL::require;

=head1 NAME

Template::Plugin::Filter::VisualTruncate - Filter Plugin for trimming text by the number of the columns of terminals and mobile phones.

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

Supported encodings on this module are UTF8, EUC-JP and system locale.

If your template was written in UTF8, then 

    [% USE Filter.VisualTruncate 'utf8' %]
    [% row.comment | visual_truncate(20, '...') | html %]

or EUC-JP

    [% USE Filter.VisualTruncate 'euc-jp' %]
    [% row.comment | visual_truncate(20, '...') | html %]

or system locale

    [% USE Filter.VisualTruncate 'locale' %]
    [% row.comment | visual_truncate(20, '...') | html %]

If parameters are not specified explicitly...

    [% row.comment | visual_truncate() | html %]

default values is used.

    [% row.comment | visual_truncate(32, '...') | html %]

=head1 FUNCTIONS

=head2 init

    Overrided method. See more detail Template::Plugin::Filter

=cut

sub init {
    my ( $self, @args ) = @_;

    $self->{_DYNAMIC}      = 1;
    $self->install_filter('visual_truncate');

    my $name = $self->{_ARGS}->[0] || 'utf8';
    my $class;

    if ($name =~ m/^utf[-]{0,1}8$/i) {
        $class = "Template::Plugin::Filter::VisualTruncate::UTF8";
    }
    elsif ($name =~ m/^euc[-]{0,1}jp$/i) {
        $class = "Template::Plugin::Filter::VisualTruncate::EUC_JP";
    }
    elsif ($name =~ m/^locale$/i) {
        $class = "Template::Plugin::Filter::VisualTruncate::Locale";
    }
    else {
        die "such a encoding $name is unsupported.";
    }

    $class->require or die;
    $self->{obj} = $class->new;

    return $self;
}

#sub truncate_filter_factory {
#    my ($context, $len, $char) = @_;
#    $len = 32 unless defined $len;
#    $char = "..." unless defined $char;
#
#    return sub {
#        my $text = shift;
#        return $text if length $text <= $len;
#        return substr($text, 0, $len - length($char)) . $char;
#    }
#}

=head2 filter

    Overrided method. See more detail Template::Plugin::Filter

=cut

sub filter {
    my ($self, $text, $args, $config) = @_;

    my $utf8_bool = utf8::is_utf8($text);

    my $len  = $args->[0] || 32; # same at Template::Filters::truncate.
    my $tail = defined $args->[1] ? $args->[1] : "...";

    my $text_width = $self->{obj}->width($text);
    my $tail_width = $self->{obj}->width($tail);

    return $text if $text_width <= $len;

    return $self->{obj}->trim($tail, $len) if $tail_width >= $len;

    my $result = $self->{obj}->trim($text, $len - $tail_width) . $tail;

    if ($utf8_bool and ! utf8::is_utf8($result)) {
        utf8::decode($result);
    }

    return $result;
}

=head1 SEE ALSO

L<HTML::Filters>, L<HTML::Plugin::Filter>, L<Text::VisualWidth>, L<Text::CharWidth>

=head1 AUTHOR

bokutin, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 bokutin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Template::Plugin::Filter::VisualTruncate
