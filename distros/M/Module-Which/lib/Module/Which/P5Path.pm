
package Module::Which::P5Path;
$Module::Which::P5Path::VERSION = '0.05';
use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(path_to_p5path path_to_p5 p5path_to_path);

use Config;
require File::Spec::Unix; # qw(splitdir catdir);
require File::Spec;

# NOTE. To map config vars to their values, like this
#    ('archlib', 'perlpath') => ( $Config{archlib}, $Config{perlpath} )
# we only need the expression "@Config{@_}".

# my @vars = _purge_vars('a', 'b', 'c')
# Purges a list of Config variable names by eliminating those with 
# false and duplicate values. The original order is preserved.
sub _purge_vars {
	my @vars;
	my %h; 
	for my $val (@Config{@_}) {
		my $var = shift @_;
		next unless $val; # skip undefs and ''
		unless ($h{$val}++) { # keep only the first occurrence of a value
			push @vars, $var;
		}
	}
	return @vars
}

sub _is_windows {
	return $^O =~ /^(MSWin32|cygwin)/i;
}

sub _is_case_tolerant {
	return $^O =~ /^(MSWin32|cygwin)/i;
}
# it would make sense to use File::Spec->case_tolerant
# which should return 1 for Windows and Cygwin
# but it does not in Cygwin.

# tells whether a path lies under a directory path
# (it just checks to see if ...
#
# NOTE. include (?i) in pattern below when case_tolerant

# turns 'blib\lib' into 'blib[\\/]lib'
#   and 'a/b\c'    into 'a[\\/]b[\\/]c'
sub _win_re {
	my $p = shift;
	$p =~ s!([\\/])|(.)! $1?'[\\\\/]':"\Q$2" !ge;
	return $p
}
# is(_win_pattern('blib\lib'), 'blib[\\/]lib');
# is(_win_pattern('a/b\c'), 'a[\\/]b[\\/]c');
# is(_win_pattern('dir/f.pl'), 'dir[\\/]f\.pl');

sub _is_under {
	my $path = shift;
	my $dir = shift;
	return $path =~ /^\Q$dir\E/ unless _is_windows;
	# windows is: case tolerant and accepts '\\' or '/'
	my $dir_re = _win_re($dir);
	return $path =~ /(?i)^$dir_re/
}

sub _parent {
	my $path = shift;
	my @path = File::Spec::Unix->splitdir($path);
	pop @path;
	return File::Spec::Unix->catdir(@path)
}

# this computes a relative path from an absolute WHEN
# we know that the base is a descendant of the path
# (so we don't need to handle '.', '..' and the like)
# like File::Spec->abs2rel() is able to do
sub _abs2rel {
	my $path = shift;
	my $base = shift;
	my @path = File::Spec::Unix->splitdir($path);
	my $base_nodes = File::Spec::Unix->splitdir($base);
	splice @path, 0, $base_nodes;
	return File::Spec::Unix->catdir(@path);
}

# my ($p5path, $p5base) = _resolve_path($path, @ivars);
# my $p5path = _resolve_path($path, @ivars);
sub _resolve_path {
	my $path = shift;
	unless ($path) {
		return ($path, '') if wantarray;
		return $path
	}

	my @vars = @_;
	for (@vars) {
		my $p5p = $Config{$_}; 
		if (_is_under($path, $p5p)) {
			my $p5base = '${' . $_ . '}/';
			#my $p5path = $p5base . File::Spec::Unix->abs2rel($path, $Config{$_});
			my $p5path = $p5base . _abs2rel($path, $p5p);
			return ($p5path, $p5base) if wantarray;
			return $p5path
		}
	}
	return ($path, _parent($path)) if wantarray; # !FIXME: I don't like this!
	return $path # no resolution against given vars
}

our @DEFAULT_IVARS = qw(
   installarchlib archlib installprivlib privlib 
   installsitearch installsitelib sitelib sitelib_stem
   installvendorarch installvendorlib vendorlib vendorlib_stem
); 

# ($p5path, $p5base) = path_to_p5($path)
# $p5path = path_to_p5($path, include => \@IVARS)
sub path_to_p5 {
	my $path = shift;
	my %options = @_;
	my $ivars = $options{install_vars} || \@DEFAULT_IVARS;
    my @ivars = _purge_vars(@$ivars);
	return _resolve_path($path, @ivars);
}

# $p5path = path_to_p5path($path);
# $p5path = path_to_p5path($path, include => \@IVARS);
sub path_to_p5path {
	return scalar path_to_p5(@_);
}

