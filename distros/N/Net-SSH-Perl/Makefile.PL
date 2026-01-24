=encoding utf8

=head1 The build file for Net::SSH::Perl

This build file is a modulino; it works as both a build script and
a module.

To build the distribution, run this file normally:

	% perl Makefile.PL

But, it's more interesting than that. You can load it with C<require>
and call C<arguments> to get the data structure it passes to
C<WriteMakefile>:

	my $package = require '/path/to/Makefile.PL';
	my $arguments = $package->arguments;

Note that C<require>-ing a file makes an entry in C<%INC> for exactly
that name. If you try to C<require> another file with the same name,
even from a different path, C<require> thinks it has already loaded
the file. As such, I recommend you always require the full path to the
file.

The return value of the C<require> is a package name (in this case,
the name of the main module. Use that to call the C<arguments> method.

Even if this distribution needs a higher version of Perl, this bit
only needs v5.8. You can play with the data structure with a primitive
Perl.

=cut

use 5.006;

package Net::SSH::Perl;
use strict;
use warnings;

use ExtUtils::MakeMaker qw(prompt WriteMakefile);

my %prereq = (
        'IO::Socket'        => 0,
        'File::Spec'        => 0,
        'File::HomeDir'     => 0,
);

my %SSH_PREREQ = (
    1 => {
        'Digest::MD5'       => 0,
        'String::CRC32'     => '1.2',
        'Math::GMP'         => '1.04',
        'Scalar::Util'      => 0,
        'Crypt::IDEA'       => 0,
    },

    2 => {
        'CryptX'            => '0.032',
        'Crypt::Curve25519' => '0.05',
    },
);

$SSH_PREREQ{3} = { map %{$SSH_PREREQ{$_}}, 1..2 };

my $p = do {
	if( caller ) { 3 }
	else {
		prompt_for_protocol();
		}
	};

@prereq{keys %{$SSH_PREREQ{$p}}} = values %{$SSH_PREREQ{$p}};

if( caller ) {  $prereq{'Digest::BubbleBabble'} = '0.01' }
else {
	print "Checking for optional modules\n\n";

	unless (have_module('Digest::BubbleBabble', 0.01)) {
		print<<MSG, "\n";
Digest::BubbleBabble is required if you want to generate bubble babble
key fingerprints with pssh-keygen.
MSG

		if (read_yes_or_no("Would you like to install it? (y/n)", "y")) {
			$prereq{'Digest::BubbleBabble'} = '0.01';
			}
		print "\n";
		}
	}

use File::Spec::Functions qw(catfile);

my $module    = __PACKAGE__;
( my $dist = $module ) =~ s/::/-/g;

my $github    = 'https://github.com/briandfoy/net-ssh-perl';
my $main_file = catfile( 'lib', split /::/, "$module.pm" );

my %WriteMakefile = (
	'MIN_PERL_VERSION' => '5.010',

	'NAME'		    => $module,
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'	=> $main_file,
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'David Robins <dbrobins@cpan.org>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Spec::Functions' => '0',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::More' => '1',
		},

	'PREREQ_PM'     => \%prereq,

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => $github,
				web  => $github,
				},
			bugtracker => {
				web    => "$github/issues",
				},
			homepage => $github,
			},
		},

	'clean' => { FILES => "$dist-*" },
	);

sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			||
		"$MM 6.64";
	eval "use $MM_version; 1" or die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21"
		if -e File::Spec->catfile( qw(t test_manifest) );

	my $arguments = arguments();
	my $minimum_perl = $arguments->{MIN_PERL_VERSION} || '5.008';
	eval "require $minimum_perl;" or die $@;

	WriteMakefile( %$arguments );
	}

sub prompt_for_protocol {
	my $prompt = <<'MSG';
This is Net::SSH::Perl.

As of version 1.00, Net::SSH::Perl supports both the SSH1 and
SSH2 protocols natively. The two protocols have different
module prerequisitives, so you need to decide which protocol(s)
you plan to use. If you use one or the other, only those modules
for your chosen protocol will be installed; if you choose both,
all of the supporting modules will be installed. Please choose
the protocols you'd like to use from the following list ("Both"
is the default).

MSG

	$prompt .= sprintf "    [%d] SSH%d\n", $_, $_ for 1..2;
	$prompt .= "    [3] Both SSH1 and SSH2\n";
	$prompt .= "\nWhich protocol(s) do you plan to use?";

	my $result = prompt($prompt, 3);

	return $result;
}

sub read_yes_or_no {
    my($prompt, $def) = @_;
    my $ans = prompt($prompt, $def);
    $ans =~ /^y/i;
}

sub have_module {
    my($name, $ver) = @_;
    eval("use $name" . ($ver ? " $ver;" : ";"));
    !$@;
}

no warnings;
__PACKAGE__;
