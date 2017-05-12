package Template::Plugin::UTF8Decode;

use 5.006;
use strict;

our $VERSION = '0.01';

my $FILTER_NAME = 'utf8_decode';

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

sub init {
    my $self = shift;

    $self->install_filter($FILTER_NAME);

    return $self;
}
   
sub filter {
    my ($self, $text) = @_;
    
    utf8::decode($text);
    
    return $text;
}

1;

__END__

=head1 NAME

Template::Plugin::UTF8Decode - UTF8 decoder filter for Template Toolkit

=head1 SYNOPSIS

  [% USE UTF8Decode %]

  [% ansi_string_var | utf8_decode | html_entity %]

=head1 DESCRIPTION

This module is a Template Toolkit filter, which decode a string to utf8.
For example, using FreeTDS (http://www.freetds.org) in order to talk with ms sql, can return an utf8 string
as byte char.

=head1 METHODS

=head2 init

Installs the filter as 'utf8_decode'.

=head2 filter

Receives a reference to the plugin object, along with the text to be
filtered.

=head1 AUTHOR

Fabio Masini E<lt>fabio.masini@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Fabio Masini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
