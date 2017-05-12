package Lingua::Stem::Snowball::Se;
use strict;
use bytes;
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Lingua::Stem::Snowball::Se - Swedish stemmer
# :: based upon the swedish stemmer algorithm at snowball.tartarus.org.
#	 by Martin Porter.
# (c) 2001-2007 Ask Solem Hoel <ask@0x61736b.net>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License version 2,
#   *NOT* "earlier versions", as published by the Free Software Foundation.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####


use vars qw($VERSION);
$VERSION = 1.2;

# special characters
my $ae = chr(0xe4); # a"
my $ao = chr(0xe5); # ao
my $oe = chr(0xf6); # o"

# delete the s if a "s ending" is preceeded by one
# of these characters.
my $s_ending = "bcdfghjklmnoprtvy";

# swedish vowels.
my $vowels = "aeiouy$ae$ao$oe";

# ####
# the endings in step 1
# XXX: these must be sorted by length
# to save time we've done it already, you can do it like this:
#	my $bylength = sub {
#		length $a <=> length $b;
#	}
#	@endings = reverse sort $bylength @endings;
my @endings = qw/
   heterna hetens ornas ernas andet heter arnas arens heten andes 
   anden orna erna erns arna ades aren aste arne ande ast het ens
   ern ade are er at es ad as en or ar e a s
/;

# the endings in step 2
# XXX: these must be sorted by length, like @endings in step 1.
my @endings2 = ('fullt', "l${oe}st", 'els', 'lig', 'ig');

my %cache = ( );

sub new {
	my $pkg = shift;
	$pkg = ref $pkg || $pkg;
	my %arg = @_;
	my $self = {};
	bless $self, $pkg;
	if($arg{use_cache}) {
		$self->use_cache(1);
	}
	return $self;
}

sub use_cache {
	my($self, $use_cache) = @_;
	if($use_cache) {
		$self->{USE_CACHE} = 1;
	}
	return $self->{USE_CACHE};
}

sub stem {
	my ($self, $word) = @_;
    no warnings;
	my $orig_word;

	if($self->use_cache()) {
		$orig_word = $word;
		my $cached_word = $cache{$word};
		return $cached_word if $cached_word;
	}

	my ($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
	return $word unless $lslen >= 3;

	# ### STEP 1
	# only need to refresh wlen each time we change the word.
	foreach my $ending (@endings)  {
		my $endinglen = length $ending; # do this once.

		# only continue if the word has this ending at all.
		if(substr($rs, $rslen - $endinglen, $rslen) eq $ending) {
			if($ending eq 's') { # b)
				# check if it has a valid "s ending"...
				my $valid_s_ending = 0;
				if($rslen == 1) {
					my $wmr1 = substr($word, 0, $wlen - $rslen);
					if($wmr1 =~ /[$s_ending]$/o) {
						$valid_s_ending = 1;
					}
				}
				else {
					if(substr($rs, $rslen - 2, $rslen - 1) =~ /[$s_ending]/o) {
						$valid_s_ending = 1;
					}
				}
				if($valid_s_ending) {
					# ...delete the last character (which is a s)
					$word = substr($word, 0, $wlen - 1);
					($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
					last;
				}
			}
			else { # a)
				# delete the ending.
				$word = substr($word, 0, $wlen - $endinglen);
				($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
				last;
			}
		}
	}
	return $word unless $lslen >= 3;

	# ### STEP 2
	my $ending = substr($rs, $rslen - 2, $rslen);
	if($ending =~ /dd|gd|nn|dt|gt|kt|tt/) {
		$word = substr($word, 0, $wlen - 1);
		($ls, $rs, $wlen, $lslen, $rslen) = getsides($word);
	}
	return $word unless $lslen >= 3;

	# ### STEP 3
	foreach my $ending (@endings2) {
		if($rs =~ /\Q$ending\E$/)
		{
			if($ending =~ /lig|ig|els/)
			{
				my $res = substr($word, 0, $wlen - length($ending));
				$word = $res; #if length $res > 2;
				last
			}
			if($ending eq "l${oe}st")
			{
				my $res = substr($word, 0, $wlen - 1);
				$word = $res; #if length $res > 2;
				last
			}
			if($ending eq 'fullt')
			{
				my $res = substr($word, 0, $wlen - 1);
				$word = $res; #if length $res > 2;
				last
			}
		}
	}

	if($self->use_cache()) {
		$cache{$orig_word} = $word;
	}
	
	return $word;
}

sub getsides {
    my $word = shift;
    no warnings;
    my $wlen = length $word;

    my($ls, $rs) = (undef, undef); # left side and right side.
	
    # ###
    # find the first vowel with a non-vowel after it.
    my($found_vowel, $nonv_position, $curpos) = (-1, -1, 0);
    foreach(split//, $word) {
        if($found_vowel> 0) {
			if(/[^$vowels]/o) {
				if($curpos > 0) {
				$nonv_position = $curpos + 1;
				last;
				}
			}
        }
        if(/[$vowels]/o) {
            $found_vowel = 1;
        }
        $curpos++;
    }

	# got nothing: return false
	return undef if $nonv_position < 0;

    # ###
    # length of the left side must be atleast 3 chars.
    my $leftlen = $wlen - ($wlen - $nonv_position);
    if($leftlen < 3) {
        $ls = substr($word, 0, 3);
        $rs = substr($word, 3, $wlen);
    }
    else {
        $ls = substr($word, 0, $leftlen);
        $rs = substr($word, $nonv_position, $wlen);
    }
    return($ls, $rs, $wlen, length $ls, length $rs);
}

1;

__END__

=head1 NAME

Lingua::Stem::Snowball::Se - Porters stemming algorithm for Swedish

=head1 VERSION

This document describes version 1.1.

=head1 SYNOPSIS

  use Lingua::Stem::Snowball::Se
  my $stemmer = new Lingua::Stem::Snowball::Se (use_cache => 1);

  foreach my $word (@words) {
	my $stemmed = $stemmer->stem($word);
	print $stemmed, "\n";
  }

=head1 DESCRIPTION

The stem function takes a scalar as a parameter and stems the word
according to Martin Porters Swedish stemming algorithm,
which can be found at the Snowball website: L<http://snowball.tartarus.org/>.

It also supports caching if you pass the use_cache option when constructing
a new L:S:S:S object.

=head2 EXPORT

Lingua::Stem::Snowball::Se has nothing to export.

=head1 AUTHOR

Ask Solem Hoel, E<lt>ask@0x61736b.netE<gt>

=head1 SEE ALSO

L<perl>. L<Lingua::Stem::Snowball>. L<Lingua::Stem>. L<http://snowball.tartarus.org>.

=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut
