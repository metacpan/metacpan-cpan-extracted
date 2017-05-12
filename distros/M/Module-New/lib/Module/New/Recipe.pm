package Module::New::Recipe;

use strict;
use warnings;
use Carp;
use Module::New::Meta;
use Module::New::Queue;

my @options;

functions {
  flow => sub (&) {
    my $flow = shift;
    Module::New::Queue->register(sub {
      my ($self, @args) = @_;
      Module::New::Queue->localize(sub {
        $flow->();
        Module::New::Queue->consume( $self, @args );
      })
    })
  },

  loop => sub (&) {
    my $loop = shift;
    Module::New::Queue->register(sub {
      my ($self, @args) = @_;
      Module::New::Queue->localize(sub {
        $loop->();
        foreach my $arg ( @args ) {
          Module::New::Queue->consume( $self, $arg );
        }
      });
    });
  },

  available_options => sub (@) { @options = @_ },
};

methods {
  options => sub { @options },

  run => sub {
    my ($self, @args) = @_;
    Module::New::Queue->consume( $self, @args );
  }
};

1;

__END__

=head1 NAME

Module::New::Recipe

=head1 SYNOPSIS

  package Your::Module::New::Recipe::Something;
  use strict;
  use warnings;
  use Module::New::Recipe;
  use Module::New::Command::Basic;

  available_options ();

  flow {
    guess_root;

    loop {
      do_something;
    };
  };

  1;

=head1 DESCRIPTION

This is a base class which provides basic DSLish commands to define recipes. See also L<Module::New::Command::Basic>.

=head1 FUNCTIONS TO DEFINE RECIPES

=head2 available_options

defines command line option specifications which will be passed to L<Getopt::Long::Parser>.

=head2 flow

defines a recipe/command flow. All the commands in the flow would take $self and all the arguments passed through the command line.

=head2 loop

defines an internal loop. All the commands in the loop would take $self and an argument per iteration.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
