package Railsish::TextHelpers;
our $VERSION = '0.21';

use strict;
use warnings;
use Exporter::Lite;

our @EXPORT = qw( pluralize singularize camelize camelcase underscore dasherize forien_key );

use Lingua::EN::Inflect::Number qw(to_S to_PL);

sub pluralize { &to_PL }
sub singularize { &to_S }

use String::CamelCase qw(camelize decamelize);

sub camelcase { &camelize }
sub underscore { &decamelize }

sub dasherize {
  my $str = &decamelize;
  $str =~ s/_/-/g;
  return $str;
}

sub forien_key {
  my $str = &decamelize;
  $str =~ s/(?!_id)$/_id/;
  return $str;
}

1;


__END__
=head1 NAME

Railsish::TextHelpers

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

