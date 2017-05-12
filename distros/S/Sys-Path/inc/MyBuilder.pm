package inc::MyBuilder;

use strict;
use warnings;

use File::Spec;
use ExtUtils::Install;
use base 'Module::Build';
use File::Path 'mkpath';

sub ACTION_build {
	my $self = shift;
	
	$self->SUPER::ACTION_build(@_);
	
	my %notes = $self->notes;
	my $path_types = $notes{'path_types'};
	
	# write the new version of SPc.pm
	my $blib_spc = File::Spec->catfile($self->blib, 'lib', 'Sys', 'Path', 'SPc.pm');
	chmod(0644, $blib_spc);
	open(my $config_fh, '<', File::Spec->catfile('lib', 'Sys', 'Path', 'SPc.pm')) or die $!;
	open(my $blib_config_fh, '>', $blib_spc) or die $!;
	while (my $line = <$config_fh>) {
		next if ($line =~ m/# remove after install$/);
		if ($line =~ m/^sub \s+ ($path_types) \s* {/xms) {
			$line = 'sub '.$1." {'".$notes{$1}."'};"."\n"
				if exists $notes{$1};
		}
		print $blib_config_fh $line;
	}
	close($blib_config_fh);
	close($config_fh);
	chmod(0444, $blib_spc);
		
	return;
}

sub ACTION_install {
	my $self = shift;
	my @args = @_;
	
	$self->SUPER::ACTION_install(@args);
	
	my $sharedstatedir = File::Spec->catdir(
		$self->install_map->{File::Spec->catdir('blib', 'sharedstatedir')},
		'syspath',
	);
	mkpath($sharedstatedir)
		if not -d $sharedstatedir;
}

1;
