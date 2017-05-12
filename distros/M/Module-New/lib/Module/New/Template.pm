package Module::New::Template;

use strict;
use warnings;
use Text::MicroTemplate ();

# XXX: I'm still wondering if I should use Mojo::Template here...
my $ENGINE = Text::MicroTemplate->new(
  expression_mark => '=',
  line_start      => '%',
  tag_start       => '<%',
  tag_end         => '%>',
);

sub render {
  my ($self, $template) = @_;

  $template = '% my $c = shift;'."\n".$template;
  $ENGINE->parse($template)->build->(Module::New->context)->as_string;
}

1;

__END__

=head1 NAME

Module::New::Template

=head1 SYNOPSIS

  my $text = Module::New::Template->render('<% $c->module %>');

=head1 DESCRIPTION

As of 0.02, L<Module::New> uses a L<Mojo::Template>-like template engine. See L<Mojo::Template> for how to write templates.

=head1 METHOD

=head2 render

takes a template, and returns a rendered text. Note that C<$c> represents the Module::New context (which is passed to the template internally).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
