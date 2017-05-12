#
# $Id: Makefile.PL 1495 2016-08-23 08:54:04Z willem $	-*-perl-*-
#


warn <<AMEN if $] < 5.008;

Net::DNS::SEC has been tested with Perl 5.8

The author is confident that this package will work with version 5.6
but not confident that it will work with any earlier version.

The latest version of perl can always be found at:
	http://www.cpan.org/src/latest.tar.gz
AMEN


use ExtUtils::MakeMaker;
use constant MM => eval $ExtUtils::MakeMaker::VERSION;

# See perldoc ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.

my @author = ( 'Olaf Kolkman', 'Dick Franks' );

my %metadata = (
	NAME		 => 'Net::DNS::SEC',
	VERSION_FROM	 => 'lib/Net/DNS/SEC.pm',
	ABSTRACT_FROM	 => 'lib/Net/DNS/SEC.pm',
	AUTHOR		 => MM < 6.5702 ? shift(@author) : [@author],
	LICENSE		 => 'mit',
	MIN_PERL_VERSION => 5.006,
	);


my %prerequisite = (
	Net::DNS	       => 1.01,
	Crypt::OpenSSL::Bignum => 0.05,
	Crypt::OpenSSL::RSA    => 0.28,
	File::Spec	       => 0.86,
	MIME::Base64	       => 2.11,
	Test::More	       => 0.47,
	);


my %optional = (
	Crypt::OpenSSL::DSA    => 0.15,
	Crypt::OpenSSL::EC     => 1.01,
	Crypt::OpenSSL::ECDSA  => 0.06,
	Crypt::OpenSSL::Random => 0.10,
	Digest::GOST	       => 0.06,
	Digest::SHA	       => 5.23,
	);


WriteMakefile(
	%metadata,
	PREREQ_PM  => {%prerequisite},
	META_MERGE => {recommends => {%optional}},
	);


sub MY::libscan {
	my $path = $_[1];
	return '' if $path =~ /\B\.svn\b/;
	return $path;
}


__END__

