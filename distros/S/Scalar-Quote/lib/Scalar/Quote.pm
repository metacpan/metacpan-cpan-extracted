package Scalar::Quote;

our $VERSION = '0.26';

use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'quote' => [ qw( quote quote_number quote_cut quote_start ) ],
		     'diff' => [ qw( str_diff str_diffix ) ],
		     'short' => [ qw( Q N S D ) ] );
our @EXPORT_OK = (@{$EXPORT_TAGS{quote}},
		  @{$EXPORT_TAGS{diff}},
		  @{$EXPORT_TAGS{short}});
our @EXPORT = qw();

# converts a char to its hex representation
sub char_to_hex ($ ) {
  my $c=ord(shift);
  sprintf( ($c < 256 ? '\x%02x' : '\x{%x}'), $c);
}

my %esc = ( "\n" => '\n',
	    "\t" => '\t',
	    "\r" => '\r',
	    "\\" => '\\\\',
	    "\a" => '\a',
	    "\b" => '\b',
	    "\f" => '\f' );

sub escape_char($ ) {
    my $char=shift;
    exists $esc{$char} ? $esc{$char} : char_to_hex($char)
}

# converts unprintable chars to \x{XX} and also escapes '"' and '\' if
# required
sub Q ($ ) {
  my $s=shift;
  defined $s or return 'undef';
  if ($s=~s/([^!#&()*+,\-.\/0123456789:;<=>?ABCDEFGHIJKLMNOPQRSTUVWXYZ\[\]\^_`abcdefghijklmnopqrstuvwxyz{|}~ ])/escape_char($1)/ge) {
    return qq("$s");
  }
  return qq('$s');
}
*quote=\&Q;

# compares two strings and returns the position where they start to be
# diferent, i.e diffix('good morning', 'good afternoon') == 5

sub str_diffix ($$) {
  my ($a, $b)=@_;

  $a='' unless defined $a;
  $b='' unless defined $b;

  return -1 if $a eq $b;

  # my $c;
  # for (my $i=0;;$i++) {
  #   $c=substr($a,$i,1);
  #   return $i
  #     unless ( $c ne '' and $c eq substr($b,$i,1));
  # }

  my $la = length $a;
  my $lb = length $b;

  my $min = $la < $lb ? $la : $lb;

  my $c = substr($a, 0, $min) ^ substr($b, 0, $min);
  if ($c =~ m/[^\0]/g) {
      return pos($c) - 1;
  }
  return $min;
}

# quote_cut($string, $start, $len), like substr() but adds a head and a tail
# to the substring reported how many chars have been left alone. It
# also escapes the string.

sub quote_cut ($$$ ) {
    return 'undef' unless defined $_[0];
    my (undef, $start, $len)=@_;
    my $end=length($_[0])-$len-$start;
    if ($end<0) {
	$start+=$end;
	$end=0;
    }
    if ($start<0) {
	$start=0;
    }
    my $s=sprintf("[%d chars omitted]", $start);
    if (length $s>=$start) {
	$len+=$start;
	$start=0;
	$s='';
    }
    my $e=sprintf("[%d chars omitted]", $end);
    if (length $e>=$end) {
	$len+=$end;
	$e='';
    }
    quote($s.substr($_[0], $start, $len).$e);
}


# escape and quote string start operator, like Q but truncates the
# string if it is to long.
sub S ($;$ ) {
  my $len=defined $_[1] ? $_[1] : 32;
  quote_cut ($_[0], 0, $len);
}
*quote_start=\&S;

my $number_re=qr/^\s*[+-]?(?:\d+|\d*\.\d*)(?i:E[+-]?\d+)?\s*$/;

# quote number
sub N ($ ) {
  no warnings;
  if (defined $_[0]) {
    if ($_[0]=~/$number_re/o) {
      return sprintf("%f", $_[0]);
    }
    return sprintf("%f (str: %s)", $_[0], S($_[0]));
  }
  'undef'
}
*quote_number=\&N;

# D computes the difference between two strings.
sub D ($$;$$ ) {
    no warnings 'uninitialized';
    return () if $_[0] eq $_[1];

    my $len=defined $_[3] ? $_[3] : 32;
    my $start=(defined $_[2] ? $_[2] : -8)
	+ str_diffix($_[0], $_[1]);
    my $a=quote_cut($_[0], $start, $len);
    my $b=quote_cut($_[1], $start, $len);

    return ($a, $b) if (wantarray);

    {
	no strict 'refs';
	my $caller = caller;
	my $pa=$caller."::a";
	my $pb=$caller."::b";
	${$pa}=$a;
	${$pb}=$b;
    }
    return 1;
}
*str_diff=\&D;




1;
__END__

=head1 NAME

Scalar::Quote - Utility functions to quote Perl strings

=head1 SYNOPSIS

  use Scalar::Quote ':short';
  $_=pack('c',rand 127) for (@a[0..1000]);
  $s1=join '', @a;
  $_=pack('c',rand 127) for (@b[0..1000]);
  $s2=join '', @b;
  $_=pack('c',rand 127) for (@c[0..40]);
  $s3=join '', @c;

  print "Q(\$s1)=",Q($s1),"\n";
  print "S(\$a)=",S($a),"\n";
  D($s3.$s1, $s3.$s2);
  print "$a is not the same as $b\n";
  print N(0), N(1), N(undef), N("hello"), "\n";

=head1 ABSTRACT

Several subrutines to quote scalars and spot differences between strings.

Mostly useful for debugging purposes.

=head1 DESCRIPTION

=over 4

=item quote_number($n)

=item N($n)

quote C<$n> as a number.

=item quote($string)

=item Q($string)

returns the string conveniently enclosed in single or double quotes,
escaping unprintable and quoting chars as required.


=item quote_start($string)

=item S($string)

=item quote_start($string, $length)

=item S($string, $length)

quote the beginning of C<$string>.

=item quote_cut($str, $start, $len)

similar to C<substr($str, $start, $len)> but adds a head or/and a tail
to the substring stating how many chars have been left out.


=item str_diffix

returns the index where the two strings start to differ or -1 if they
are equal.


=item str_diff($s1, $s2)

=item str_diff($s1, $s2, $start, $len)

=item D($s1, $s2)

=item D($s1, $s2, $start, $len)

C<str_diff> compares two strings and creates quoted versions of them
around the place where they start to differ.

  D($s1, $s2) and print "$a is not the same as $b\n";

In scalar context the quoted strings are stored in globals C<$a> and
C<$b> on the caller package.

In list context the quoted strings are returned (C<$a> and C<$b> are
untouched).

When both strings are equal, undef or the empty list is returned.

Optional arguments C<$start> and C<$len> allow to configure the length
of the quoting. C<$start> is the location to start the quote *after*
the differences begin, so it should be a negative number.


=back

=head2 EXPORT

Nothing by default.

=head2 EXPORT_TAGS

=over 4

=item :quote

exports C<quote>, C<quote_start>, C<quote_cut> and C<quote_number>

=item :diff

exports C<str_diffix> and C<str_diff> subrutines.

=item : short

exports C<Q>, C<S>, C<N> and C<D>.


=back


=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2006 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
