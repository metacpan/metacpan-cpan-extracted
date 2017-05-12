package Movie::Info;

use strict;
use File::Which qw(where);

our $VERSION = "0.2";


=head1 NAME

Movie::Info -  get meta data from various format movie files

=head1 SYNOPSIS

	my $mi = Movie::Info->new || die "Couldn't find an mplayer to use\n";

	foreach my $file (@ARGV) {
		my %info = $mi->info($file) || warn "Couldn't read info from $file\n" && next;
		print "$file (WxH) - $info{width}x$info{height}\n"; 

	}

=head1 DESCRIPTION

C<Movie::Info> is a thin layer around B<MPlayer>'s C<--identify> command
line flag. As such it can only give you as much information as Mplayer 
is able to give you which is down to the quality and number of codecs 
you have installed.

MPlayer is available from http://www.mplayerhq.hu/

This module is largely based on the C<midentify> script shipped with 
MPlayer.

=cut

=head1 METHODS

=head2 new [path to mplayer]

Returns a new C<Movie::Info> instance or undef if it can't find an 
mplayer binary.

To find a binary it looks in three places - firstly if you've passed in 
a path to look at it checks there, secondly at the environment variable 
C<$MOVIE_INFO_MPLAYER_PATH> and then finally it searches your C<$PATH> 
like the standard C<which> command in Unix.

=cut


sub new {
	my $class   = shift;
	my $mplayer;

	my @where = where('mplayer');
	for my $cand ( ( shift, $ENV{MOVIE_INFO_MPLAYER_PATH}, @where ) ) {
		next unless defined $cand && -x $cand;
		$mplayer=$cand;
		last;
	}

	return undef unless defined $mplayer;


	BLESS:
	return bless { _mplayer_binary => $mplayer }, $class;
}


=head2 info <filename>

Returns a hash representing all the meta data we can garner about file.

Returns undef if it can't read the file. 

=cut

sub info {
	my $self = shift;
	my $file = shift || return undef;
	my %info;

	my $mplayer = $self->{_mplayer_binary};

	open(MPLAYER, "$mplayer -vo null -ao null -frames 0 -identify \"$file\" 2>/dev/null|") || die "Couldn't read from $mplayer: $!\n";
	while (<MPLAYER>) {
		next unless s/^ID_//;
		s/^VIDEO_//;
		chomp;
        s/(^\s*|\s*$)//g;
		s/([`\\!$"])/\\$1/g;
		my ($key, $value) = split /=/, $_, 2;
		$info{lc($key)} = $value;
			
	}
	#$info{filename} = $file;

	close MPLAYER;


	return %info;
}


=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Released under the same terms as Perl itself.

=cut

1;
