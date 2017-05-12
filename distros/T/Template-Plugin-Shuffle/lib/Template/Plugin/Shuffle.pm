package Template::Plugin::Shuffle;

use strict;
use vars qw($VERSION);
$VERSION = "0.02";

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Algorithm::Numerical::Shuffle qw(shuffle);

sub new {
    my ($pkg, $context, @args) = @_;
    $context->define_vmethod('LIST', shuffle => sub {
                                 return [ shuffle(@{$_[0]}) ];
                             });
    return $pkg->SUPER::new($context, @args);
}

1;
__END__

=head1 NAME

Template::Plugin::Shuffle - TT Vmethods for shuffling lists

=head1 SYNOPSIS

  [% USE Shuffle %]
  [% FOREACH item = items.shuffle %]
  Name: [% item.name %]
  [% END %]

=head1 DESCRIPTION

Template::Plugin::Shuffle is a TT plugin to define Virtual Methods to
shuffle a list variable.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Algorithm::Numerical::Shuffle>, L<Template>

=cut
