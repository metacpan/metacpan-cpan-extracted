# vim: sts=3 sw=3 et
package Parse::CPAN::Whois;
use strict;
use warnings;

our $VERSION='0.02';

=head1 NAME

Parse::CPAN::Whois - Parse CPAN's authors/00whois.xml file

=head1 DESCRIPTION

CPAN has two author indices, "01mailrc.txt.gz", which L<Parse::CPAN::Authors> parses for you, and "00whois.xml", which is handled by this module.

It tries to be API-compatible with L<Parse::CPAN::Authors>, while providing
access to the extra information "00whois.xml" has over "01mailrc.txt.gz".

=cut

use XML::SAX::ParserFactory;
use Parse::CPAN::Whois::Author;

use base qw(XML::SAX::Base);

=head1 METHODS

=head2 new FILENAME|DATA

new() takes either a path or a scalar containing the data to parse
as an argument. It parses the data, and then returns an object you
can query for PAUSE ids.

=cut

sub new {
   my $class = shift;
   my $file = shift;

   $file = '00whois.xml' unless (defined $file);

   my $handler = $class->SUPER::new;
   my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
   if (substr ($file, 0, 1) eq '<') {
      $p->parse_string ($file);
   } else {
      $p->parse_file($file);
   }

   return delete $handler->{list};
}

=head2 author PAUSEID

returns the L<Parse::CPAN::Whois::Author> object that corresponds to
the PAUSE id.

=cut

sub author {
   my $self = shift;
   my $cpanid = shift;

   return $self->{uc($cpanid)}
}

=head2 authors

returns a list of L<Parse::CPAN::Whois::Author> objects.

=cut

sub authors {
   my $self = shift;

   return values %$self;
}


# below are the SAX2 methods used.


sub start_element {
   my $self = shift;
   my $elem = shift;

   if ($elem->{LocalName} eq 'cpan-whois') {
      $self->{list} = bless {}, 'Parse::CPAN::Whois';
   } elsif ($elem->{LocalName} eq 'cpanid') {
      $self->{tmp} = bless {}, 'Parse::CPAN::Whois::Author';
   } else {
      $self->{key} = $elem->{LocalName};
      $self->{value} = '';
   }
}

sub characters {
   my $self = shift;
   my $data = shift;

   if (defined $self->{value}) {
      $self->{value} .= $data->{Data};
   }
}

sub end_element {
   my $self = shift;
   my $elem = shift;

   if ($elem->{LocalName} eq 'cpan-whois') {
   } elsif ($elem->{LocalName} eq 'cpanid') {
      my $id = $self->{tmp}->{id};
      my $foo = delete $self->{tmp};
      if ($foo->{type} eq 'author') {
         $self->{list}->{$id} = $foo;
      }
   } else {
      $self->{tmp}->{delete $self->{key}} = delete $self->{value};
   }
}

1;

__END__

=head1 SEE ALSO

L<Parse::CPAN::Authors>

=head1 AUTHOR

Martijn van Beers  <martijn@cpan.org>

=head1 LICENSE

Copyright (c) 2008, Martijn van Beers

This module is free software; you can redistribute it or modify it under
the GPL, version 2 or higher. See the LICENSE file for details.