sub p5path_to_path {
	my $path = shift;
	$path =~ s/^\$\{(\w+)\}/$Config{$1}/;
	return $path

}

1;

__END__

=head1 NAME

Module::Which::P5Path - Translate paths to Config-relative paths

=head1 SYNOPSIS

   use Module::Which::P5Path qw(path_to_p5path p5path_to_path);

   $path = "$Config{installarchlib}/A/B.pm";
   $p5path = path_to_p5path($path); # => '${installarchlib}/A/B.pm'

   $p5path = path_to_p5path($path, install_vars => [ qw(archlib sitelib vendorlib) ]);

   $path = p5path_to_path('${sitelib_stem}/X/Y/Z.pm'); # the same as "$Config{sitelib_stem}/X/Y/Z.pm"

   # translate your @INC
   for (@INC) {
	   print "$_ -> ", path_to_p5path($_), "\n";
   }

=head1 DESCRIPTION

The Perl 5 configuration has a number of parameters which 
are library paths used for finding C<.pm>, C<.pl> and related files.
For example, C<installarchlib> and C<sitelib>. These
are used by the C<perl> executable to build the C<@INC>
variable at script startup.

L<Module::Which> is intented to find out information
about installed modules, including path and version. 
To help C<Module::Which> to provide sensible information,
this module provides functions to express a path like
F</usr/lib/perl5/5.8.2/CPAN/Config.pm> as
F<${installprivlib}/CPAN/Config.pm>. Here such paths 
are called I<p5-paths> and hence the name of the module.

By default, we consider the following C<Config> variables:

   installarchlib archlib installprivlib privlib 
   installsitearch installsitelib sitelib sitelib_stem
   installvendorarch installvendorlib vendorlib vendorlib_stem

Some of these can be empty (C<undef>, C<''>, and so on)
and some can hold the same value. For example, in a typical
Windows installation, there are only two different paths,
one for I<core> libs and another for I<site> libs.
We deal with such cases by discarding empty variables
and considering only the first variable in the same
order shown above. 

That is, in a Cygwin installation where the following
configuration was found:

	installarchlib    = /usr/lib/perl5/5.8/cygwin
	archlib           = /usr/lib/perl5/5.8/cygwin
	installprivlib    = /usr/lib/perl5/5.8
	privlib           = /usr/lib/perl5/5.8
	installsitearch   = /usr/lib/perl5/site_perl/5.8/cygwin
	installsitelib    = /usr/lib/perl5/site_perl/5.8
	sitelib           = /usr/lib/perl5/site_perl/5.8
	sitelib_stem      = /usr/lib/perl5/site_perl/5.8
	installvendorarch = /usr/lib/perl5/vendor_perl/5.8/cygwin
	installvendorlib  = /usr/lib/perl5/vendor_perl/5.8
	vendorlib         = /usr/lib/perl5/vendor_perl/5.8
	vendorlib_stem    = /usr/lib/perl5/vendor_perl/5.8

only the following are used to resolve literal paths into p5-paths:

	installarchlib    = /usr/lib/perl5/5.8/cygwin
	installprivlib    = /usr/lib/perl5/5.8
	installsitearch   = /usr/lib/perl5/site_perl/5.8/cygwin
	installsitelib    = /usr/lib/perl5/site_perl/5.8
	installvendorarch = /usr/lib/perl5/vendor_perl/5.8/cygwin
	installvendorlib  = /usr/lib/perl5/vendor_perl/5.8

=over 4

=item B<p5path_to_path>

    $path = p5path_to_path($p5path)

Translates from p5-paths to ordinary paths. It is done
by merely replacing the match of pattern C</^\$\{(\w+)\}/>
with C<$Config{$1}>. 

=item B<path_to_p5path>

    $p5path = path_to_p5path($path)
	$p5path = path_to_p5path($path, install_vars => $arrayref)

Resolves an ordinary path to a p5-path. This is done
by trying to match C<$Config{$ivar}> to the start of
the path for each $ivar on
a list of C<Config> variables (named installation variables
due to their relation to Perl 5 installation paths). 
At the first match, it replaces the prefix with 
C<"\$\{$ivar\}">. 

The list of C<Config> variables is given by the array ref
given by option I<install_vars> or by a reference to
the package variable
C<@Module::Which::P5Path::DEFAULT_IVARS> which holds

   installarchlib archlib installprivlib privlib 
   installsitearch installsitelib sitelib sitelib_stem
   installvendorarch installvendorlib vendorlib vendorlib_stem

in this order. 

