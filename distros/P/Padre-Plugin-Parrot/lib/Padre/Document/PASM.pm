package Padre::Document::PASM;
BEGIN {
  $Padre::Document::PASM::VERSION = '0.31';
}

# ABSTRACT: A PASM Document

use 5.008;
use strict;
use warnings;
use Padre::Document ();
use Padre::Util     ();

our @ISA     = 'Padre::Document';

# Slightly less naive way to parse and colorize pasm files

# still not working:
#  eq	I1,31,done
#	lt	P0,2,is_one
#	mul	P0,P0,I2

sub colorize {
	my ( $self, $first ) = @_;

	my $doc = Padre::Current->document;
	$doc->remove_color;

	my $editor = $doc->editor;
	my $text   = $doc->text_get;

	my @keywords = qw(substr save print branch new set end
		sub abs gt lt eq shift get_params if
		getstdin getstdout readline bsr inc
		push dec mul pop ret sweepoff trace
		restore ge le);
	my $keywords = join '|', sort { length $b <=> length $a } @keywords;

	#	my %regex_of = (
	#		PASM_KEYWORD  => qr/$keywords/,
	#		PASM_REGISTER => qr/\$?[ISPN]\d+/,
	#		PASM_LABEL    => qr/^\s*\w*:/m,
	#		PASM_STRING   => qr/(['"]).*\1/,
	#		PASM_COMMENT  => qr/#.*/,
	#	);

	my $in_pod;
	my @lines = split /\n/, $text;
	foreach my $i ( 0 .. @lines - 1 ) {
		next if $lines[$i] =~ /^\s$/;
		if ( $lines[$i] =~ /^\s*#/ ) {
			_color( $editor, 'Padre::Constant::PADRE_BLUE', $i, 0 );
			next;
		}
		if ( $lines[$i] =~ /^=/ or $in_pod ) {
			_color( $editor, 'Padre::Constant::PADRE_GREEN', $i, 0 );
			if ( $lines[$i] =~ /^=cut/ ) {
				$in_pod = 0;
			} else {
				$in_pod = 1;
			}
			next;
		}
		if ( $lines[$i] =~ /^\s*\w*:/m ) {
			_color( $editor, 'Padre::Constant::PADRE_GREEN', $i, 0 );
			next;
		}
		if ( $lines[$i] =~ /^\s*($keywords)\s*$/ ) { #   end
			_color( $editor, 'Padre::Constant::PADRE_BLUE', $i, 0 );
			next;
		}
		if ( $lines[$i] =~ /^\s*($keywords)\s*(([\'\"])[^\3]*\3|\$?[ISPN]\d+)\s*$/ ) { #   print "abc"
			my $keyword = $1;
			my $string  = $2;
			my $loc     = index( $lines[$i], $keyword );
			_color( $editor, 'Padre::Constant::PADRE_BLUE', $i, $loc, length($keyword) );
			my $loc2 = index( $lines[$i], $string, $loc + length($keyword) );
			if ( $string =~ /[\'\"]/ ) {
				_color( $editor, 'Padre::Constant::PADRE_ORANGE', $i, $loc2, length($string) );
			} else {
				_color( $editor, 'Padre::Constant::PADRE_MAGENTA', $i, $loc2, length($string) );
			}
			next;
		}
		if ( $lines[$i] =~ /^\s*($keywords)\s*(.*)$/ ) { # get_params "0", P0
			my $keyword = $1;
			my $other   = $2;

			my $loc = index( $lines[$i], $keyword );
			_color( $editor, 'Padre::Constant::PADRE_BLUE', $i, $loc, length($keyword) );

			my ( $first, $second ) = split /,/, $other, 2; # breaks if string is the first element
			my $endloc2 = gg( $editor, $first, $i, $lines[$i], $loc + length($keyword) );
			if ( not defined $endloc2 ) {

				# warn
				next;
			}
			gg( $editor, $second, $i, $lines[$i], $endloc2 );

			next;
		}

	}

}

sub gg {
	my ( $editor, $str, $i, $line, $loc ) = @_;
	if ( not defined $str ) {

		#warn $line;
		return;
	}
	if ( $str =~ /^\s*(\$?[ISPN]\d+)\s*$/ ) {
		my $substr = $1;
		my $loc2 = index( $line, $substr, $loc );
		_color( $editor, 'Padre::Constant::PADRE_BLUE', $i, $loc2, length($substr) );
		return $loc2 + length($substr);
	} elsif ( $str =~ /^\s*(([\'\"])[^\2]*\2)\s*$/ ) {
		my $substr = $1;
		my $loc2 = index( $line, $substr, $loc );
		_color( $editor, 'Padre::Constant::PADRE_BLUE', $i, $loc2, length($substr) );
		return $loc2 + length($substr);
	} elsif ( $str =~ /^\s*(\w\w*)\s*$/ ) {
		my $substr = $1;
		my $loc2 = index( $line, $substr, $loc );
		_color( $editor, 'Padre::Constant::PADRE_BROWN', $i, $loc2, length($substr) );
		return $loc2 + length($substr);
	}
	return;
}

sub _color {
	my ( $editor, $color, $line, $offset, $length ) = @_;

	#print "C: $color\n";
	my $start = $editor->PositionFromLine($line) + $offset;
	if ( not defined $length ) {
		$length = $editor->GetLineEndPosition($line) - $start;
	}

	no strict "refs"; ## no critic
	$editor->StartStyling( $start, $color->() );
	$editor->SetStyling( $length, $color->() );
	return;
}

sub get_command {
	my $self = shift;

	my $filename = $self->filename;

	if ( not $ENV{PARROT_DIR} ) {
		die "PARROT_DIR is not defined. Need to point to trunk of Parrot SVN checkout.\n";
	}
	my $parrot = File::Spec->catfile( $ENV{PARROT_DIR}, 'parrot' );
	if ( not -x $parrot ) {
		die "$parrot is not an executable.\n";
	}

	return qq{"$parrot" "$filename"};

}

sub comment_lines_str {
	return '#';
}

1;
__END__
=pod

=head1 NAME

Padre::Document::PASM - A PASM Document

=head1 VERSION

version 0.31

=head1 AUTHORS

=over 4

=item *

Gabor Szabo L<http://szabgab.com/>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

