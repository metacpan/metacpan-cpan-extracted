package Mojolicious::Plugin::JavaScript::Console;

# ABSTRACT: use the JavaScript console from Mojolicious applications

use strict;
use warnings;

use Mojo::Base qw(Mojolicious::Plugin);
use JavaScript::Console;

our $VERSION = 0.02;

sub register {
    my ($plugin, $mojo, $param) = @_;

    my $console = JavaScript::Console->new( %{ $param || {} } );

    $mojo->helper(
        'console' => sub {
            $console;
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::JavaScript::Console - use the JavaScript console from Mojolicious applications

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Mojolicious::Lite;
  
  plugin 'JavaScript::Console';
  
  get '/' => sub {
      my $self = shift;
      $self->console->group( 'start' );
      $self->console->log( 'logging with JavaScript::Console' );
      $self->console->warn( 'this is for $foo #25' );
      $self->console->group_end;
  
      $self->console->dir_by_id( 'test' );
  
      $self->render( 
          'index', 
      );
  };
  
  app->start;
  
  __DATA__
  @@ index.html.ep
  <div id="test"><h2>JavaScript::Console</h2></div>
  Please open a JavaScript console
  <%= Mojo::ByteStream->new( console()->output ) %>

=head1 DESCRIPTION

C<Mojolicious::Plugin::JavaScript::Console> is a simple plugin to print
debug output to a javascript console.

=head1 METHODS

=head2 register

  # in Mojolicious
  sub format_output {
      return JSON::XS->new->encode( shift );
  }
  
  $app->plugin(
    'JavaScript::Console' => {
      charset   => 'utf-8',
      formatter => \&format_output,
    },
  );

  # in Mojolicious::Lite
  plugin 'JavaScript::Console' => {
    charset   => 'utf-8',
    formatter => \&format_output,
  };

=head1 HELPERS

=head2 console

  my $console = $c->console;
  $c->console->log( 'Logging output' );

returns a C<JavaScript::Console> object.

=head1 REPOSITORY

  http://github.com/reneeb/Mojolicious-Plugin-JavaScript-Console

=head1 DEPENDENCIES

=over 4

=item * Mojolicious

=item * JavaScript::Console

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
