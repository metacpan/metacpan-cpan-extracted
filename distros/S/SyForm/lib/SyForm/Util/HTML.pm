package SyForm::Util::HTML;
BEGIN {
  $SyForm::Util::HTML::AUTHORITY = 'cpan:GETTY';
}
$SyForm::Util::HTML::VERSION = '0.103';
use strict;
use warnings;
use Exporter 'import';
use Clone 'clone';

our @EXPORT = qw(

  add_html_attr
  put_html_attr
  set_html_attr
  get_html_attr

);

sub add_html_attr {
  my ( $html_declare, %attrs ) = @_;
  return _add_or_put_html_attr($html_declare,0,%attrs);
}

sub put_html_attr {
  my ( $html_declare, %attrs ) = @_;
  return _add_or_put_html_attr($html_declare,1,%attrs);
}

sub _add_or_put_html_attr {
  my ( $html_declare, $add_put, %attrs ) = @_;
  my $clone = clone($html_declare);
  for my $key (keys %attrs) {
    my $current = _get_html_attr($clone,$key);
    if ($current) {
      my $new = join(" ",$add_put
        ? ( $attrs{$key},$current->[1] )
        : ( $current->[1],$attrs{$key} )
      );
      $current->[1] = $new;
    } else {
      $clone->attributes([
        @{$clone->attributes},
        [ $key, $attrs{$key} ],
      ]);
    }
  }
  return $clone;
}

sub set_html_attr {
  my ( $html_declare, %attrs ) = @_;
  my $clone = clone($html_declare);
  for my $key (keys %attrs) {
    my $current = _get_html_attr($clone,$key);
    if ($current) {
      $current->[1] = $attrs{$key};
    } else {
      $clone->attributes([
        @{$clone->attributes},
        [ $key, $attrs{$key} ],
      ]);
    }
  }
  return $clone;
}

sub get_html_attr {
  my ( $html_declare, @attrs ) = @_;
  my @values;
  for my $key (@attrs) {
    my $attr = _get_html_attr($html_declare, $key);
    push @values, defined $attr ? $attr->[1] : undef;
  }
  return wantarray ? @values : $values[0];
}

sub _get_html_attr {
  my ( $html_declare, $key ) = @_;
  for my $attr (@{$html_declare->attributes}) {
    return $attr if $attr->[0] eq $key;
  }
  return undef;
}

1;

__END__

=pod

=head1 NAME

SyForm::Util::HTML

=head1 VERSION

version 0.103

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
