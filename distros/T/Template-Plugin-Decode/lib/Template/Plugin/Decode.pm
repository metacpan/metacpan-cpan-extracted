package Template::Plugin::Decode;
use strict;
use warnings;

use 5.008001;

require Template::Plugin::Filter;
use base qw(Template::Plugin::Filter);
use vars qw($VERSION $DYNAMIC $FILTER_NAME);

$VERSION     = 0.02;
$DYNAMIC     = 0;
$FILTER_NAME = 'decode';

sub init {
    my $self = shift;
    my $args = shift;
    my $name = $self->{_ARGS}->[0] || $FILTER_NAME;
    $self->install_filter($name);
    return $self;
}

sub filter {
    my($self, $text) = @_;
	utf8::decode($text) unless utf8::is_utf8($text);
	return $text;
}

1;
__END__

=head1 NAME

Template::Plugin::Decode - decoding filter plugin for Template-Toolkit.

=head1 SYNOPSIS

  at first,
  [% USE Decode %]
  then you can use the filter 'decode'.
  this filter encodes string from UTF-8 to Perl's inner unicode format.
    
  [% multibyte_str | decode %]

=head1 DESCRIPTION

Template::Plugin::Decode is a plugin for TT, which allows you to decode output string to unicode(Perl inner format).

=head1 NOTE

I guess you often see scrambled results, when you use TT2 with
templates and embedded parameters including utf-8 multibyte characters.
That's because it combines decoded string(Perl inner format) and undecoded one.

To prevent it, use this module.

This is a one of solutions for this problem.

Use utf-8 template files with BOM and decode parameters that are embedded into it,
and you'll never seen garbled text.

=head1 AUTHOR

Lyo Kato E<lt>kato@lost-season.jpE<gt>

=head1 SEE ALSO

L<Template>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Lyo Kato.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

