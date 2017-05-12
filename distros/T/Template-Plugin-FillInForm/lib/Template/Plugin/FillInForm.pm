package Template::Plugin::FillInForm;

use strict;
use vars qw($VERSION);
$VERSION = 0.04;

require Template::Plugin;
use base qw(Template::Plugin);

use vars qw($FILTER_NAME);
$FILTER_NAME = 'fillinform';

use HTML::FillInForm;

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
	    my $text = shift;
	    my $fif = HTML::FillInForm->new;
	    return $fif->fill(scalarref => \$text, %$config);
	};
    };
    return [ $sub, 1 ];
}

1;
__END__

=head1 NAME

Template::Plugin::FillInForm - TT plugin for HTML::FillInForm

=head1 SYNOPSIS

  use Template;
  use Apache;
  use Apache::Request;

  my $apr      = Apache::Request->new(Apache->request); # or CGI.pm will do
  my $template = Template->new( ... );
  $template->process($filename, { apr => $apr });

  # in your template
  [% USE FillInForm %]
  [% FILTER fillinform fobject => apr %]
  <!-- this form becomes sticky -->
  <form action="foo" method="POST">
  <input type="text" name="foo">
  <input type="hidden" name="bar">
  <input type="radio" name="baz" value="foo">
  <input type="radio" name="baz" value="bar">
  </form>
  [% END %]

=head1 DESCRIPTION

Template::Plugin::FillInForm is a plugin for TT, which allows you to
make your HTML form sticky using HTML::FillInForm.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<HTML::FillInForm>

=cut
