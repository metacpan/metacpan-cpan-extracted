package Template::Plugin::Hatena;
use strict;
use base qw (Template::Plugin::Filter);
use Text::Hatena;

our $VERSION = 0.02;

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}->[0] || 'hatena');
    $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;

    if (Text::Hatena->VERSION >= 0.20) {
        Text::Hatena->parse($text)
    } else {
        my $parser = Text::Hatena->new(%$config);
        $parser->parse($text);
        return $parser->html;
    }
}

1;

__END__

=head1 NAME

Template::Plugin::Hatena - TT plugin for Text::Hatena

=head1 SYNOPSIS

  [% USE Hatena -%]
  [% FILTER hatena -%]
  * Hello, World!

  - Good Morning
  -- Greetings

  * Farewell

  - Good Bye
  - Thank you
  [%- END %]

=head1 DESCRIPTION

Template::Plugin::Hatena is a plugin for TT, which format your text with Hatena Style.

=head1 SEE ALSO

L<Template>, L<Text::Hatena>

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
