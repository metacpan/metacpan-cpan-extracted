package Template::Plugin::HTML::Strip;

use 5.006;
use strict;

our $VERSION = '0.01';

use Template::Plugin::Filter;
use base 'Template::Plugin::Filter';
use HTML::Strip;

my $FILTER_NAME = 'html_strip';

sub init {
    my $self = shift;

    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}->[0] || $FILTER_NAME);

    return $self;
}

sub filter {
    my ($self, $text, undef, $config) = @_;
    $config = $self->merge_config($config);

    my $hs = HTML::Strip->new(%$config);
    return $hs->parse($text);
}

1;

__END__

=head1 NAME

Template::Plugin::HTML::Strip - HTML::Strip filter for Template Toolkit

=head1 SYNOPSIS

  [% USE HTML.Strip %]

  [% FILTER html_strip %]
  <title>People for the Preservation of Presentational Markup</title>
  <h1>HTML::Strip - A cause for concern?</h1>
  [% END %]

  [% USE HTML.Strip 'strip'
      striptags   = [ 'script' 'iframe' ]
      emit_spaces = 0
  %]

  [% FILTER strip %]
  <p>A call to arms against the removal of our elements!</p>
  [% END %]

=head1 DESCRIPTION

This module is a Template Toolkit dynamic filter, which uses HTML::Strip
to remove markup (primarily HTML, but also SGML, XML, etc) from filtered
content during template processing.

By default, the installed filter's name is 'html_strip'.  This can be
changed by specifying a new name as the first positional argument
during plugin usage:

  [% USE HTML.Strip 'strip' %]

  [% '<div>Our very existence is under threat.</div>' | strip %]

The filter can optionally take configuration options, which will be
passed to HTML::Strip's constructor method:

  [% USE HTML.Strip
      striptags   = [ 'applet' 'strong' ]
      emit_spaces = 0
  %]

  [% FILTER html_strip %]
  <strong>Are we next!?</strong>
  [% END %]

For more details on available configuration options, please refer to
L<HTML::Strip|HTML::Strip>.

=head1 METHODS

=head2 init

Creates a dynamic filter and installs the filter under the value provided
for the first positional argument, otherwise uses 'html_strip'.

=head2 filter

Receives a reference to the plugin object, along with the text to be
filtered and configuration options.  Using HTML::Strip, returns the filtered
(stripped) text.

=head1 SEE ALSO

L<Template|Template>, L<HTML::Strip|HTML::Strip>

=head1 AUTHOR

Geoff Simmons E<lt>gsimmons@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Geoff Simmons

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
