package Template::Plugin::JavaScript::Compactor;
use strict;
use base qw (Template::Plugin::Filter);
use Data::JavaScript::Compactor;

our $VERSION = 0.01;

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}->[0] || 'jscompactor');
    $self;
}

sub filter {
    my ($self, $text) = @_;
    return Data::JavaScript::Compactor->compact($text);
}

1;

__END__

=head1 NAME

Template::Plugin::JavaScript::Compactor - TT plugin for Data::JavaScript::Compactor

=head1 SYNOPSIS

  [% USE JavaScript::Compactor -%]
  [% FILTER jscompactor -%]
  document.writeln('Hello, World!');
  function foobar () {
    alert('hoge');
  }
  [%- END %]

=head1 DESCRIPTION

Template::Plugin::JavaScript::Compactor is a plugin for TT, which allows you to make your JavaScript compact.

=head1 SEE ALSO

L<Template>, L<Data::JavaScript::Compactor>

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
