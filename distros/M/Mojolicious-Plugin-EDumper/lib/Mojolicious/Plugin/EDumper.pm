package Mojolicious::Plugin::EDumper;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.00007';

=pod

=encoding utf8


=head1 ¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

Доброго всем, соответственно

=head1 VERSION

0.00007

=head1 NAME

Mojolicious::Plugin::EDumper - pretty dumps encoded data.

=head1 SINOPSYS

    $app->plugin('EDumper');
    $app->plugin('EDumper', helper=>'dumper');
    
    $c->dumper( +{'Вася' => 'Пупкин'} );
    

=head1 OPTIONS

=head2 helper

Name of the helper. Default - 'edumper'.


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

Copyright 2016+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub register {
  my ($self, $app, $conf)  = @_;
  #~ my $enc = delete $conf->{enc} || 'utf8';
  my $helper = delete $conf->{helper} || 'edumper';
  $app->helper($helper => sub {
    shift;
      
      #~ my $dump = eval 'qq★'.
        Data::Dumper->new(\@_)->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(0)->Dump
          #~ .'★';
        =~ s/((?:\\x\{[\da-f]+\})+)/eval '"'.$1.'"'/eigr;
      
      #~ die __PACKAGE__." error: $@"
        #~ if $@;
      
      #~ return $dump;
      
  });
  return $self;
}

1;
