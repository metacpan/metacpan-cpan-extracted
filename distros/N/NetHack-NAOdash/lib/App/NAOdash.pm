package App::NAOdash;

use 5.014000;
use strict;
use warnings;
use re '/saa';
use utf8;

our $VERSION = '0.003';

use Encode qw/encode/;
use File::Slurp;
use NetHack::NAOdash;
use Term::ANSIColor ':constants';

my @order = qw/
achieve_sokoban achieve_luckstone achieve_medusa achieve_bell achieve_gehennom achieve_candelabrum achieve_book achieve_invocation achieve_amulet achieve_endgame achieve_astral achieve_ascended

combo_arc_hum_law combo_arc_hum_neu combo_arc_dwa_law combo_arc_gno_neu
combo_bar_hum_neu combo_bar_hum_cha combo_bar_orc_cha
combo_cav_hum_law combo_cav_hum_neu combo_cav_dwa_law combo_cav_gno_neu
combo_hea_hum_neu combo_hea_gno_neu
combo_kni_hum_law
combo_mon_hum_law combo_mon_hum_neu combo_mon_hum_cha
combo_pri_hum_law combo_pri_hum_neu combo_pri_hum_cha combo_pri_elf_cha
combo_ran_hum_neu combo_ran_hum_cha combo_ran_elf_cha combo_ran_gno_neu combo_ran_orc_cha
combo_rog_hum_cha combo_rog_orc_cha
combo_sam_hum_law
combo_tou_hum_neu
combo_val_hum_law combo_val_hum_neu combo_val_dwa_law
combo_wiz_hum_neu combo_wiz_hum_cha combo_wiz_elf_cha combo_wiz_gno_neu combo_wiz_orc_cha

conduct_foodless conduct_vegan conduct_vegetarian conduct_atheist conduct_weaponless conduct_pacifist conduct_illiterate conduct_genocideless conduct_polypileless conduct_polyselfless conduct_wishless conduct_artiwishless

uconduct_survivor uconduct_boneless uconduct_minscore/;

sub naodash_to_ansi {
	my ($dash) = @_;
	my @checks = @{$dash->{checks}};
	my %numbers = %{$dash->{numbers}};

	my $base = <<"EOF";
ACHIEVEMENTS
============
#Sokoban #Luckstone  #Medusa #Bell    #Gehennom #Candelabrum
#Book    #Invocation #Amulet #Endgame #Astral   #Ascended

STARTING COMBOS
===============
#Arc-Hum-Law #Arc-Hum-Neu #Arc-Dwa-Law #Arc-Gno-Neu
#Bar-Hum-Neu #Bar-Hum-Cha #Bar-Orc-Cha
#Cav-Hum-Law #Cav-Hum-Neu #Cav-Dwa-Law #Cav-Gno-Neu
#Hea-Hum-Neu #Hea-Gno-Neu
#Kni-Hum-Law
#Mon-Hum-Law #Mon-Hum-Neu #Mon-Hum-Cha
#Pri-Hum-Law #Pri-Hum-Neu #Pri-Hum-Cha #Pri-Elf-Cha
#Ran-Hum-Neu #Ran-Hum-Cha #Ran-Elf-Cha #Ran-Gno-Neu #Ran-Orc-Cha
#Rog-Hum-Cha #Rog-Orc-Cha
#Sam-Hum-Law
#Tou-Hum-Neu
#Val-Hum-Law #Val-Hum-Neu #Val-Dwa-Law
#Wiz-Hum-Neu #Wiz-Hum-Cha #Wiz-Elf-Cha #Wiz-Gno-Neu #Wiz-Orc-Cha

CONDUCTS
========
#Foodless     #Vegan        #Vegetarian #Atheist
#Weaponless   #Pacifist     #Illiterate #Genocideless
#Polypileless #Polyselfless #Wishless   #Artiwishless

UNOFFICIAL CONDUCTS
===================
#Survivor #Boneless #Minscore

NUMBERS
=======
Time played:   $numbers{totalrealtime}
Games:         $numbers{games}
Ascensions:    $numbers{ascensions}
Most HP:       $numbers{maxhp}
Most points:   $numbers{maxpoints}
Most conducts: $numbers{maxconducts}
Least turns:   $numbers{minturns}
Least time:    $numbers{minrealtime}
EOF

	my $rst = RESET;
	for my $check (@order) {
		my $color = (grep { $_ eq $check } @checks) ? GREEN UNDERLINE : RED;
		$base =~ s/#([a-zA-Z-]+)/$color$1$rst/;
	}
	$base =~ s/([A-Z ]+)\n=*/BOLD($1).RESET/ge;

	$base
}

sub run {
	my ($args, $user_or_path) = @_;
	my $stats;
	if ($user_or_path =~ /^\w+$/) { # Looks like a user
		$stats = naodash_user $args, $user_or_path
	} else {
		$stats = naodash_xlog $args, read_file $user_or_path
	}
	print encode 'UTF-8', naodash_to_ansi $stats ## no critic (RequireCheckedSyscalls)
}

1;
__END__

=encoding utf-8

=head1 NAME

App::NAOdash - Analyze NetHack xlogfiles and extract statistics (command-line interface)

=head1 SYNOPSIS

  use App::NAOdash;
  App::NAOdash::run(@ARGV);

=head1 DESCRIPTION

App::NAOdash is the backend of the L<naodash> script, a command-line
interface to L<NetHack::NAOdash>.

It defines two functions:

=over

=item B<naodash_to_ansi>(I<$stats>)

Takes the result of B<naodash_user> or B<naodash_xlog> and presents it
in a text form, using ANSI escape sequences to indicate the
presence/absence of checks.

=item B<run>(I<$user_or_path>)

Analyzes the xlogfile for the given user / at the given path, passes
the result through B<naodash_to_ansi> and prints the result.

If the argument contains non-word characters, it is interpreted as a
path. Otherwise it is interpreted as a NAO username.

=back

=head1 SEE ALSO

L<naodash>, L<NetHack::NAOdash>, L<App::Web::NAOdash>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
