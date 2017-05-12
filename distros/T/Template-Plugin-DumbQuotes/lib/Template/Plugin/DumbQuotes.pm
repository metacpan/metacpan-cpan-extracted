package Template::Plugin::DumbQuotes;

use vars qw($VERSION);
$VERSION = "0.01";
use strict;
use warnings;

use Template::Plugin::Filter;
use base qw(Template::Plugin::Filter);
use Encode;
use utf8;

=pod

=head1 NAME

Template::Plugin::DumbQuotes - Transform educated quotes to dumb quotes

=head1 DESCRIPTION

Installs a filter to change Smart Quotes (curly etc...) and similar characters
to plain/dumb equivalent (ASCII safe)

=head1 SYNOPSIS

    [% USE DumbQuotes %]
    [% FILTER dumb_quotes %]
        “This is an example of smart-quotes”
    [% END %]
    [%# will be changed to :
        "This is an example of smart-quotes"
    %]
    
    [%# Specify another filter name for your convenience %]
    [% USE DumbQuotes dq %]
    [% | dq %][% | loc %]What’s up[% END %][% END %]

=head1 FILTERS

=over 4

=item double quotes ” and “

are changed  to "

=item guillemets «»

are changed to "

=item single quotes ‘’

are changed to C<`> and C<'>

=item dashes –—

are changed to hyphen-minus C<->

=item ellipsis …

is changed to three dots : C<...>

=back


=head1 INTERNALS

=head2 init

init respects TT interface to initialise the filter

=cut

sub init {
    my $self = shift;
    my $name = $self->{ _ARGS }->[ 0 ] || 'dumb_quotes';
    $self->install_filter($name);
    return $self;
}

=head2 filter

uses a regexp internally to change the text in input.

=cut

sub filter {
    my ($self, $text) = @_;
    my $decoded = Encode::is_utf8($text);
    unless ($decoded) {
        $text = Encode::decode_utf8($text);
    }
    $text =~ y/«»”“‘’/""""`'/;
    $text =~ s/[\x{2012}-\x{2015}]/-/g;
    $text =~ s/…/.../g;
    $text = Encode::encode_utf8($text) unless $decoded;
    return $text;
}

1;

=head1 MOTIVATION

The original reason why this plugin has been created is to decrease the number of
different but yet similar strings in translation files (Using L<Locale::Maketext>).
Indeed in templates, depending on the context, you want to use smort-quotes for 
rich-capable user-agent, and in some other cases (exemple text-email templates) you
just want dumb-quotes.

This plugins allows you to use the rich version in templates by filtering them out,
and still, you will only have an unique lexicon entry in your .po (or whatever).

Example:

[% |dumb_quotes %] [% |loc %]let’s roll[% END %] [% END %]

=head1 UTF-8

It should work flawlessly whether your template is unicode encoded or not.

=head1 LICENSE

I<Template::Plugin::DumbQuotes> is free software; you may redistribute it and/or 
modify it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<Template::Plugin::DumbQuotes> is Copyright 2005-2007
Six Apart, cpan (at) sixapart (dot) com. All rights reserved.

=cut
