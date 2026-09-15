package inc::MyBuilder;

use strict;
use warnings;

use B 'perlstring';
use File::Spec;
use ExtUtils::Install;
use base 'Module::Build';
use File::Path 'mkpath';

sub ACTION_build {
	my $self = shift;
	
	$self->SUPER::ACTION_build(@_);
	
	my %notes = $self->notes;
	my $path_types = $notes{'path_types'};
	
	# Replace the copied module with its configured, installation-ready form.
	my $blib_spc = File::Spec->catfile($self->blib, 'lib', 'Sys', 'Path', 'SPc.pm');
	chmod(0644, $blib_spc);
	open(my $config_fh, '<', File::Spec->catfile('lib', 'Sys', 'Path', 'SPc.pm')) or die $!;
	open(my $blib_config_fh, '>', $blib_spc) or die $!;
	while (my $line = <$config_fh>) {
		next if ($line =~ m/# remove after install$/);
		if ($line =~ m/^sub \s+ ($path_types) \s* {/xms) {
			$line = 'sub '.$1.' {'.perlstring($notes{$1}).'};'."\n"
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

__END__

=head1 NAME

inc::MyBuilder - build and install Sys::Path directory constants

=head1 DESCRIPTION

This private L<Module::Build> subclass generates the installation-ready
C<Sys::Path::SPc> module and prepares its shared-state directory.

=head1 METHODS

=head2 ACTION_build

Run the parent build action, then regenerate the built C<Sys::Path::SPc> from
the source module. Lines ending in C<# remove after install> are omitted, and
each configured path accessor is replaced with a constant from the builder
notes. Path values are encoded as Perl string literals so quotes and
backslashes remain valid. The generated file is made read-only.

=head2 ACTION_install

Run the parent installation action, then create F<syspath> beneath the mapped
C<sharedstatedir> installation destination. This directory stores
F<install-checksums.json>. The destination matches the C<sharedstatedir>
selected during configuration.

=cut
