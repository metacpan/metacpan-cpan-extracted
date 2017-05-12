#!/usr/bin/perl -w

use Getopt::Std;
use File::Basename;
use File::Copy;

sub usage();

getopts('hr:l:') or usage;
usage if (defined($Getopt::Std::opt_h) or defined($Getopt::Std::opt_h) or @ARGV != 1);

my $sVVoiceRoot = (defined($Getopt::Std::opt_r) ? $Getopt::Std::opt_r : '/usr/lib/ViaVoice');
my $locale = (defined($Getopt::Std::opt_l) ? $Getopt::Std::opt_l : 'En_US');
my $buildpol = $sVVoiceRoot . '/bin/buildpol';

my $words = shift @ARGV;
my $bname = basename($words, ('.words'));
open WORDS, $words or die "cannot open $words";
my @words = <WORDS>;
close WORDS;

# create words list for buildpol
my ($lst, $pbsp) = ($bname . '.lst', $bname . '.pbsp');
open LST, '>' . $lst or die "cannot create $lst";
open PBSP, '>' . $pbsp or die "cannot create $pbsp";
for (@words) {
	if (m/^\s*(\S.*?)\t\s*([a-zA-Z].*)/) {
		my ($word, $phonetic) = ($1, $2);
		printf LST "%s\n", ($word =~ m/\S\s\S/ ? "'$word'" : $word);
		printf PBSP "%s\t%s\n", ($word =~ m/\S\s\S/ ? "'$word'" : $word), $phonetic;
	}
}
close LST;
close PBSP;

# create .pol file
my $pol = $bname . '.pol';
open POL, '>' . $pol or die "cannot create $pol";

print POL "Standard_Baseforms:\n"
			. "\tPhone-Type = Phonetic\n"
			. "\tAcoustic-ID = genDus\n"
			. "\tTranslations = /usr/lib/ViaVoice/vocabs/langs/En_US/models\n"
			. "\tWord-Lists = $lst\n"
			. "\tBaseform-Files = $pbsp\n"
			. "\tFile-Prefix = $bname\n"
			. "\tBaseforms = $bname.pbc\n"
			. "\tOffsets = $bname.bof\n"
			. "\tSpellings = $bname.spe\n"
			. "\tPrints-like Offsets = $bname.pof\n";
close POL;

# run buildpol
system $buildpol, $pol;

my ($pbc, $pof, $spe, $bof) = ("$bname.pbc", "$bname.pof", "$bname.spe", "$bname.bof");

# move files to $sVVoiceRoot/vocabs/langs/$locale/pools/
my $poolDir = "$sVVoiceRoot/vocabs/langs/$locale/pools";
printf "moving pronunciation files to %s/\n", $poolDir;
move($pol, $poolDir) or print STDERR "could not move $pol to $poolDir/\n";
move($pbc, $poolDir) or print STDERR "could not move $pbc to $poolDir/\n";
move($pof, $poolDir) or print STDERR "could not move $pof to $poolDir/\n";
move($spe, $poolDir) or print STDERR "could not move $spe to $poolDir/\n";
move($bof, $poolDir) or print STDERR "could not move $bof to $poolDir/\n";

unlink($pbsp);
unlink($lst);

exit(0);

# done




#-----------------------------------------------------------------------
# subroutines

sub usage()
{
	my $prog = basename $0;
	printf STDERR "\n";
	printf STDERR "usage: %s [-r <ViaVoiceRootDir>] [-l <locale>] <words-file>\n", $prog;
	printf STDERR "       -r default = /usr/lib/ViaVoice\n"
				. "       -l default = En_US\n"
				. "       <words-file> has lines like:\n\n"
				. "          word-or-phrase<  1 or more Tab chars  ><phonetic pronunciation>\n\n"
				. "       A description of the <phonetic pronunciation> field can be found in\n"
				. "       the ViaVoice documentation (section 3 in /usr/doc/ViaVoice/bpreadme.txt)\n\n";
	exit 1;
}
