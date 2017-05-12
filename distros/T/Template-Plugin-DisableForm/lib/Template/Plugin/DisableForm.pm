package Template::Plugin::DisableForm;
use strict;
use warnings;
use base qw(Template::Plugin::Filter);
use HTML::DisableForm;

our $VERSION = 0.01;

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}->[0] || 'disable_form');
    $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;
    my $df = HTML::DisableForm->new;
    return $df->disable_form(scalarref => \$text, %$config);
}

1;

__END__

=head1 NAME

Template::Plugin::DisableForm - TT plugin for HTML::DisableForm

=head1 SYNOPSIS

  my $template = Template->new;
  $template->process(\$html, { ... });

  # in your template
  [% USE DisableForm %]
  [% disable_form %]
  <!-- these form controlls will be disabled -->
  <form method="get">
  <input type="text" name="foo" />
  <input type="submit" name="bar" />
  </form>
  [% END %]

=head1 DESCRIPTION

TT plugin for HTML::DisableForm, which allows you to make your HTML
form controlls disabled.

=head1 METHODS

=head2 init

Intenal method for TT plugin

=head2 filter

Intenal method for TT plugin

=head1 AUTHOR

Naoya Ito, C<< <naoya at bloghackers.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Naoya Ito, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
