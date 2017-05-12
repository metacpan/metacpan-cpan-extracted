package Taxon::Parse;

use strict;
use warnings;

our $VERSION = '0.013';

sub new {
  my $class = shift;
  my $self = {
      patterns => {},
      pattern_parts => {},
  };
  bless $self,$class;
  $self->init();
  return $self;
}

sub pattern {
  my $self = shift;
  my $pattern = shift;
  return $self->{patterns}->{$pattern} if exists $self->{patterns}->{$pattern};
}

sub pattern_parts {
  my $self = shift;
  my $pattern = shift;
  return $self->{pattern_parts}->{$pattern} if exists $self->{pattern_parts}->{$pattern};
}

sub patterns {
  my $self = shift;
  return $self->{patterns};
}

sub order {
  my $self = shift;
  my $pattern = shift;
  return $self->{order}->{$pattern} if exists $self->{order}->{$pattern};
}

sub match {
  my $self = shift;
  my $pattern = shift;
  my $string = shift;
  
  my $regex = $self->pattern($pattern);
  return $string =~ m/$regex/;
}

sub match_parts {
  my $self = shift;
  my $pattern = shift;
  my $string = shift;
  
  my $regex = $self->pattern_parts($pattern);
  return $string =~ m/$regex/;
}

sub check_parts {
  my $self = shift;
  my $pattern = shift;
  my $string = shift;
  
  my $regex = $self->pattern_parts($pattern);
  return $string =~ m/^$regex$/;
}


sub check {
  my $self = shift;
  my $pattern = shift;
  my $string = shift;
  
  my $regex = $self->pattern($pattern);
  return $string =~ m/^$regex$/;
}

sub pick {
  my $self = shift;
  my $pattern = shift;
  my $string = shift;
  
  my $regex = $self->pattern($pattern);
  my @result = $string =~ m/($regex)/g;
  return @result;
}

sub ast {
  my $self = shift;
  my $pattern = shift;
  my $string = shift;
  
  my $regex = $self->pattern($pattern);
  my $order = $self->order($pattern);
  my $result = [];
  {
     if ($string =~ m/^$regex$/) {
       for my $key (@$order) {
         push @$result,[ $key, $+{$key} ] if ($+{$key});
       }
     };
  }
  return $result;
}

sub init {
  my $self = shift;

  my $p = $self->{patterns};

  $p->{apostrophe} = qr/[\'´`]/xms;
  $p->{compound_connector} = qr/[-]/xms;

}


__END__

=head1 NAME

Taxon::Parse - Parse bio Taxon names

=for html
<a href="https://travis-ci.org/wollmers/Taxon-Parse"><img src="https://travis-ci.org/wollmers/Taxon-Parse.png" alt="Taxon-Parse"></a>
<a href='https://coveralls.io/r/wollmers/Taxon-Parse?branch=master'><img src='https://coveralls.io/repos/wollmers/Taxon-Parse/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

 use Taxon::Parse;
 Taxon::Parse->new();
 
=head1 DESCRIPTION

C<Taxon::Parse> is the base module providing utility methods for parsers.

=head1 METHODS


=head2 new

 my $object = Taxon::Parse->new();
 
=head2 pattern

 my $regex = $object->pattern($pattern_name);

=head2 pattern_parts

 my $regex = $object->pattern_parts($pattern_name);
 
=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Taxon-Parse>

=head1 AUTHOR

Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



1;
