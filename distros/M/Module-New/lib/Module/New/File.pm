package Module::New::File;

use strict;
use warnings;
use Carp;
use Module::New::Meta;

my %stash;

functions {
  file => sub ($$) {
    my ($name, $content) = @_;
    $stash{$name} = sub { $content->(@_) };
  },

  content => sub (&) { return shift },
};

methods {
  render => sub {
    my $class = shift;
    my $context = Module::New->context;

    my %hash;
    while ( my ($path, $content) = each %stash ) {
      while ( my ($name) = $path =~ /\{([A-Z_]+)\}/ ) {
        my $method = $context->can(lc $name);
        my $value  = $method ? $context->$method : '';
        $path =~ s/\{$name\}/$value/g;
      }

      # for backward compatibility
      my $template = $content->( $context );

      $hash{$path} = $context->template->render( $template );
    }
    %stash = ();
    return %hash;
  },
};

1;

__END__

=head1 NAME

Module::New::File

=head1 SYNOPSIS

  package Your::Module::New::File::Something;
  use Module::New::File;

  file '{MAINFILE}' => content { return <<'TEMPLATE';
  # following is a Mojo-like template for a module.
  package <%= $c->module %>;
  use strict;
  use warnings;
  sub new { bless {}, shift; }
  1;
  TEMPLATE
  };

=head1 FUNCTIONS TO DEFINE FILES

=head2 file

specifies the relative path of a file to create. C<{MAINFILE}> becomes C<lib/Path/To/Module.pm> you specified as a command line argument, and C<{MAINDIR}> becomes C<lib/Path/To/Module>.

=head2 content

just a syntax sugar of C<sub { }>. The subroutine takes a context object, and should return a scalar text. Of course you can freely use template engines (you might want to extend the context to hold a template engine object to reuse). As of 0.02, L<Module::New> uses L<Text::MicroTemplate>, a fork of L<Mojo::Template> by default.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
