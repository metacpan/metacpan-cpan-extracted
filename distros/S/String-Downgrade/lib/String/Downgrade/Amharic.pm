package String::Downgrade::Amharic;

# If either of these next two lines are inside
# the BEGIN block the package will break.
#
use utf8;
use Regexp::Ethiopic::Amharic qw(:forms overload setForm subForm);

BEGIN
{
	use strict;
	use base qw( Exporter );
	use vars qw( $VERSION @EXPORT %HaMaps );

	$VERSION = "0.03";

	@EXPORT = qw( &downgrade );

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
			my $to = subForm ( 'ሀ', $from );
			my $compliment = ( $from =~ /[#ኀ#]/ ) ? "ሐ" : "ኀ" ;
			$to .= subForm ( $compliment, $from );
			_downgradeMultiTarget ( \@list, \$re, $from, $to );
		}
		if ( /([ሐኀኃሓኻኍ])/ ) {
			my $to = $HaMaps{$1};
			_downgradeMultiTarget ( \@list, \$re, $1, $to );
		}
	}


	( @list, $re );
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

String::Downgrade::Amharic - Generate Acceptable Spellings from Canonical.

=head1 SYNOPSIS

  #
  #  OO Style:
  #
  use utf8;
  require String::Downgrade::Amharic;

  my $string = new String::Downgrade::Amharic;

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
  use String::Downgrade::Amharic;

  my @list = downgrade ( "እግዚአብሔር" );

  :
  :
  :

=head1 DESCRIPTION

Under the "three levels of Amharic spelling" theory, the
String::Downgrade::Amharic  package will take a canonical word (level one)
and generate level two words (the level of popular use).  The first member
of the returned array is the original string.  The last member of the returned
array is a regular expression that will match all renderings of the list.

The doc/index.html file presents a development of the downgrade rules applied.

The package is useful for some problems, it will produce orthographically
"legal" simplification and avoids improbable naive simplifications.
L<Text::Metaphone::Amharic> of course over simplifies as it addresses a
different problem.  So while not to promote level 2 orthographies, in some
instances it is useful to generate level 2 renderings given a canonical
form.

You I<must> start with the canonical spelling of a word as only downgrades
can occur.  Starting with a near canonical form and downgrading will generate
a shorter word list than you would have starting from the top.

=head1 REQUIRES

L<Regexp::Ethiopic> (which I<rules> btw).

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::Metaphone::Amharic>

=cut
