package Perl6::Variables;
$VERSION = '0.01'; 
use Filter::Simple;

my $ident = qr/ [_a-z] \w* (?: :: [_a-z] \w* )* /ix;
my $listlikely = qr/ (?: \.\. | => | , | qw | \@ $ident \b [^[] ) /x;
my $alist = qr/ [^]]* $listlikely /x;
my $hlist = qr/ [^}]* $listlikely /x;

FILTER {
	$DB::single=1;
    my $text = "";
    pos = 0;
    while (pos($_)<length($_)) {
	m/\G \$ ($ident) \.? \[ (?=$alist) /sxgc and
		$text .= qq/\@{\$$1}[/ and next;
	m/\G \$ ($ident) \.? \[ (?!$alist) /sxgc and
		$text .= qq/\$$1\->[/ and next;
	m/\G \$ ($ident) \.? \{ (?=$hlist) /sxgc and
		$text .= qq/\@{\$$1}{/ and next;
	m/\G \$ ($ident) \.? \{ (?!$hlist) /sxgc and
		$text .= qq/\$$1\->{/ and next;
	m/\G \@ ($ident) \[ (?=$alist) /sxgc and
		$text .= qq/\@$1\[/ and next;
	m/\G \@ ($ident) \[ (?!$alist) /sxgc and
		$text .= qq/\$$1\[/ and next;
	m/\G \% ($ident) \{ (?=$hlist) /sxgc and
		$text .= qq/\@$1\{/ and next;
	m/\G \% ($ident) \{ (?!$hlist) /sxgc and
		$text .= qq/\$$1\{/ and next;
	m/\G ([^\$\@%]+|.) /xgcs and
		$text .= $1;
    }
    $_ = $text . substr($_,pos);
};

__END__

=head1 NAME

Perl6::Variables - Perl 6 variable syntax for Perl 5

=head1 VERSION

This document describes version 0.01 of Perl6::Variables,
released May 17, 2001.

=head1 SYNOPSIS

	use Perl6::Variables;

	sub show { print @_[0], @_[1..$#_], "\n" }

	my %hash  = (a=>1, b=>2, z=>26);
	my @array = (0..10);

	my $arrayref = \@array;
	my $hashref = \%hash;

	show %hash;
	show @array;
	show $hashref;
	show $arrayref;

	show %hash{a};
	show %hash{a=>'b'};
	show %hash{'a','z'};
	show %hash{qw(a z)};

	show @array[1];
	show @array[1..3];
	show @array[@array];

	show $hashref{a};
	show $hashref{a=>'b'};
	show $hashref{'a','z'};
	show $hashref.{qw(a z)};

	show $arrayref[1];
	show $arrayref[1..3];
	show $arrayref.[@array];

=head1 DESCRIPTION

The Perl6::Variables module lets you try out the new Perl variable access
syntax in Perl 5.

That syntax is:

        Access through...       Perl 5          Perl 6
        =================       ======          ======
        Scalar variable         $foo            $foo
        Array variable          $foo[$n]        @foo[$n]
        Hash variable           $foo{$k}        %foo{$k}
        Array reference         $foo->[$n]      $foo[$n] (or $foo.[$n])
        Hash reference          $foo->{$k}      $foo{$k} (or $foo.{$k})
        Code reference          $foo->(@a)      $foo(@a) (or $foo.(@a))
        Array slice             @foo[@ns]       @foo[@ns]
        Hash slice              @foo{@ks}       %foo{@ks}

	

=head1 DEPENDENCIES

The module is implemented using Filter::Simple
and requires that modules to be installed. 

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS

This module is not designed for serious implementation work.

It uses some very simple heuristics to translate Perl 6 syntax back to
Perl 5. It I<will> make mistakes, if you get even moderately tricky inside
a subscript.  It's only 20 lines long, for crying out loud.

Nevertheless, bug reports are most welcome.

=head1 COPYRIGHT

Copyright (c) 2001, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
