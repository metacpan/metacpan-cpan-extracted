use strict;
use warnings;
use OpenGL::Modern::Registry;
require './utils/common.pl';

=head1 PURPOSE

This script reads the function signatures from the registry
and creates XS stubs for each.

This should also autogenerate stub documentation by adding links
to the OpenGL documentation for each function via

L<https://www.opengl.org/sdk/docs/man/html/glShaderSource.xhtml>

=cut

our %signature;
*signature = \%OpenGL::Modern::Registry::registry;

=head1 Automagic Perlification

We should think about how to ideally enable the typemap
to automatically perlify the API. Or just handwrite
it for the _p functions?!

=cut

sub munge_GL_args {
    my ( @args ) = @_;

    # GLsizei n
    # GLsizei count
}

sub generate_glew_xs {
  my $content;
  for my $name (@_ ? @_ : sort keys %signature) {
    my $item = $signature{$name};
    if ( is_manual($name) ) {
      print "Skipping $name, already implemented in Modern.xs\n";
      next;
    }
    for my $s (bindings($name, $item)) {
      my $res = "$s->{xs_rettype}\n$s->{binding_name}($s->{xs_args})\n";
      $res .= $s->{xs_argdecls};
      $res .= "$s->{aliases}$s->{xs_code}  OGLM_GLEWINIT\n";
      $res .= "  $s->{error_check}\n" if $s->{error_check};
      $res .= $s->{avail_check} . $s->{beforecall};
      $res .= "  $s->{retcap}$name$s->{callarg_list};";
      $res .= "\n  $s->{error_check2}" if $s->{error_check2};
      $content .= "$res$s->{aftercall}$s->{retout}\n\n";
    }
  }
  return $content;
}

my $xs_code = generate_glew_xs(@ARGV);
save_file( 'auto-xs.inc', $xs_code );
