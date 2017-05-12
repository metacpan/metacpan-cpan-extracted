package Template::Plugin::HTML::Template;

use strict;
use vars qw($VERSION $DYNAMIC $FILTER_NAME);
$VERSION = 0.02;

$DYNAMIC = 1;
$FILTER_NAME = 'html_template';

use HTML::Template;
use base qw(Template::Plugin::Filter);

sub init {
    my($self, $options) = @_;
    my $name = $self->{_ARGS}->[0] || $FILTER_NAME;
    $self->install_filter($name);
    $self->{_options} = $options;
    return $self;
}

sub filter {
    my($self, $text, $args, $options) = @_;
    my $template = HTML::Template->new(
	strict => 0,
	die_on_bad_params => 0,
	%{$self->{_options}},
	%$options,
	scalarref => \$text,
    );

    my $stash = $self->{_CONTEXT}->stash;
    my @params = map { ($_ => $stash->{ $_ }) } grep !/^[\._]/, keys %$stash;
    $template->param(@params);
    return $template->output;
}

1;
__END__

=head1 NAME

Template::Plugin::HTML::Template - HTML::Template filter in TT

=head1 SYNOPSIS

  my $tt = Template->new;
  $tt->process('html-template.tt', { myname => 'foo' });

  # html-template.tt
  [% USE HTML.Template %]
  [% FILTER html_template %]
  My name is <TMPL_VAR name=myname>
  [% END %]

  # HTML::Template parameters
  [% USE ht = HTML.Template(loop_context_vars = 1) %]
  [% FILTER $ht %]
  <TMPL_LOOP employee>
     <TMPL_IF __FIRST__>...</TMPL_IF>
  </TMPL_LOOP>
  [% END %]

=head1 DESCRIPTION

Template::Plugin::HTML::Template is a TT plugin to filter
HTML::Template templates. It might sound just silly, but it can be
handy when you want to reuse existent HTML::Template templates inside
TT.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

darren chamberlain <darren@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<HTML::Template>

=cut
