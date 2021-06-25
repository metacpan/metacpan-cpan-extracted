package Pod::Weaver::Plugin::SingleEncoding 4.018;
# ABSTRACT: ensure that there is exactly one =encoding of known value

use Moose;
with(
  'Pod::Weaver::Role::Dialect',
  'Pod::Weaver::Role::Finalizer',
);

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use namespace::autoclean;

use Pod::Elemental::Selectors -all;

#pod =head1 OVERVIEW
#pod
#pod The SingleEncoding plugin is a Dialect and a Finalizer.
#pod
#pod During dialect translation, it will look for C<=encoding> directives.  If it
#pod finds them, it will ensure that they all agree on one encoding and remove them.
#pod
#pod During document finalization, it will insert an C<=encoding> directive at the
#pod top of the output, using the encoding previously detected.  If no encoding was
#pod detected, the plugin's C<encoding> attribute will be used instead.  That
#pod defaults to UTF-8.
#pod
#pod If you want to reject any C<=encoding> directive that doesn't match your
#pod expectations, set the C<encoding> attribute by hand.
#pod
#pod No actual validation of the encoding is done.  Pod::Weaver, after all, deals in
#pod text rather than bytes.
#pod
#pod =cut

has encoding => (
  reader => 'encoding',
  writer => '_set_encoding',
  isa    => 'Str',
  lazy   => 1,
  default   => 'UTF-8',
  predicate => '_has_encoding',
);

sub translate_dialect {
  my ($self, $document) = @_;

  my $want;
  $want = $self->encoding if $self->_has_encoding;
  if ($want) {
    $self->log_debug("enforcing encoding of $want in all pod");
  }

  my $childs = $document->children;
  my $is_enc = s_command([ qw(encoding) ]);

  for (reverse 0 .. $#$childs) {
    next unless $is_enc->( $childs->[ $_ ] );
    my $have = $childs->[$_]->content;
    $have =~ s/\s+\z//;

    if (defined $want) {
      my $ok = lc $have eq lc $want
            || lc $have eq 'utf8' && lc $want eq 'utf-8';
      confess "expected only $want encoding but found $have" unless $ok;
    } else {
      $have = 'UTF-8' if lc $have eq 'utf8';
      $self->_set_encoding($have);
      $want = $have;
    }

    splice @$childs, $_, 1;
  }

  return;
}

sub finalize_document {
  my ($self, $document, $input) = @_;

  my $encoding = Pod::Elemental::Element::Pod5::Command->new({
    command => 'encoding',
    content => $self->encoding,
  });

  my $childs = $document->children;
  my $is_pod = s_command([ qw(pod) ]); # ??
  for (0 .. $#$childs) {
    next if $is_pod->( $childs->[ $_ ] );
    $self->log_debug('setting =encoding to ' . $self->encoding);
    splice @$childs, $_, 0, $encoding;
    last;
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::SingleEncoding - ensure that there is exactly one =encoding of known value

=head1 VERSION

version 4.018

=head1 OVERVIEW

The SingleEncoding plugin is a Dialect and a Finalizer.

During dialect translation, it will look for C<=encoding> directives.  If it
finds them, it will ensure that they all agree on one encoding and remove them.

During document finalization, it will insert an C<=encoding> directive at the
top of the output, using the encoding previously detected.  If no encoding was
detected, the plugin's C<encoding> attribute will be used instead.  That
defaults to UTF-8.

If you want to reject any C<=encoding> directive that doesn't match your
expectations, set the C<encoding> attribute by hand.

No actual validation of the encoding is done.  Pod::Weaver, after all, deals in
text rather than bytes.

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
