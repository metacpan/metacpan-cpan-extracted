package Pod::Simple::Role::XHTML::WithHighlightConfig;
use Moo::Role;

our $VERSION = '0.000002';
$VERSION =~ tr/_//d;

use Pod::Simple::XHTML ();
BEGIN {
  *_ENCODE_AS_METHOD = $Pod::Simple::VERSION >= 3.16 ? sub(){1} : sub(){0};
}

with 'Pod::Simple::Role::WithHighlightConfig';

sub _encode_html_entities {
  my ($self, $text) = @_;
  if (_ENCODE_AS_METHOD) {
    $self->encode_entities($text);
  }
  else {
    Pod::Simple::XHTML::encode_entities($text);
  }
}

around start_highlight => sub {
  my ($orig, $self, $item, $config) = @_;
  $self->$orig($item, $config);
  $config ||= {};
  my $tag = '<pre';
  my @classes;
  if ($config->{line_numbers}) {
    push @classes, 'line-numbers';
    if ($config->{start_line}) {
      $tag .= ' data-start="' . $self->_encode_html_entities($config->{start_line}) . '"';
    }
  }
  if ($config->{highlight}) {
    $tag .= ' data-line="' . $self->_encode_html_entities($config->{highlight}) . '"';
  }
  if (@classes) {
    $tag .= ' class="' . join (' ', @classes) . '"';
  }
  $tag .= '><code';
  if ($config->{language}) {
    my $lang = lc $config->{language};
    $lang =~ s/\+/p/g;
    $lang =~ s/\W//g;
    $tag .= ' class="language-' . $lang . '"';
  }
  $tag .= '>';
  $self->{scratch} = $tag;
};

1;
__END__

=head1 NAME

Pod::Simple::Role::XHTML::WithHighlightConfig - Allow configuring syntax highlighting hints in Pod

=head1 SYNOPSIS

  package My::Pod::Simple::Subclass;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::XHTML::WithHighlightConfig';

=head1 DESCRIPTION

Provides the same functionality described as
L<Pod::Simple::XHTML::WithHighlightConfig> but in the form of a role.

=head1 AUTHORS

See L<Pod::Simple::XHTML::WithHighlightConfig> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Pod::Simple::XHTML::WithHighlightConfig> for the copyright and license.

=cut
