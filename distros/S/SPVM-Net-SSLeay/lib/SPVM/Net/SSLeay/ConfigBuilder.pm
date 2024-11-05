package SPVM::Net::SSLeay::ConfigBuilder;

# find_openssl_prefix function and ssleay_get_build_opts function are copied from Makefile.PL in Perl's Net::SSLeay.
# Some parts are commented out with "=pod COMMENT OUT".

use utf8;
use strict;
use warnings;

use Config;
use English qw( $OSNAME -no_match_vars );
use ExtUtils::MakeMaker;
use File::Basename ();
use File::Spec;
use File::Spec::Functions qw(catfile);
use Symbol qw(gensym);
use Text::Wrap;

sub new {
  my $class = shift;
  
  my $self = {
    @_
  };
  
  return bless $self, ref $class || $class;
}

sub build_config {
  my ($self, $config) = @_;
  
  my $openssl_prefix = &find_openssl_prefix();
  my $openss_build_opts = &ssleay_get_build_opts($openssl_prefix);
  
  my $cccdlflags = $openss_build_opts->{cccdlflags};
  
  my $inc_path = $openss_build_opts->{inc_path};
  
  my $lib_paths = $openss_build_opts->{lib_paths};
  
  my $lib_links = $openss_build_opts->{lib_links};
  
  if (length $cccdlflags) {
    $config->add_ccflag($cccdlflags);
  }
  
  $config->add_include_dir($inc_path);
  
  $config->add_lib_dir(@$lib_paths);
  
  $config->add_lib(@$lib_links);
}

# According to http://cpanwiki.grango.org/wiki/CPANAuthorNotes, the ideal
# behaviour to exhibit when a prerequisite does not exist is to use exit code 0
# to ensure smoke testers stop immediately without reporting a FAIL; in all
# other environments, we want to fail more loudly
use constant {
    MISSING_PREREQ     => ( $ENV{AUTOMATED_TESTING} ? 0 : 1 ),
    UNSUPPORTED_LIBSSL => ( $ENV{AUTOMATED_TESTING} ? 0 : 1 ),
};

# Error messages displayed with alert() will be this many columns wide
use constant ALERT_WIDTH => 78;

# Define this to one if you want to link the openssl libraries statically into 
# the Net-SSLeay loadable object on Windows
my $win_link_statically = 0;

