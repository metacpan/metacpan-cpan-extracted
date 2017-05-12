package Template::Plugin::XML::Escape;
# $Id$

use 5.006001;
use strict;
use warnings;
use Template::Plugin::Filter;
use base 'Template::Plugin::Filter';

our $VERSION = '0.02';

our $NAME = 'xml_escape';

sub init {
    my $self = shift;
    $self->install_filter($self->{_ARGS}->[0] || $NAME);

    return $self;
}

sub filter {
    my ($self, $text, undef, $config) = @_;
    $text =~ s/&/&amp;/go;
    $text =~ s/</&lt;/go;
    $text =~ s/>/&gt;/go;
    $text =~ s/'/&apos;/go;
    $text =~ s/"/&quot;/go;
    return $text;
}

1;
__END__

=head1 NAME

Template::Plugin::XML::Escape - Escape variables to suit being placed into XML

=head1 SYNOPSIS

  [% USE XML.Escape %]
  ...
  <foo bar="[% c.variable | xml_escape %]" />

=head1 DESCRIPTION

Escapes XML entities from text, so that you don't fall prey to people putting
quotes, less-than/greater-than, and ampersands, into variables that end up in
TT templates.

=head1 SEE ALSO

 * Template Toolkit

=head1 AUTHOR

Toby Corkindale, E<lt>cpan@corkindale.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Toby Corkindale.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
