package Mojolicious::Plugin::Number::Commify;
use Mojolicious::Plugin -base;

our $VERSION = 0.041;

sub register {
  my ($self, $app, $cfg) = @_;
  $app->helper(commify => sub {
    my ($self, $number) = @_;
    my $sep = $cfg->{separator} // ',';
    $number =~ s/(
      ^[-+]?  # beginning of number.
      \d+?    # first digits before first comma
      (?=     # followed by, (but not included in the match) :
        (?>(?:\d{3})+) # some positive multiple of three digits.
        (?!\d)         # an *exact* multiple, not x * 3 + 1 or whatever.
      )
      |       # or:
      \G\d{3} # after the last group, get three digits
      (?=\d)  # but they have to have more digits after them.
    )/$1$sep/xgo;
    $number;
  });
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Number::Commify - Numbers 1,000,000 times more readable

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Number::Commify');

  # Mojolicious::Lite
  plugin 'Number::Commify';

=head1 DESCRIPTION

Mojolicious::Plugin::Number::Commify is a L<Mojolicious> plugin for putting
commas into big numbers.  Sometimes this is 1,000,000 times better than letting
the reader try to parse it.

=head1 USAGE

The plugin takes an optional 'separator' to use for separating groups of digits.
Any length of string can be used, but common choices are dot ('.'), space (' '),
underscore ('_') or apostrophe ("'").  If no separator is specified, it defaults
to comma (',').

  $self->plugin('Number::Commify' => { separator => '.' });

=head1 METHODS

L<Mojolicious::Plugin::Number::Commify> inherits all methods from
L<Mojolicious::Plugin>.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 RATIONALE

It's often useful to have access to a commify function in views, so an easily
accessible helper is in order.

=head1 COPYRIGHT AND LICENSE

Copyright (C) Benjamin Goldberg, Nic Sandfield

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<perlfaq5>, L<Mojolicious::Guides>.