This function is smart enough to discount 
case-tolerance of certain filesystems when trying to
match a prefix to a path. 

=item B<path_to_p5>

	$p5path = path_to_p5($path)
	($p5path, $p5base) = path_to_p5($path)

Works just like C<path_to_p5path> but, in list context,
returns also the p5-base. For example, given
C<$Config{installarchlib} eq '/usr/local/lib/perl5'>,

    ($p5path, $p5base) = path_to_p5('/usr/local/lib/perl5/M.pm')

assigns C<'${installarchlib}/M.pm'> to C<$p5path> and
C<'${installarchlib}/'> to C<$p5base>. Beware of this behavior
when calling functions that are not prototyped 
and list operators.

    print "p5-path: ", path_to_p5('/usr/local/lib/perl5/M.pm'), "\n"

prints C<"p5-path: ${installarchlib}/M.pm${installarchlib}/">
rather than C<"p5-path: ${installarchlib}/M.pm"> that would be
generated by

    print "p5-path: ", scalar path_to_p5('/usr/local/lib/perl5/M.pm'), "\n"

=back

=begin comment

SAMPLES

Cygwin ---------------

$ perl -v
This is perl, v5.8.6 built for cygwin-thread-multi-64int

$ perl -e '$" = "\n"; print "@INC"'
/usr/lib/perl5/5.8/cygwin
/usr/lib/perl5/5.8
/usr/lib/perl5/site_perl/5.8/cygwin
/usr/lib/perl5/site_perl/5.8
/usr/lib/perl5/site_perl/5.8
/usr/lib/perl5/vendor_perl/5.8/cygwin
/usr/lib/perl5/vendor_perl/5.8
/usr/lib/perl5/vendor_perl/5.8

Linux ----------------

# perl -v
This is perl, version 5.005_03 built for i386-linux

# perl -e '$" = "\n"; print "@INC"'
/usr/lib/perl5/i386-linux
/usr/lib/perl5
/usr/lib/perl5/site_perl/i386-linux
/usr/lib/perl5/site_perl

HP-UX ----------------

r11:/u01/r11>/usr/local/bin/perl -v
This is perl, v5.8.3 built for PA-RISC2.0

r11:/u01/r11>/usr/local/bin/perl -e '$" = "\n"; print "@INC"'
/usr/local/lib/perl5/5.8.3/PA-RISC2.0           [installarchlib]
/usr/local/lib/perl5/5.8.3                      [installprivlib]
/usr/local/lib/perl5/site_perl/5.8.3/PA-RISC2.0 [installsitearch]
/usr/local/lib/perl5/site_perl/5.8.3            [installsitelib]
/usr/local/lib/perl5/site_perl                  

# arch priv site vendor
qw(installarchlib archlib installprivlib privlib installsitelib sitelib installvendorlib vendorlib) 

r11:/u01/r11>/usr/local/bin/perl -V:inst.*
installarchlib='/usr/local/lib/perl5/5.8.3/PA-RISC2.0'
installprivlib='/usr/local/lib/perl5/5.8.3'
installprefix='/usr/local'
installprefixexp='/usr/local'
installscript='/usr/local/bin'
installsitearch='/usr/local/lib/perl5/site_perl/5.8.3/PA-RISC2.0'
installsitelib='/usr/local/lib/perl5/site_perl/5.8.3'
installsitescript='/usr/local/bin'
installstyle='lib/perl5'
installusrbinperl='undef'
installvendorarch=''
installvendorlib=''
installvendorscript=''

===

>perl -v
This is perl, version 4.0

> perl -e '$" = "\n"; print "@INC"'
/usr/local/lib/perl

====

> perl -v
This is perl, version 5.003 with EMBED

r11:/u01/r11>/u01/app/oracle/product/8.0.6/ows/3.0/perl/bin/perl  -e '$" = "\n"; print "@INC"'
/mnt/was302/SRC/exp/cartxs/src/perl/lib/PA-RISC/5.003
/mnt/was302/SRC/exp/cartxs/src/perl/lib
/mnt/was302/SRC/exp/cartxs/src/perl/lib/site_perl/PA-RISC
/mnt/was302/SRC/exp/cartxs/src/perl/lib/site_perl

Windows ------------------

>perl -e "$\" = qq{\n}; print qq{@INC}"
C:/tools/PXPerl/lib
C:/tools/PXPerl/site/lib

>perl -e "$\" = qq{\n}; print qq{@INC}"
c:/tools/Perl/lib
c:/tools/Perl/site/lib

=end comment
