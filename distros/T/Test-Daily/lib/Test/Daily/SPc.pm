package Test::Daily::SPc;

=head1 NAME

Test::Daily::SPc - build-time system path configuration

=cut

use warnings;
use strict;

our $VERSION = '0.02';

use File::Spec;

sub _path_types {qw(
	sysconfdir
	datadir
	webdir
)};

=head1 PATHS

=head2 prefix

=head2 sysconfdir

=head2 datadir

=head2 webdir

=cut

sub prefix     { use Module::Build::SysPath; Module::Build::SysPath->find_distribution_root(__PACKAGE__); };
sub sysconfdir { File::Spec->catdir(__PACKAGE__->prefix, 'conf') };
sub datadir    { File::Spec->catdir(__PACKAGE__->prefix, 'share') };
sub webdir     { File::Spec->catdir(__PACKAGE__->prefix, 'www') };

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
