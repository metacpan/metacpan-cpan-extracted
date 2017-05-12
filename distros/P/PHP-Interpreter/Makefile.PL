use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;
use File::Spec::Functions qw(catdir);

# Allow 'php-config' to be customized
my $php_config = $ENV{PHP_CONFIG} || q{php-config}; 
print "using php_config '$php_config'\n";

# Check if File::Find is present
eval { use File::Find; };
my $filefind = (!$@) ? 1 : 0;

# These header files must be present for PHP::Interpreter to compile
my %headers = map { $_ => 1 } qw (
  php_config.h php.h php_ini.h php_main.h zend.h
  zend_API.h zend_compile.h zend_ini.h SAPI.h TSRM.h
  zend_interfaces.h
);

# Return true if files in headers hash are found, otherwise die
sub check_headers {
  my $inc = shift;
  die "Need an argument" if !$inc;
  print "Checking header files...\n";

  # Consider as directories only those args starting with '-I' 
  my @incdirs = grep(/^-I/, split(/ /, $inc));
  @incdirs = map { s/^-I//g; chomp; $_ } @incdirs;

  for (@incdirs) {
    die "No such directory: '$_'" if (!-d);
    print "using incdir '$_'\n";
  }

  # Make sure header files are present
  my $finder = sub {
    return if (!-f $_ or !exists($headers{$_}));
    print "Found $File::Find::name\n";
    delete $headers{$_};
  };

  # Try to find all files in headers - delete hash entries when found.
  # Any remaining hash key indicates a necessary file is missing.
  find(\&$finder, @incdirs);
  die "Missing header files: " . join(q{, }, keys %headers) .
    "\nDo you have PHP source installed?" if (keys %headers);

  return 1;
}

# Die unless 'php-config' is found
qx($php_config) or die "Failed to find the 'php-config' executable. " .
             "Make sure you have PHP and PHP sources installed, ".
             "and that 'php-config' is in PATH.";


# Execute 'php-config' for each variable.  Dies if executable is not
# in path.
my %conf = map {
  my $a = qx($php_config --$_);
  die "Error: $php_config --$_ failed\n" unless $a;
  chomp $a;
  $_ => $a;
} qw(includes prefix version ldflags);

# Get php version
print "using php version $conf{version}\n";
$conf{version} =~ s/^(\d+).*/$1/;    # Need major version only
die "Unsupported PHP version" if ($conf{version} != 5);

# Get prefix. Use script argument as prefix, otherwise use value from
# 'php-config'
my $prefix = $ENV{PHP_PREFIX} || ($conf{prefix});
die "Failed to find php prefix" if (!defined($prefix) or !-d $prefix);
print "using prefix $prefix\n";

# Get include directories
my $includes = "-I" . catdir($prefix, 'include') . " " . $conf{includes};
print "using includes $includes\n";

# Get libraries
my @lddlflags = ($Config{lddlflags}, $conf{ldflags});
push @lddlflags, "-L" . catdir $prefix, "lib";
my $php_embedlib_path = "-L" . catdir $prefix, "lib";
push @lddlflags, $php_embedlib_path;
print "using lddlflags " . join(q{ }, @lddlflags) . "\n";

# Libs = lddlflags + php-version
my @libs = ("$php_embedlib_path");
push @libs, "-lphp$conf{version}";
print "using libs " . join(q{ }, @libs) . "\n";

my @ofiles = ('PHP.o', 'phpinterp.o', 'phpfuncs.o');

# Check that header files are present if File::Find is installed
($filefind)
  ? check_headers($includes)
  : print "WARNING: Module File::Find not installed. Header files check skipped.\n";

WriteMakefile(
  CCFLAGS      => '-g',
  OBJECT       => join(' ', @ofiles),
  NAME         => 'PHP::Interpreter',
  LIBS         => join(' ', @libs),
  LDDLFLAGS    => join(' ', @lddlflags),
  INC          => $includes,
  VERSION_FROM => 'lib/PHP/Interpreter.pm',
  PREREQ_PM    => {

    # Just required for testing.
    'Test::More' => 0,
    'IO::File'   => 0
  },
);

__END__

=pod

=head1 NAME

  Makefile.PL - Makefile for PHP::Interpreter

=head1 SYNOPSIS

  # Set PHP_PREFIX (optional)
  PHP_PREFIX=/usr/local

  # Create makefile
  perl Makefile.PL
  
=head1 OPTIONS

Valid environment variables are

=head2 PHP_PREFIX

The root directory of the PHP install, e.g. '/usr/local/' or
'C:\\php'.

=head2 PHP_CONFIG

The executable used to set up the PHP environment,
e.g. '/usr/local/bin/php-config'.  Default is to just set it to
'php-config', which means it must be in your PATH. In case of more
than one matching file, then the first one will be used.

=head1 DESCRIPTION

This creates a makefile for PHP::Interpreter.  PHP::Interpreter
depends on having both PHP and PHP sources installed.

This script uses the executable I<php-config> to determine how PHP is
configured. This script will die unless I<php-config> is installed.

PHP::Interpreter works with PHP5 only.

This script will perform header files check if module I<File::Find> is
installed.

=head1 TROUBLESHOOTING

=head2 PHP5 LIBRARIES NOT FOUND

If the php5 libraries cannot be found, then the install will not
work:

  Note (probably harmless): No library found for -lphp5 

You can resolve this problem by setting I<PHP_PREFIX> to the root
directory of you PHP install.  Do also make sure that your install of
PHP is compiled as described in the the README file.

=head1 SEE ALSO

  php
  php-config

=cut


