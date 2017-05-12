package Template::Plugin::deJSON;

=head1 NAME

  Template::Plugin::DeJSON - de-JSONify a JSON string

=head1 SYNOPSIS

  [%
    USE deJSON;
    hash = deJSON.deJSON(json_string);
    FOREACH field=hash;
      field; field.value;
    END;
  %]

=head1 DESCRIPTION

Well, I needed this. I had JSON string things flying around between servers,
and passed into templates. (If you must know, objects were stringified using
JSON, and bit-shifted around the world.) It seemed to me I needed a plugin to
take those strings and turn them into something a bit more useful.

So it takes a JSON string, and gives you back a hash. Or me. It gives it back
to me. YMMV.

It also copes with JSON strings within JSON strings, returning a nice data
structure where the values themselves might be hashes. This is good. It means
keys don't get overwritten. Again, it works on my machine for what I want it
to do. YMM(again)V.

=cut

use strict;
use warnings;

use base 'Template::Plugin';

our $VERSION = 0.03;

sub new {
  my ($class, $context) = @_;
  bless { 
    _CONTEXT => $context, 
  }, $class;
}

sub _balance {
  my ($self, $string) = @_;
  my $index = 0; my (@opens, @closes);
  while ($index >= 0) {
    my $pos = index $string, '{', $index;
    last if $pos < 0;
    push @opens, $pos unless (substr($string, $pos - 1, 1) eq '\\');
    $index = $pos + 1;
  }
  $index = 0;
  while ($index >= 0) {
    my $pos = index $string, '}', $index;
    last if $pos < 0;
    push @closes, $pos unless (substr($string, $pos - 1, 1) eq '\\');
    $index = $pos + 1;
  }
  die "Unbalanced" unless scalar @opens == scalar @closes;
  my @stack = ([ shift(@opens), pop(@closes) ]);
  for my $start (reverse @opens) {
    my $brack = $closes[-1];
    for my $end (@closes) {
      $brack = $end if $end > $start;
    }
    @closes = grep { $_ ne $brack } @closes;
    push @stack, [ $start, $brack ];
  }
  return @stack;
}

sub _inflate {
  my ($self, $string) = @_;
  my @coords = $self->_balance($string);
  my $outer = shift @coords;
  my %all;
  my ($SPACER1, $SPACER2, $offset) = ('#!#_#mwk', 'mwk!__!__!', 0);
  for my $pos (@coords) {
    my $substr = substr $string, $pos->[0] + $offset, $pos->[1] - $pos->[0];
    $string =~ m/"(\w+)":\Q$substr/;
    my $name = $1;
    (my $info = $substr) =~ s/({|}|")//g;
    $all{$name} = { map { split /:/, $_ } split /,/, $info };
    (my $replace = $substr) =~ s/./=/g;
    $string =~ s/$substr/$replace/;
  }
  $string =~ s/({|}|")//g;
  return { map { split /:/, $_ } split /,/, $string }, { %all };
}

sub _structure {
  my ($self, $string) = @_;
  my ($master, $replaces) = $self->_inflate($string);
  for my $key (keys %$replaces) {
    for my $inner (keys %{ $replaces->{$key} }) {
      $replaces->{$key}->{$inner} = delete $replaces->{$inner}
        if $replaces->{$key}->{$inner} =~ m/=/;
    }
  }
  for my $key (keys %$master) {
    $master->{$key} = $replaces->{$key}
      if $master->{$key} =~ m/=/;
  }
  return $master;
}

sub deJSON {
  my ($self, $json)= @_;
  return $self->_structure($json);
}

=head1 BUGS

Yup.

It doesn't cope if you have curly braces in your strings. The next version
will cope with that, honest.

I tried using Text::Balanced, but it didn't do what I wanted, so I rolled my
own. Yes, I know there are better ways to do it, but I wrote it without
access to the interwebs to find out how to better solve this solved problem.
Leave me alone, alright?

=head1 AUTHOR

Stray Taoist E<lt>F<mwk@strayLALALAtoaster.co.uk>E<gt>

=head1 COPYRIGHT

Copyright (c) 2007 StrayTaoist

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 STUFF

 o things

=head1 THINGS

 o stuff

=cut

return qw/You drink your kawfee and I sip my tay/;
