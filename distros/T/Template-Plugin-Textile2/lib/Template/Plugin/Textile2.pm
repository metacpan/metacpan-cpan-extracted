package Template::Plugin::Textile2;

use strict;
use warnings;
use Template::Plugin::Filter;
use Text::Textile;

our $VERSION = "1.21";

use base qw/Template::Plugin::Filter/;

sub init {
    my ($self, $args) = @_;

    die 'Args must be an hashref'
        if (defined $args) && (ref $args ne 'HASH');
    
    $self-> { _FORMAT_MODE }
        = $args->{format_mode} || 'default';
    delete $args->{format_mode};        

    $self->{ _TEXTILE } = Text::Textile->new(
        %$args
    );

    my $name = $self->{ _CONFIG }->{ name } || 'textile2';
    $self->install_filter($name);

    return $self;
}

sub filter {
    my ($self, $text) = @_;

    if ( $self->{_FORMAT_MODE} eq 'inline' ) {    
        return $self->{_TEXTILE}->format_inline(text => $text);
    }
    else {
        return $self->{_TEXTILE}->process($text);
    }
}

1;

__END__

=head1 NAME

Template::Plugin::Textile2 - Use Textile formatting with Template Toolkit

=head1 SYNOPSIS

  [% USE Textile2 -%]
  [% FILTER textile2 %]This *bold* and this is _italic_.[% END %]

  <p>this is <strong>bold</strong> and this is <em>italic</em>.


  [% USE Textile2 ( disable_html => 1 ) -%]
  [% FILTER textile2 %]this is<br /> _italic_.[% END %]

  <p>this is&lt;br /&gt; <em>italic</em>.</p>

=head1 DESCRIPTION

This module wraps Text::Textile into a plugin Template Toolkit.  It
provides a filter named C<textile2>.
This aims to be a more feature-full version L<Template::Plugin::Textile>,
by allowing you to pass parameters to L<Text::Textile>. 

Use this way:

    [% FILTER textile2 %]
    Reasons to use the Template Toolkit:

    * Seperation of concerns.
    * It's written in Perl.
    * Badgers are Still Cool.
    [% END %]

or:

    [% mytext | textile2 %]

You can pass the same options you would pass to Text::Textile, directly
when using the template. For instance to disable processing of HTML
tags you can do:

    [% USE Textile2 ( disable_html => 1 ) %]

To avoid your text to be wrapped into C<&lt;p&gt...&lt;/p&gt> you can
use:

    [% USE Textile2 ( format_mode => 'inline' ) %]

See L<Text::Textile> for details.

=head1 AUTHOR

Michele Beltrame C<mb@italpro.net>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::Textile>, L<Template>

=cut
