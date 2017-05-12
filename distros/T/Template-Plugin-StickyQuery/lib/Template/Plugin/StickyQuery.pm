package Template::Plugin::StickyQuery;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

require Template::Plugin::Filter;
use base qw(Template::Plugin::Filter);

use vars qw($DYNAMIC $FILTER_NAME);
$DYNAMIC = 1;
$FILTER_NAME = 'stickyquery';

use HTML::StickyQuery;

sub init {
    my $self = shift;
    my $name = $self->{_ARGS}->[0] || $FILTER_NAME;
    $self->install_filter($name);
    return $self;
}

sub filter {
    my($self, $text, $args, $config) = @_;
    my $sticky = HTML::StickyQuery->new(%$config);
    return $sticky->sticky(scalarref => \$text,
			   param => $config->{param});
}


1;
__END__

=head1 NAME

Template::Plugin::StickyQuery - TT plugin for HTML::StickyQuery

=head1 SYNOPSIS

  use Template;
  use Apache;
  use Apache::Request;

  my $apr      = Apache::Request->new(Apache->request); # or CGI.pm will do
  my $template = Template->new( ... );
  $template->process($filename, { apr => $apr });

  # in your template
  [% USE StickyQuery %]
  [% FILTER stickyquery param => apr %]
  <A HREF="go.cgi?page=&foo=&bar">go</A>
  [% END %]

=head1 DESCRIPTION

Template::Plugin::StickyQuery is a plugin for TT, which allows you to
make your HTML tag sticky using HTML::StickyQuery.

Special thanks to IKEBE Tomohiro.

=head1 AUTHOR

Hiroyuki Kobayasi E<lt>kobayasi@piano.gsE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<HTML::StickyQuery>

=cut
