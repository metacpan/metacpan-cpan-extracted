package Mojolicious::Plugin::Form;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Loader qw(data_section find_modules load_class);

our $VERSION = '0.006';

sub register {
  my ($self, $app, $conf) = @_;

  $conf ||= {};

  $app->helper(
    form_handler => sub {
      my $self       = shift;
      my $class_name = shift;

      $class_name ||= 'Default';
      my $namespace = ref($self->app) . '::Form::';

      unless ($class_name =~ m/[A-Z]/) {
        my $namespace = ref($self->app) . '::Form::';
        $namespace = '' if $namespace =~ m/^Mojolicious::Lite/;

        $class_name = join '' => $namespace,
          Mojo::ByteStream->new($class_name)->camelize;
      }

      $class_name = $namespace . $class_name;
      #my $e = Mojo::Loader->new->load($class_name);
      #my $e = Mojo::Loader->load_class($class_name);
      my $e = load_class($class_name);      

      Carp::croak qq/Can't load form '$class_name': / . $e->message
        if ref $e;

      Carp::croak qq/Can't find form '$class_name'/ if $e;

      #Carp::croak qq/Wrong form '$class_name' isa /.ref($self->app) . '::Form' 
      #  unless $class_name->isa(ref($self->app) . '::Form');

      return $class_name->new(%$conf, @_);
    }
  );
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Form - abstract forms for Mojolicious and DBIx::Class

=for html
<a href="https://travis-ci.org/wollmers/Mojolicious-Plugin-Form"><img src="https://travis-ci.org/wollmers/Mojolicious-Plugin-Form.png" alt="Mojolicious-Plugin-Form"></a>
<a href='https://coveralls.io/r/wollmers/Mojolicious-Plugin-Form?branch=master'><img src='https://coveralls.io/repos/wollmers/Mojolicious-Plugin-Form/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-Form'><img src='http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-Form.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Mojolicious-Plugin-Form"><img src="https://badge.fury.io/pl/Mojolicious-Plugin-Form.svg" alt="CPAN version" height="18"></a>


=head1 SYNOPSIS

 $app->plugin('Mojolicious::Plugin::Form');


=head1 DESCRIPTION

L<Mojolicious::Plugin::Form> is a Mojolicious-Plugin.


=head1 SEE ALSO

=over

=item *

L<Mojolicious>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Mojolicious-Plugin-Form>

=head1 AUTHOR

Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=for html
<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



