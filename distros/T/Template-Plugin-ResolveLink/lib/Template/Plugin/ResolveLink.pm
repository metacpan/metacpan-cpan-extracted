package Template::Plugin::ResolveLink;

use strict;
our $VERSION = '0.01';

use base qw(Template::Plugin);
our $FILTER_NAME = 'resolve_link';

use HTML::ResolveLink;

sub new {
    my($class, $context, @args) = @_;
    my $name = $args[0] || $FILTER_NAME;
    $context->define_filter($name, $class->filter_factory());
    bless {}, $class;
}

sub filter_factory {
    my $class = shift;
    my $sub = sub {
        my($context, @args) = @_;
        my $config = ref $args[-1] eq 'HASH' ? pop(@args) : { };
        return sub {
            my $html = shift;
            my $resolver = HTML::ResolveLink->new(%$config);
            return $resolver->resolve($html);
        };
    };
    return [ $sub, 1 ];
}

1;
__END__

=head1 NAME

Template::Plugin::ResolveLink - Template plugin for HTML::ResolveLink

=head1 SYNOPSIS

  use Template::Plugin::ResolveLink;

  # in your template
  [% USE ResolveLink -%]
  [% FILTER resolve_link base = "http://www.example.com/base/" -%]
  <a href="foo.html"><img src="/bar.gif"></a>
  <a href="mailto:bar">foo</a>
  [% END %]

  # will become
  <a href="http://www.example.com/base/foo.html"><img src="http://www.example.com/bar.gif"></a>
  <a href="mailto:bar">foo</a>

=head1 DESCRIPTION

Template::Plugin::ResolveLink is a wrapper for HTML::ResolveLink to be
used in Template Toolkit templates.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::ResolveLink>

=cut
