package String::Equivalence::Amharic;

# If either of these next two lines are inside
# the BEGIN block the package will break.
#
binmode(STDOUT, ":utf8");
use strict;
use warnings;
use utf8;
use Regexp::Ethiopic::Amharic qw(:forms overload setForm subForm %AmharicEquivalence);

BEGIN
{
	use base qw( Exporter );
	use vars qw( $VERSION @EXPORT %HaMaps );

	$VERSION = "0.06";

	@EXPORT = qw( &downgrade &inflate &isEquivalentTo &isReducible &hasEquivalence );

	%HaMaps =(
		ሐ	=> "ኀኃሀሃ",
		ኀ	=> "ሐኃሀሃ",
		ኃ	=> "ኀሐሀሃ",
		ሓ	=> "ሐኀኃሀሃ",
		ኻ	=> "ሀሃ",
		ኍ	=> "ኁሁሑ"
	);
}


sub new
{
	bless ( {}, shift );
}


sub _downgradeMultiTarget
{
my ( $list, $re, $from, $targets ) = @_;

	my @to = split ( //, $targets );
	my @outList = ();

	foreach my $to (@to) {
		my @newList;
		for (my $i=0; $i < @{$list}; $i++) {
			$newList[$i] = $list->[$i];     # copy old list
			$newList[$i] =~ s/$from/$to/;
		}
		push ( @outList, @newList );  # add new keys to old keys
	}
	push ( @{$list}, @outList );  # add new keys to old keys
	$$re =~ s/$from(?!\])/[$from$targets]/;
}


sub _downgrade
{
my ( $list, $re, $from, $to ) = @_;

	unless ( $to ) {
		$to = $from;
		$to =~ tr/ሀሃሗሠ-ሧኣእኧቍኵጕቈኰጐቆኮጎዑዒዔዕዖፀ-ፆኹኺኼኽኾ/ሃሀኋሰ-ሷአእቁኩጉቆኮጎቈኰጐዕኡኢኤእኦጸ-ጾሁሂሄህሆ/;
	}

	my @newList;
	for (my $i=0; $i < @{$list}; $i++) {
		$newList[$i] = $list->[$i];     # copy old list
		$newList[$i] =~ s/$from/$to/;
	}
	push ( @{$list}, @newList );  # add new keys to old keys
	$$re =~ s/$from(?!\])/[$from$to]/;
}


