package Telugu::Utils;

use Mouse;
use Kavorka -all;
use utf8;
use Telugu::TGC;

our $VERSION = '0.04';


has 'tgc' => (
    is => 'ro',
    isa => 'Object',
    default => sub {
	my $tgc = Telugu::TGC->new();
	return $tgc;
    }
);


method ngram( Str $string, Int $n ) {
    my @filtered  = $self->tgc->TGC($string);

    my @ngram;
    foreach my $start ( 0 .. @filtered - $n ) {
	push @ngram, [ @filtered[ $start .. $start + $n - 1 ] ];
    }

    return @ngram;
}


1;

__END__
=encoding utf-8

=head1 NAME

Telugu::Utils - Utilities for Telugu strings.

=head1 SYNOPSIS

  use Telugu::Utils;
  use utf8;
  binmode STDOUT, ":encoding(UTF-8)";

  my $util = Telugu::Utils->new();
  my @ngrams = $util->ngram("రాజ్కుమార్రెడ్డి", 2);
  print $ngrams[1][0], "\n";


=head1 DESCRIPTION

Currently it provides one function, ngram. It takes two paramameters, first param must be a string and second param must be an integer.


=head1 AUTHOR

Rajkumar Reddy, mesg.raj@outlook.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
