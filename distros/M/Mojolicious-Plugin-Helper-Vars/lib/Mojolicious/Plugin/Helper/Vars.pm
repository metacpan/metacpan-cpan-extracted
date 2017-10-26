package Mojolicious::Plugin::Helper::Vars;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.0004';
my $pkg = __PACKAGE__;

=pod

=encoding utf8

Доброго всем

=head1 Mojolicious::Plugin::Helper::Vars

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head VERSION

0.0004

=head1 NAME

Mojolicious::Plugin::Helper::Vars - Stash & every_params to one var named.

=head1 SINOPSYS

    $app->plugin('Helper::Vars');
    
    # controller
    $c->param('foo'=>[1,2,3]);
    $foo = $c->vars('foo'); # 1
    
    $c->stash('foo'=>['undef']);
    $c->stash('Foo'=>5);
    @foo = $c->vars('foo', 'Foo'); # (1,2,3,undef,5)
    
    


=head1 OPTIONS

=over 4

=item * B<helper>

Name of the helper. Default - 'vars'.

Возвращает объединенный список stash & every_param и в скалярном контексте первое из определенных. String value 'undef' convert to undef.

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::ParamExpand>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche [on] cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-Helper-Vars/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016-2017 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#~ my $a;

sub register {
  my ($self, $app, $conf)  = @_;
  #~ $a = $app;
  my $helper = delete $conf->{helper} || 'vars';
  $app->helper($helper => sub {
    my $c = shift;
    my @vars;
    for (@_) {
      if (defined(my $stash = $c->stash($_))) {
        #~ warn "Stash [$_]:", $c->dumper($stash);
        if (ref($stash) eq 'ARRAY') {
          push @vars, map _val($_), @$stash;
        } else {
          push @vars, _val($stash);
        }
      }

      if (my $param = $c->req->params->every_param($_)) {
        #~ warn "Param [$_]:", $c->dumper($param);
        #~ if (ref($param) eq 'ARRAY') {
          push @vars, map _val($_), @$param;
        #~ } else {
          #~ push @vars, map $val->($param);
        #~ }
      }
    }
    return wantarray ? @vars : shift(@vars);
  });
  return $self;
}

sub _val {
  my $val = shift;
  return $val eq 'undef' || $val eq 'undefined' ? undef : $val;
}

1;