sub downgrade
{
my $self;

	($self, $_) = @_;
	$_ = $self unless ( ref($self) );

	my @list = ( $_ );
	my $re = $_;
	my @letters = split ( // );

	foreach ( @letters ) {
		if ( /([#ሠፀ#]|[ሀሃሗኣእኧቍኵጕቈኰጐቆኮጎዑዒዔዕዖኹኺኼኽኾ])/ ) {
			my $from = $1;
			_downgrade ( \@list, \$re, $from )
				unless ( $from eq "እ" && $re =~ /^እ/ );
		}
		if ( /([ዓዐ])/ ) {
			my $to = ( $1 eq "ዓ" ) ? "አዐ" : "አዓ" ;
			_downgradeMultiTarget ( \@list, \$re, $1, $to );
		}
		if ( /([ሑሒሔሕሖኁኂኄኅኆ])/ ) {
			my $from = $1;
			my $compliment = ( $from =~ /[#ኀ#]/ ) ? "ሐ" : "ኀ" ;
			my $to = subForm ( $compliment, $from ).subForm ( 'ሀ', $from );
			_downgradeMultiTarget ( \@list, \$re, $from, $to );
		}
		if ( /([ሐኀኃሓኻኍ])/ ) {
			my $to = $HaMaps{$1};
			_downgradeMultiTarget ( \@list, \$re, $1, $to );
		}
	}


	wantarray ? ( @list, $re ) : $list[$#list] ;
}


sub isReducible
{
my $self;

	($self, $_) = @_;
	$_ = $self unless ( ref($self) );

	/[#ሐኀሠዐፀ#]|[ቍኍኵጕቈኈኰጐ]/;

}


sub hasEquivalence
{
my $self;

	($self, $_) = @_;
	$_ = $self unless ( ref($self) );

	/[=#ሀሠዐፀ#=]|[=ቍ=]|[=ኍ=]|[=ኵ=]|[=ጕ=]|[=ቈ=]|[=ኈ=]|[=ኰ=]|[=ጐ=]/;
}


sub _inflate
{
my ($re, @words);

	foreach (@_) {
		$re = $_;
		$re =~ s/\[(\w+)\]/<replace>/;

		my @letters = split ( //, $1 );
		foreach ( @letters ) {
			push ( @words,$re );
			$words[ $#words ] =~ s/<replace>/$_/;
		}

	}

	if ( $words[0] =~ /\[/ ) {
		push ( @words, _inflate( @words ) );
		@words = grep { !/\[/ } @words;
	}
	
	return @words;
}


sub inflate
{
my $self;

	($self, $_) = @_;
	$_ = $self unless ( ref($self) );

	my @words = ( $_ );
	my $re = $_;

	my @letters = split ( // );

	foreach ( @letters ) {
		if ( $AmharicEquivalence{$_} ) {
			#
			# these next 3 lines are here to skip over old Amharic
			#
			my $equiv = $AmharicEquivalence{$_};
			$equiv =~ s/[#ኸ#]//g;
			$re =~ s/$_/[$equiv]/g;
			# $re =~ s/$_/[$AmharicEquivalence{$_}]/g;
		}
	}

	if ( $re =~ /\[/ ) {
		push ( @words, _inflate( $re ) );
		@words = grep { !/\[/ } @words;
		push ( @words, $re );
	}

	return @words;
}


sub isEquivalentTo
{
my ($self, $a, $b) = @_;

	unless ( ref($self) ) {
		$b = $a;
		$a = $self;
	}

	my @b = $self->inflate( $b );
	
	( $a =~ /^$b[$#b]$/ );
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__

=encoding utf8

=head1 NAME

String::Equivalence::Amharic - Normalization Utilities for Amharic.

=head1 SYNOPSIS

  #
  #  OO Style:
  #
  use utf8;
  require String::Equivalence::Amharic;

  my $string = new String::Equivalence::Amharic;

  my @list = $string->downgrade ( "እግዚአብሔር" );

  my $count = 0;
  foreach (@list) {
      $count++;
      print "$count: $_\n";
  }


  #
  #  Functional Style:
  #
  use utf8;
  use String::Equivalence::Amharic;

  my @list = downgrade ( "እግዚአብሔር" );

  :
  :
  :

=head1 DESCRIPTION

Under the "three levels of Amharic spelling" theory, the
String::Equivalence::Amharic  package will take a canonical word (level one)
and generate level two words (the level of popular use).  The first member
of the returned array is the original string.  The last member of the returned
array is a regular expression that will match all renderings of the list.

The doc/index.html file presents a development of the downgrade rules applied.

The package is useful for some problems, it will produce orthographically
"legal" simplification and avoids improbable naive simplifications.
L<Text::Metaphone::Amharic> of course over simplifies as it addresses a
different problem.  So, while not to promote level 2 orthographies, in some
instances it is useful to generate level 2 renderings given a canonical
form.

You I<must> start with the canonical spelling of a word as only downgrades
can occur.  Starting with a near canonical form and downgrading will generate
a shorter word list than you would have starting from the top.

=head2  Equivalence Utilities

=over 4

=item  downgrade ( $word )

Generates a list of the phonetically "decayed" written forms of the provided $word.

=item  isReducible ( $word )

Returns true if the provided $word can be reduced to an equivalent decayed form.

=item  hasEquivalence ( $word )

Returns true if a phonetically equivalent written form is possible for the provided $word.

=item  isEquivalentTo ( $wordA, $wordB )

Returns true if $wordA is phonetically equivalent to $wordB under Amharic rules.

=item  inflate ( $word )

Returns a list of all phonetically equivalent written forms of the provided $word.
The compliment to "downgrade".

=item getForm

A utility function to query the "form" of an Ethiopic syllable.  It
will return an integer between 1 and 12 corresponding to the [#\d+#]
classes.

  print getForm ( "አ" ), "\n";  # prints 1

=back

=head1 REQUIRES

L<Regexp::Ethiopic> (which I<rules> btw).

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Text::Metaphone::Amharic>

=cut
