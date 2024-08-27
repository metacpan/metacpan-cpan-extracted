package Pod::Simple::XHTML::WithHighlightConfig;
use Moo;

our $VERSION = '0.000003';
$VERSION =~ tr/_//d;

extends 'Pod::Simple::XHTML';
with 'Pod::Simple::Role::XHTML::WithHighlightConfig';

1;
__END__

=head1 NAME

Pod::Simple::XHTML::WithHighlightConfig - Allow configuring syntax highlighting hints in Pod

=head1 SYNOPSIS

  my $parser = Pod::Simple::XHTML::WithHighlightConfig->new;
  $parser->parse_file('path/to/file.pod');

=head1 DESCRIPTION

This is a L<Pod::Simple::XHTML> subclass that consumes the role
L<Pod::Simple::Role::XHTML::WithHighlightConfig>. See
L<Pod::Simple::Role::XHTML::WithHighlightConfig> for documentation about its
use in Pod.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2014 the Pod::Simple::XHTML::WithHighlightConfig L</AUTHOR> and
L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
