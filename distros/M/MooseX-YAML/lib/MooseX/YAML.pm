#!/usr/bin/perl

package MooseX::YAML;

use strict;
use warnings;

our $VERSION = "0.04";

use Carp qw(croak);

use MooseX::Blessed::Reconstruct;

my $v;
sub fixup { ($v ||= MooseX::Blessed::Reconstruct->new)->visit(@_) }

use namespace::clean;

use Sub::Exporter -setup => {
	exports => [qw(Load LoadFile)],
	collectors => [ "-xs", "-syck", "-pp" ],
	generator => sub {
		foreach my $export ( @_ ) {
			my $r = $export->{class}->_resolve($export->{name}, $export->{col});
			return sub { fixup( $r->(@_) ) };
		}
	},
};

sub _resolve {
	my ( $class, $routine, $flags ) = @_;

	if ( keys %$flags ) {
		croak "Can't use more than one of -xs, -syck or -pp" if keys %$flags > 1;

		if ( exists $flags->{-xs} ) {
			require YAML::XS;
			return YAML::XS->can($routine);
		} elsif ( exists $flags->{-syck} ) {
			require YAML::Syck;
			return YAML::Syck->can($routine);
		} else {
			require YAML;
			return YAML->can($routine);
		}
	} else {
		my $drv = (
			do { local $@; eval { require YAML::XS; "YAML::XS" } }
				or
			require YAML && "YAML"
		);
		
		return $drv->can($routine) || croak "Can't find a provided for $routine (fallback is $drv)";
	}
}

my $load;
sub Load {
    $load ||= __PACKAGE__->_resolve("Load");
    fixup( $load->(@_) );
}

my $loadfile;
sub LoadFile {
    $loadfile ||= __PACKAGE__->_resolve("LoadFile");
    fixup( $loadfile->(@_) );
}

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::YAML - DWIM loading of Moose objects from YAML

=head1 SYNOPSIS

	# given some class:

	package My::Module;
	use Moose;

	has package => (
		is => "ro",
		init_arg => "name",
	);

	has version => (
		is  => "rw",
		init_arg => undef,
	);

	sub BUILD { shift->version(3) }



	# load an object like so:	

	use MooseX::YAML qw(Load -xs);

	my $obj = Load(<<'YAML');
	--- !My::Module # this syntax requires YAML::XS
	name: "MooseX::YAML"
	YAML

	$obj->package; # "MooseX::YAML"
	$obj->version; # 3, BUILD was called

=head1 DESCRIPTION

This module provides DWIM loading of L<Moose> based objects from YAML
documents.

Any hashes blessed into a L<Moose> class will be replaced with a properly
constructed instance (respecting init args, C<BUILDALL>, and the meta instance
type).

This is similar to L<YAML::Active> in that certain nodes in the loaded YAML
documented are treated specially.

=head1 EXPORTS

All exports are setup by L<Sub::Exporter> using currying.

C<-xs>, C<-syck> or C<-pp> can be specified to specify L<YAML::XS>,
L<YAML::Syck> or L<YAML> on a per import basis.

If no driver is explicitly chosen L<YAML::XS> will be tried first, falling back
to L<YAML>.

=over 4

=item Load

=item LoadFile

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
