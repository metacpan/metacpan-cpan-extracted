
package TeX::Hyphen::german;

=head1 NAME

TeX::Hyphen::german -- provides parsing routine for German patterns

=head1 SYNOPSIS

	use TeX::Hyphen;
	my $hyp = new TeX::Hyphen 'hyphen.tex', style => 'german';

	# and then follow documentation for TeX::Hyphen

=head1 DESCRIPTION

This file provides parsing routine for German patterns.

=cut

use vars qw( $LEFTMIN $RIGHTMIN $VERSION );
$VERSION = 0.121;
$LEFTMIN = 2;
$RIGHTMIN = 2;

# ######################################################
# TeX conversions done for Czech language, eg. \'a, \v r
#
my %BACKV = ( 'c' => 'è', 'd' => 'ï', 'e' => 'ì', 'l' => 'µ',
	'n' => 'ò', 'r' => 'ø', 's' => '¹', 't' => '»', 'z' => '¾',
	'C' => 'È', 'D' => 'Ï', 'E' => 'Ì', 'L' => '¥', 'N' => 'Ò',
	'R' => 'Ø', 'S' => '©', 'T' => '«', 'Z' => '®' );
my %BACKAP = ( 'a' => 'á', 'e' => 'é', 'i' => 'í', 'l' => 'å',
	'o' => 'ó', 'u' => 'ú', 'y' => 'ý', 'A' => 'Á', 'E' => 'É',
	'I' => 'Í', 'L' => 'Å', 'O' => 'Ó', 'U' => 'Ú', 'Y' => 'Ý');
sub cstolower {
	my $e = shift;
	$e =~ tr/[A-Z]ÁÄÈÏÉÌËÍÅ¥ÒÓÔÕÖØ©«ÚÙÛÜÝ¬®/[a-z]áäèïéìëíåµòóôõöø¹»úùûüý¼¾/;
	$e;
}
# German conversions
my %german_conv = (a => "ä", o => "ö", u => "ü", '3' => "ß",
		A => "Ä", O => "Ö", U => "Ü");


sub process_patterns {
	my ($line, $bothhyphen, $beginhyphen, $endhyphen, $hyphen) = @_;

	if ($line =~ /\\endgroup/) {
		return 0;
	}

	for (split /\s+/, $line) {
		next if $_ eq '';

		my $begin = 0;
		my $end = 0;

		$begin = 1 if s!^\.!!;
		$end = 1 if s!\.$!!;
		s!\\n\{([^\}]+)\}!$1!g;
		s!\"(aouAOU3)!$german_conv{$1}!eg;
		s!\\v\s+(.)!$BACKV{$1}!g;	# process the \v tag
		s!\\'(.)!$BACKAP{$1}!g;		# process the \' tag
		s!\^\^(..)!chr(hex($1))!eg;
					# convert things like ^^fc
		s!(\D)(?=\D)!${1}0!g;		# insert zeroes
		s!^(?=\D)!0!;		# and start with some digit
		
		($tag = $_) =~ s!\d!!g;		# get the string
		($value = $_) =~ s!\D!!g;	# and numbers apart
		$tag = cstolower($tag);		# convert to lowercase
			# (if we knew locales are fine everywhere,
			# we could use them)
	
		if ($begin and $end) {
			$bothhyphen->{$tag} = $value;
		} elsif ($begin) {
			$beginhyphen->{$tag} = $value;
		} elsif ($end) {
			$endhyphen->{$tag} = $value;
		} else {
			$hyphen->{$tag} = $value;
		}
	}

	return 1;
}

sub process_hyphenation {
	my ($line, $exception) = @_;

	if ($line =~ /\}/) {
		return 0;
	}

	local $_ = $line;

	s!\\v\s+(.)!$BACKV{$+}!g;
	s!\\'(.)!$BACKAP{$+}!g;

	($tag = $_) =~ s!-!!g;
	$tag = cstolower($tag);
	($value = '0' . $_) =~ s![^-](?=[^-])!0!g;
	$value =~ s![^-]-!1!g;
	$value =~ s![^01]!0!g;
	
	$exception->{$tag} = $value;

	1;
}

1;