sub ssleay_get_build_opts {
    my ($prefix) = @_;

    my $opts = {
        lib_links  => [],
        cccdlflags => '',
    };

    my @try_includes = (
        'include' => sub { 1 },
        'inc32'   => sub { $OSNAME eq 'MSWin32' },
    );

    while (
           !defined $opts->{inc_path}
        && defined( my $dir = shift @try_includes )
        && defined( my $cond = shift @try_includes )
    ) {
        if ( $cond->() && (-f "$prefix/$dir/openssl/ssl.h"
                           || -f "$prefix/$dir/ssl.h")) {
            $opts->{inc_path} = "$prefix/$dir";
        }
    }

    # Directory order matters. With macOS Monterey a poisoned dylib is
    # returned if the directory exists without the desired
    # library. See GH-329 for more information. With Strawberry Perl
    # 5.26 and later the paths must be in different order or the link
    # phase fails.
    my @try_lib_paths = (
	["$prefix/lib64", "$prefix/lib", "$prefix/out32dll", $prefix] => sub {$OSNAME eq 'darwin' },
	[$prefix, "$prefix/lib64", "$prefix/lib", "$prefix/out32dll"] => sub { 1 },
	);

    while (
	!defined $opts->{lib_paths}
	&& defined( my $dirs = shift @try_lib_paths )
	&& defined( my $cond = shift @try_lib_paths )
    ) {
	if ( $cond->() ) {
	    foreach my $dir (@{$dirs}) {
		push @{$opts->{lib_paths}}, $dir if -d $dir;
	    }
	}
    }

=pod COMMENT OUT

    print <<EOM;
*** If there are build errors, test failures or run-time malfunctions,
    try to use the same compiler and options to compile your OpenSSL,
    Perl, and Net::SSLeay.
EOM

=cut

    if ($^O eq 'MSWin32') {
        if ($win_link_statically) {
            # Link to static libs
            push @{ $opts->{lib_paths} }, "$prefix/lib/VC/static" if -d "$prefix/lib/VC/static";
            push @{ $opts->{lib_paths} }, "$prefix/lib/VC/x86/MT" if -d "$prefix/lib/VC/x86/MT"; # Shining Light 32bit OpenSSL 3.2.0
            push @{ $opts->{lib_paths} }, "$prefix/lib/VC/x64/MT" if -d "$prefix/lib/VC/x64/MT"; # Shining Light 64bit OpenSSL 3.2.0
        }
        else {
            push @{ $opts->{lib_paths} }, "$prefix/lib/VC" if -d "$prefix/lib/VC";
            push @{ $opts->{lib_paths} }, "$prefix/lib/VC/x86/MD" if -d "$prefix/lib/VC/x86/MD"; # Shining Light 32bit OpenSSL 3.2.0
            push @{ $opts->{lib_paths} }, "$prefix/lib/VC/x64/MD" if -d "$prefix/lib/VC/x64/MD"; # Shining Light 64bit OpenSSL 3.2.0
        }

        my $found = 0;
        my @pairs = ();
        # Library names depend on the compiler
        @pairs = (['eay32','ssl32'],['crypto.dll','ssl.dll'],['crypto','ssl']) if $Config{cc} =~ /gcc/;
        @pairs = (['libeay32','ssleay32'],['libeay32MD','ssleay32MD'],['libeay32MT','ssleay32MT'],['libcrypto','libssl'],['crypto','ssl']) if $Config{cc} =~ /cl/;
        FOUND: for my $dir (@{$opts->{lib_paths}}) {
          for my $p (@pairs) {
            $found = 1 if ($Config{cc} =~ /gcc/ && -f "$dir/lib$p->[0].a" && -f "$dir/lib$p->[1].a");
            $found = 1 if ($Config{cc} =~ /cl/ && -f "$dir/$p->[0].lib" && -f "$dir/$p->[1].lib");
            if ($found) {
              $opts->{lib_links} = [$p->[0], $p->[1], 'crypt32']; # Some systems need this system lib crypt32 too
              $opts->{lib_paths} = [$dir];
              last FOUND;
            }
          }
        }
        if (!$found) {
          #fallback to the old behaviour
          push @{ $opts->{lib_links} }, qw( libeay32MD ssleay32MD libeay32 ssleay32 libssl32 crypt32);
        }
    }
    elsif ($^O eq 'VMS') {
        if (-r 'sslroot:[000000]openssl.cnf') {      # openssl.org source install
          @{ $opts->{lib_paths} } = 'SSLLIB';
          @{ $opts->{lib_links} } = qw( ssl_libssl32.olb ssl_libcrypto32.olb );
        }
        elsif (-r 'ssl111$root:[000000]openssl.cnf') {  # VSI SSL111 install
            @{ $opts->{lib_paths} } = 'SYS$SHARE';
            @{ $opts->{lib_links} } = qw( SSL111$LIBSSL_SHR32 SSL111$LIBCRYPTO_SHR32 );
        }
        elsif (-r 'ssl1$root:[000000]openssl.cnf') {  # VSI or HPE SSL1 install
            @{ $opts->{lib_paths} } = 'SYS$SHARE';
            @{ $opts->{lib_links} } = qw( SSL1$LIBSSL_SHR32 SSL1$LIBCRYPTO_SHR32 );
        }
        elsif (-r 'ssl$root:[000000]openssl.cnf') {  # HP install
            @{ $opts->{lib_paths} } = 'SYS$SHARE';
            @{ $opts->{lib_links} } = qw( SSL$LIBSSL_SHR32 SSL$LIBCRYPTO_SHR32 );
        }
        @{ $opts->{lib_links} } = map { $_ =~ s/32\b//g } @{ $opts->{lib_links} } if $Config{use64bitall};
    }
    else {
        push @{ $opts->{lib_links} }, qw( ssl crypto z );

        if (($Config{cc} =~ /aCC/i) && $^O eq 'hpux') {

=pod COMMENT OUT

            print "*** Enabling HPUX aCC options (+e)\n";

=cut

            $opts->{optimize} = '+e -O2 -g';
        }

        if ( (($Config{ccname} || $Config{cc}) eq 'gcc') && ($Config{cccdlflags} =~ /-fpic/) ) {

=pod

            print "*** Enabling gcc -fPIC optimization\n";

=cut

            $opts->{cccdlflags} .= '-fPIC';
        }
    }
    return $opts;
}

sub find_openssl_prefix {
    my ($dir) = @_;

    if (defined $ENV{OPENSSL_PREFIX}) {
        return $ENV{OPENSSL_PREFIX};
    }

    my @guesses = (
	'/home/linuxbrew/.linuxbrew/opt/openssl/bin/openssl' => '/home/linuxbrew/.linuxbrew/opt/openssl', # LinuxBrew openssl
	'/opt/homebrew/opt/openssl/bin/openssl' => '/opt/homebrew/opt/openssl', # macOS ARM homebrew
	'/usr/local/opt/openssl/bin/openssl' => '/usr/local/opt/openssl', # OSX homebrew openssl
	'/usr/local/bin/openssl'         => '/usr/local', # OSX homebrew openssl
	'/opt/local/bin/openssl'         => '/opt/local', # Macports openssl
	'/usr/bin/openssl'               => '/usr',
	'/usr/sbin/openssl'              => '/usr',
	'/opt/ssl/bin/openssl'           => '/opt/ssl',
	'/opt/ssl/sbin/openssl'          => '/opt/ssl',
	'/usr/local/ssl/bin/openssl'     => '/usr/local/ssl',
	'/usr/local/openssl/bin/openssl' => '/usr/local/openssl',
	'/apps/openssl/std/bin/openssl'  => '/apps/openssl/std',
	'/usr/sfw/bin/openssl'           => '/usr/sfw', # Open Solaris
	'C:\OpenSSL\bin\openssl.exe'     => 'C:\OpenSSL',
	'C:\OpenSSL-Win32\bin\openssl.exe'        => 'C:\OpenSSL-Win32',
	'C:\Program Files (x86)\OpenSSL-Win32\bin\openssl.exe' => 'C:\Program Files (x86)\OpenSSL-Win32', # Shining Light 32bit OpenSSL 1.1.1w, 3.0.12, 3.1.4 and 3.2.0
	'C:\Program Files\OpenSSL-Win64\bin\openssl.exe'       => 'C:\Program Files\OpenSSL-Win64',       # Shining Light 64bit OpenSSL 1.1.1w, 3.0.12, 3.1.4 and 3.2.0
	$Config{prefix} . '\bin\openssl.exe'      => $Config{prefix},           # strawberry perl
	$Config{prefix} . '\..\c\bin\openssl.exe' => $Config{prefix} . '\..\c', # strawberry perl
	'/sslexe/openssl.exe'            => '/sslroot',  # VMS, openssl.org
	'/ssl111$exe/openssl.exe'        => '/ssl111$root',# VMS, VSI install
	'/ssl1$exe/openssl.exe'          => '/ssl1$root',# VMS, VSI or HPE install
	'/ssl$exe/openssl.exe'           => '/ssl$root', # VMS, HP install
	$Config{prefix} . '/bin/openssl' => $Config{prefix}, # Custom prefix, e.g. Termux
    );

    while (my $k = shift @guesses
           and my $v = shift @guesses) {
        if ( -x $k ) {
            return $v;
        }
    }
    (undef, $dir) = check_no_path()
       and return $dir;

    return;
}

1;

=head1 Name

SPVM::Net::SSLeay::ConfigBuilder - Config Builder for Net::SSLeay.

=head1 Description

SPVM::Net::SSLeay::ConfigBuilder class is a config builder for L<Net::SSLeay|SPVM::Net::SSLeay>.

This class is a Perl module.

=head1 Usage

my $ssl_config_builder = SPVM::Net::SSLeay::ConfigBuilder->new;

$ssl_config_builder->build_config($config);

=head1 Class Methods

=head2 new

  my $ssl_config_builder = SPVM::Net::SSLeay::ConfigBuilder->new;

Create a new L<SPVM::Net::SSLeay::ConfigBuilder> object and returns it.

=head1 Instance Methods

=head2 build_config

  $ssl_config_builder->build_config($config);

Builds the config $config to bind L<Net::SSLeay|SPVM::Net::SSLeay>.

$config is a L<SPVM::Builder::Config> object.

The path of the directory that contains OpenSSL headers and library is automatically detected, but if you specify it, use C<$ENV{OPENSSL_PREFIX}> environment variable.

  export OPENSSL_PREFIX = /path/openssl

=head1 See Also

=over 2

=item * L<SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
