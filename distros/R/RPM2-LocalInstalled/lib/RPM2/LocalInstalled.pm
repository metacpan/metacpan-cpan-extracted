package RPM2::LocalInstalled;

use 5.008;
use strict;
use warnings;

require Exporter;

use RPM2;
use Sort::Versions;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

(our $VERSION) = '$Revision: 1.4 $' =~ /([\d.]+)/;

sub new {
	my $class = shift;
	my $args = shift;
	my $self = {};

	if($args) {
		die "The argument supplied is not reference; Use ->new({ tags = [ qw/version release epoch ]}) for example." unless ref $args;
	}
	my @default_tags = qw/version release epoch/;
	$self->{tags} = $args->{tags} || \@default_tags;
	foreach(@default_tags) {
		push @{$self->{tags}}, $_ unless $self->{tags} =~ /$_/;
	}
	die "tags is not an array: " . ref $self->{tags} unless ref $self->{tags} eq 'ARRAY';

	bless($self, $class);
	return $self;
}

sub list_all {
	my $self = shift;
	my $rpmdb = RPM2->open_rpm_db();
	my $i = $rpmdb->find_all_iter();
	while(my $pkg = $i->next()) {
		my $info;
		foreach my $tag (@{$self->{tags}}) {
			$info->{$tag} = $pkg->tag($tag);
			$info->{$tag} = 0 if $tag eq 'epoch' && ! defined $pkg->tag($tag);
		}
		push @{$self->{__all}->{$pkg->name()}}, $info;
	}
	return $self->{__all};
}

sub list_newest {
	my $self = shift;
	$self->list_all() unless $self->{__all};
	foreach my $pkgname (keys %{$self->{__all}}) {
		foreach(@{$self->{__all}->{$pkgname}}) {
			if($self->{__newest}->{$pkgname}) {
				my $everel1 = $_->{epoch} . ":" . $_->{version} . "-" . $_->{release};
				my $everel2 = $self->{__newest}->{$pkgname}->{epoch} . ":" . $self->{__newest}->{$pkgname}->{version} . "-" . $self->{__newest}->{$pkgname}->{release};
				push @{$self->{__older}->{$pkgname}}, $self->{__newest}->{$pkgname} if versioncmp($everel1, $everel2) == 1;
				$self->{__newest}->{$pkgname} = $_ if versioncmp($everel1, $everel2) == 1;
			} else {
				$self->{__newest}->{$pkgname} = $_;
			}
		}
	}
	return $self->{__newest};
}

sub list_older {
	my $self = shift;
	$self->list_newest() unless $self->{__newest};
	return $self->{__older};
}

1;
__END__

=head1 NAME

RPM2::LocalInstalled - Perl extension that returns a list of locally installed RPMs

=head1 SYNOPSIS

  use RPM2::LocalInstalled;
  
  my $rpms = RPM2::LocalInstalled->new();
  
  my $all_rpms = $rpms->list_all();
  my $newest_rpms = $rpms->list_newest();
  my $older_rpms = $rpms->list_older();

  $all_rpms is a hash with the rpm package name as hash keys. Behind the hash
  key there will be an array containing a hash of all tags you requested (or
  the default tags: version release epoch) from the different packages
  installed (if more than one is installed (often happens for the kernel
  package).

  $newest_rpms is a hash, but containing only one hash, containing the tags you
  requested.

  $older_rpms is 'the difference between $all_rpms and $newest_rpms. It
  lists only older packages. The ones that should be removed sooner or later...

  You can define the tags @ new this way (example):

  my $rpms = RPM2::LocalInstalled->new(
	tags => [ qw/group size packager license/ ],
  );

  Note, that RPM2::LocalInstalled will allways add the default tags
  (version, release, epoch), as they are used in newest_rpms()
  for version comparison.

=head1 DESCRIPTION

RPM2::LocalInstalled is a wrapper around RPM2. RPM2::LocalInstalled
will return lists of locally installed RPMs.
This is usefully for comparing with a list of updates, eg. from
Config::YUM.

=head2 EXPORT

None by default.

=head1 SEE ALSO

RPM2
Sort::Version

=head1 AUTHOR

Oliver Falk, E<lt>oliver@linux-kernel.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Oliver Falk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
