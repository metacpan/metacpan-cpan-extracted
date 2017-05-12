package String::Iota;
use strict;
use warnings;

require Exporter;
our @EXPORT = qw(
	trim
);

our $VERSION = '0.85';

sub trim {
	my ($string, $pat) = @_;
	$string ||= $_;
	my @chars = split //, $string;
	return join "", @chars[0..--$pat];
}
	
sub strim {
	my ($string, $pat) = @_;
	$string ||= $_;
	$string   = scalar reverse $string;
	$string =~ s/.*${pat}(.*)/$1/;
	return scalar reverse $string;
}
	
sub dismantle {
	my $string = shift;
	return my @info = (length $string,  split //, $string );
}

1;

__END__

=head1 NAME

String::Iota - Simple interface to some useful string functions

=head1 SYNOPSIS

  use String::Iota;
  $str = "Just another perl hacker";
  print trim  $str, 4;   # Just
  print strim $str, 'p'; # Just another 
  @info = dismantle $str;
  print join ", ", @info; # 24, J, u, s, t,  , a, n, o, t, h, e, r,  , p, e, r, l,  , h, a, c, k, e, r
  
  open (FILE, "+<", "/test.txt");
  while (<FILE>) {
  	trim  $_, 40;  # Trim every line of test.txt to 40 characters
  	strim $_, "#"; # Get rid of comments
  }

=head1 DESCRIPTION

This module provides several simple, small and fast functions for processing strings. 

=head2 EXPORT

=head3 trim (i<$string>, i<$num>)
Trims a string to a certain length, specified by $num. 

=head3 strim (i<$string>, i<$delim>)
Trims a string to whatever is before another string, specified by $delim.

=head3 dismantle (i<$string>)
Returns an array; the first element is the length of $string, followed by each character of $string, one per element.

=head1 AUTHOR

Lincoln Ombelets, E<lt>ch.animalbar@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Lincoln Ombelets

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
