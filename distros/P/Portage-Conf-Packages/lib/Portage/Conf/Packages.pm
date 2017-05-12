package Portage::Conf::Packages;

require Exporter;
use strict;
use warnings;
use vars qw($VERSION @EXPORT);
use Tie::File;

our @ISA = qw(Exporter);
our @EXPORT = qw(new validatePackage Use);
our @EXPORT_OK = qw();
our $VERSION = 1.3;

sub new {
	my $invoke = shift;
	my $class = ref($invoke) || $invoke;
	my $self = {
		UsePath => '/etc/portage/package.use',
		KeywordsPath => '/etc/portage/package.keywords',
		MaskPath => '/etc/portage/package.mask',
		UnmaskPath => '/etc/portage/package.unmask',
		@_
	};
	return bless $self,$class;
}


sub validatePackage {
	my $self = shift;
	my $ret = 1;
	for my $package (@_) {
		last if !$ret;
		my $eix = `eix -c $package` or die "eix failed\n";
		my $wc = `echo \"$eix\" | wc -l`;
		if ($eix =~ m/No matches found/) {
			print "No matches for $package\n";
			$ret = 0;
		}elsif(($wc - 1) > 1 and $eix !~ m/[ ]($package)[ ]/) {
			print "Too many matches for $package\n";
			$ret = 0;
		}elsif ($eix !~ m/[ ]($package)[ ]/) {
			print "Did you mean: ";
			$eix =~ m/^\[.+\][ ]([\w\-\/]+)[ ].+/;
			print "$1 ?\n";
			$ret = 0;
		}elsif ($eix =~ m/[ ]($package)[ ]/) {
			print "$package is valid\n";
			$ret = 1;
		}
	}
	return $ret;
}


sub Use {
	my $self = shift;
	my %packages = @_;
	my $i = 0;
	my $fuseflags;
	my $fpackage;
	my $haspackage;
	my $pack;

	tie my @uselines, 'Tie::File', $self->{UsePath};
	#look if package already in there
	for $pack (keys %packages) {
		for my $fuseline (@uselines) {
			#regexp for package match and useflag extraction
			if ( $fuseline =~ m/^($pack)[ ](.*)$/sg )
			{    #package is already in the file
				#save useflags
				$fpackage   = $1;
				$fuseflags  = $2;
				$haspackage = 1;
				last;
			}
			$i++;
		}

		if(!$haspackage) {
			my $newline = $pack . " " . join( " ", @{$packages{$pack}} );
			$uselines[@uselines] = $newline; #write new line to file
			print "New line: $newline\n";
			untie @uselines;
			exit 0;
		}

		for my $flags (@{$packages{$pack}}) {
			next if $fuseflags =~ m/(^($flags)|(\s$flags)|(\s$flags\s))/; #flag is already in the file
			if ( $fuseflags =~ s/([-]$flags)/$flags/ ) { #enabling a disabled flag
				print "Setting $1 to $flags : Enabling\n";
				next;
			}
			if ( $flags =~ m/([-](.+))/s and $fuseflags =~ m/($2)/s ) { #disable an enabled flag
				print "Setting $1 to $flags : Disabling\n";
				$fuseflags =~ s/$1/$flags/;
			}
			else { #add new flag
				print "Adding useflag: $flags \n";
				$fuseflags .= " " . $flags;
			}
		}

		#write new line
		$uselines[$i] =
		$pack . " " . join( " ", reverse sort split( " ", $fuseflags ) );
		print "Altered line: ", $uselines[$i], "\n";
		untie @uselines;
	}
}

1;

__END__

=head1 NAME

Portage::Conf::Packages - Function collection for the Gentoo Portage package files.


=head1 SYNOPSIS

	use Portage::Conf::Packages;
	$mod = Portage::Conf::Packages->new(UsePath => './package.use');
	if ($mod->validatePackage("net-im/skype")) {
		$mod->Use(
			"net-im/skype" => ["-arts", "oss", "dbus"]
		);
	}


=head1 DESCRIPTION

This Module is able to modifie your /etc/portage/package.* files


=head1 METHODS

Discription of the Methods


=over 4

=item * validatePackage

Validates a package with eix.
	$epack->validatePackage("net-im/skype");


=item * Use

Edit or add the useflags for given packages and flags
	$mod->Use(
		"net-im/skype" => ["-arts", "oss", "dbus"]
	);


=back


=head1 BUGS

Please report to https://opensvn.csie.org/traccgi/epackageuse


=head1 AUTHOR

Tristan Leo filecorpse::at::gmail.com


=head1 COPYRIGHT

Copyright (c) 2006 Tristan Leo All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
# vim:ts=8:sw=4:ft=perl
