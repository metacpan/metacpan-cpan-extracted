# $Id: 00-version.t 1582 2017-07-07 21:45:14Z willem $ -*-perl-*-

use strict;
use Test::More;
use File::Spec;
use File::Find;
use ExtUtils::MakeMaker;

my @files;
my $blib = File::Spec->catfile(qw(blib lib));

find( sub { push( @files, $File::Find::name ) if /\.pm$/ && !/Template/ }, $blib );

my %manifest;
open MANIFEST, 'MANIFEST' or plan skip_all => "MANIFEST: $!";
while (<MANIFEST>) {
	chomp;
	my ( $volume, $directory, $name ) = File::Spec->splitpath($_);
	$manifest{lc $name}++ if $name;
}
close MANIFEST;

plan skip_all => 'No versions from git checkouts' if -e '.git';

plan skip_all => 'Not sure how to parse versions.' unless eval { MM->can('parse_version') };

plan tests => scalar @files;

foreach my $file ( sort @files ) {				# reconcile files with MANIFEST
	my $version = MM->parse_version($file);
	diag("$file\t=>\t$version") if $ENV{'NET_DNS_DEBUG'};
	ok( $version =~ /[\d.]{3}/, "file version: $version\t$file" );
	my ( $volume, $directory, $name ) = File::Spec->splitpath($file);
	diag("File not in MANIFEST: $file") unless $manifest{lc $name};
}


eval {
	my %macro;						# extract Makefile macros
	open MAKEFILE, 'Makefile' or die $!;
	while (<MAKEFILE>) {
		$macro{$1} = $2 if /^([A-Z_]+)\s+=\s+(.*)$/;
	}
	close MAKEFILE;

	my %install_type = qw(perl INSTALLPRIVLIB site INSTALLSITELIB vendor INSTALLVENDORLIB);
	my $install_site = join '', '$(DESTDIR)$(', $install_type{$macro{INSTALLDIRS}}, ')';
	for ($install_site) {
		s/\$\(([A-Z_]+)\)/$macro{$1}/eg while /\$\(/;	# expand Makefile macros
		s|([/])[/]+|$1|g;				# remove gratuitous //s
	}

	local @INC = grep !m/\bblib\W(arch|lib)$/i, @INC;
	eval 'require Net::DNS';

	my $nameregex = '\W+Net\WDNS.pm$';
	my @installed = grep m/$nameregex/io, values %INC;
	my %noinstall;

	foreach (@installed) {
		my $path = $1 if m/^(.+)$nameregex/i;
		my %seen;
		foreach (@INC) {
			$seen{$_}++;				# find $path in @INC
			last if $_ eq $path;
		}
		foreach ( grep !$seen{$_}, @INC ) {
			$noinstall{$_}++;			# mark hidden libraries
		}
	}

	warn <<"AMEN" if $noinstall{$install_site};

##
##	The install location for this version of Net::DNS differs
##	from the existing version $Net::DNS::VERSION in your perl library.
##	@installed
##
##	The installation will be rendered ineffective because the
##	library search finds the existing version before reaching
##	$install_site
##
##	Makefile has been generated to support build and test only.
##
AMEN

}


__END__

