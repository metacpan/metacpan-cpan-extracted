package Mojolicious::Plugin::EDumper;

use Mojo::Base 'Mojolicious::Plugin';
use Encode qw(decode);
use Data::Recursive::Encode;

our $VERSION = '0.00003';

=pod

=encoding utf8

Доброго всем

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !


=head1 NAME

Mojolicious::Plugin::EDumper - pretty dumps encoded data.

=head1 SINOPSYS

    $app->plugin('EDumper');
    $app->plugin('EDumper', helper=>'dumper');
    $app->plugin('EDumper', helper=>'dumper', enc=>'cp777');
    
    $c->dumper( +{'Вася' => 'Пупкин'} );

=head1 OPTIONS

=over 4

=item * B<helper>

Name of the helper. Default - 'edumper'.

=item * B<enc>

Encoding. Default - 'utf8'.

=head1 SEE ALSO

L<Data::Dumper>
L<Data::Dumper::AutoEncode>
L<Data::Recursive::Encode>
L<Mojolicious::Plugin::DefaultHelpers>

Redefine might not work:

    sub Data::Dumper::qquote {
      my $s = shift;
      return "'$s'";
    }


=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche [on] cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-EDumper/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub register {
  my ($self, $app, $conf)  = @_;
  my $enc = delete $conf->{enc} || 'utf8';
  my $helper = delete $conf->{helper} || 'edumper';
  $app->helper($helper => sub {
    shift;
    decode $enc,
      Data::Dumper->new(Data::Recursive::Encode->encode($enc, \@_),)
      ->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(0)->Dump;
  });
  return $self;
}

1;