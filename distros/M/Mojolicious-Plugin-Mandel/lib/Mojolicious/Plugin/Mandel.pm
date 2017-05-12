package Mojolicious::Plugin::Mandel;
use Modern::Perl;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw(data_section find_modules load_class);

our $VERSION = '0.1.1'; # VERSION
# ABSTRACT: A plugin for mango document model called Mandel.


has mandels => sub { {} };


has mandel_documents => sub { [] };


sub register {
  my ($plugin, $app, $conf) = @_;
  for my $mandel_name (keys %$conf) {
    my $mandel_classes = $conf->{$mandel_name};
    for my $class (keys %$mandel_classes) {
      my $error = load_class($class);
      die $error if ref $error;
      my $obj = $class->connect($mandel_classes->{$class});
      my @docs = $obj->all_document_names;
      for my $doc_name (@docs) {
        my $fullname = "$mandel_name.$doc_name";
        push @{$plugin->mandel_documents}, $fullname;
        my $collection = $obj->collection($doc_name);
        if (defined $plugin->mandels->{$doc_name}) {
          $plugin->mandels->{$doc_name} = 0;
        } else {
          $plugin->mandels->{$doc_name} = $collection;
        }
        if (defined $plugin->mandels->{$fullname}) {
          die "$mandel_name.$doc_name seems exists";
        } else {
          $plugin->mandels->{$fullname} = $collection;
        }
      }
    }
  }
  $app->helper(
    mandel => sub {
      my ($self, $name) = @_;
      my $mandel;
      return $mandel if ($mandel = $plugin->mandels->{$name});
      my $message = "$name seems not exists in any mandel";
      $self->flash(message => $message);
      $self->app->log->fatal($message);
      die;
    }
  );
  $app->helper(
    mandel_documents => sub {
      @{$plugin->mandel_documents};
    }
  );
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Mandel - A plugin for mango document model called Mandel.

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

Mojolicious::Lite application:

  plugin Mandel => {
    a => {
      "Mandel::A" => "mongodb://localhost/test",
      "Mandel::B" => "mongodb://localhost/btest"
    },
  };

C<a> is the name of mandel that will be prefix of mandel
documents, C<Mandel::A> is the Mandel model name, the value
C<mongodb://localhost/test> is the MongoDB string URI.

Then you can call C<mandel>, C<mandel_document> in controller.

  # /
  any '/' => sub {
    my $c = shift;
    my $coll = $c->mandel("a.document");
    # or
    $coll = $c->mandel("document");
    $c->render(text => $coll->name);
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Mandel> is a Model (M in MVC architecture) for Mojolicious applications,
based on the L<Mandel> and L<Mango>.

=head1 HELPERS

The plugin generate two helpers:

=head2 mandel

Param: require one argument which should be one of the C<mandel_documents>.

=head2 mandel_documents

No params.

Return: an array of contained mandel document names.

=head1 ATTRIBUTES

=head2 mandels

Containing mandel document objects.

=head2 mandel_documents

Containing the mandel document names.

=head1 METHODS

=head2 register

The method to register plugin.

=head1 AUTHOR

Huo Linhe <huolinhe@berrygenomics.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Berry Genomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
