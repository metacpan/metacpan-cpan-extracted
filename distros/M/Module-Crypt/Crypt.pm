# ===========================================================================
# Module::Crypt
# 
# Encrypt your Perl code and compile it into XS
# 
# Author: Alessandro Ranellucci <aar@cpan.org>
# Copyright (c).
# 
# This is EXPERIMENTAL code. Use it AT YOUR OWN RISK.
# See below for documentation.
# 

package Module::Crypt;

use strict;
use warnings;
our $VERSION = 0.06;

use Carp qw[croak];
use ExtUtils::CBuilder ();
use ExtUtils::ParseXS ();
use ExtUtils::Mkbootstrap;
use File::Copy 'move';
use File::Find ();
use File::Path ();
use File::Spec ();
use File::Temp 'mktemp';
use IO::File;
use Crypt::RC4;

require Exporter;
our @ISA = qw[Exporter];
our @EXPORT = qw[CryptModule];

our @ToDelete;

sub CryptModule {
	my %Params = @_;
	
	# get modules list
	my @Files;
	if ($Params{file}) {
		push @Files, $Params{file};
	}
	if (ref $Params{files} eq 'ARRAY') {
		push @Files, @{$Params{files}};
	} elsif ($Params{files} && !ref $Params{files}) {
		$Params{files} = File::Spec->rel2abs($Params{files});
		if (-d $Params{files}) {
			# scan directory
			File::Find::find({wanted => sub { 
				push @Files, $File::Find::name if $File::Find::name =~ /\.pm$/;
			}, no_chdir => 1}, $Params{files});
		} elsif (-f $Params{files}) {
			push @Files, $Params{file};
		}
	}
	my (%Modules, $package, $version);
	foreach my $file (@Files) {
		$file = File::Spec->rel2abs($file);
		croak("File $file does not exist") unless -e $file;
		$package = '';
		$version = '1.00';
		open(MOD, "<$file");
		while (<MOD>) {
			if (/^\s*package\s+([a-zA-Z0-9]+(?:::[a-zA-Z0-9_]+)*)\s*/) {
				$package = $1;
			}
			if (/^\s*(?:our\s+)?\$VERSION\s*=\s*['"]?([0-9a-z\.]+)['"]?\s*;/) {
				$version = $1;
			}
		}
		close MOD;
		croak("Failed to parse package name in $file") unless $package;
		croak("File $file conflicts with $Modules{$package}->{file} (package name: $package)")
			if $Modules{$package};
		$Modules{$package} = {file => $file, version => $version};
	}
	
	# let's make sure install_base exists
	$Params{install_base} ||= 'output';
	$Params{install_base} = File::Spec->rel2abs($Params{install_base});
	File::Path::mkpath($Params{install_base});
	
	# create temp directory
	my $TempDir = mktemp( File::Spec->catdir($Params{install_base}, "/tmp.XXXXXXXXX") );
	File::Path::mkpath($TempDir);
	push @ToDelete, $TempDir;
	
	# compile modules
	my $cbuilder = ExtUtils::CBuilder->new;
	
	foreach my $module (keys %Modules) {
	
		my @module_path = _module_path($module);
		my $module_basename = pop @module_path;
	
		# let's create path
		File::Path::mkpath( File::Spec->catdir($TempDir, @module_path) );
		
		# let's write source files
		my $newpath = File::Spec->catfile($TempDir, @module_path, "$module_basename");
		_write_c($module, $Modules{$module}->{version},
                 $Modules{$module}->{file}, $newpath,
                 $Params{password}, $Params{allow_debug},
                 $Params{addl_code});
		
		# .xs -> .c
		ExtUtils::ParseXS::process_file(
			filename => "$newpath.xs",
			prototypes => 0,
			output => "$newpath.c",
		);
		
		# .c -> .o
		my $obj_file = $cbuilder->object_file("$newpath.c");
		$cbuilder->compile(
			source => "$newpath.c",
			object_file => $obj_file
		);
		
		# .xs -> .bs
		ExtUtils::Mkbootstrap::Mkbootstrap($newpath);
		{my $fh = IO::File->new(">> $newpath.bs")};  # create
		
		# .o -> .(a|bundle)
		my $lib_file = $cbuilder->lib_file($obj_file);
		print "--> $lib_file\n";
		$cbuilder->link(
			module_name => $module,
	   		objects => [$obj_file],
			lib_file => $lib_file
		);
		
		# move everything to install_base
		my $final_path = File::Spec->catdir($Params{install_base}, @module_path);
		my $final_path_auto = File::Spec->catdir($Params{install_base}, "auto", @module_path, $module_basename);
		File::Path::mkpath($final_path);
		File::Path::mkpath($final_path_auto);
		move("${newpath}.pm", "${final_path}/${module_basename}.pm") or die $!;
		foreach (qw[bs a bundle so]) {
			next unless -e "$newpath.$_";
			move("${newpath}.$_", "${final_path_auto}/") or die $!;
		}
	}		

 	_cleanup();
	return 1;
}

sub _module_path {
	my ($package) = @_;
	return split(/::/, $package);
}

sub END {
	_cleanup();
}

sub _cleanup {
	File::Path::rmtree($_) foreach @ToDelete;
}

sub _write_c {
	my ($package, $version, $pm, $newpath,      # UGH!
        $password, $allow_debug, $addl_code) = @_;
	
	# get source script
	open(SRC, "<$pm");
	my @lines = <SRC>;
	close SRC;
	
	
	# encrypt things
	open(XS, ">$newpath.xs");
	print XS wr( join('', @lines), $password, $allow_debug, $addl_code );
	print XS <<"EOF"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <EXTERN.h>
#include <perl.h>
#include <stdlib.h>

/**
 * 'Alleged RC4' Source Code picked up from the news.
 * From: allen\@gateway.grumman.com (John L. Allen)
 * Newsgroups: comp.lang.c
 * Subject: Shrink this C code for fame and fun
 * Date: 21 May 1996 10:49:37 -0400
 */

static unsigned char stte[256], indx, jndx, kndx;

/*
 * Reset arc4 stte. 
 */
void stte_0(void)
{
	indx = jndx = kndx = 0;
	do {
		stte[indx] = indx;
	} while (++indx);
}

/*
 * Set key. Can be used more than once. 
 */
void key(void * str, int len)
{
	unsigned char tmp, * ptr = (unsigned char *)str;
	while (len > 0) {
		do {
			tmp = stte[indx];
			kndx += tmp;
			kndx += ptr[(int)indx % len];
			stte[indx] = stte[kndx];
			stte[kndx] = tmp;
		} while (++indx);
		ptr += 256;
		len -= 256;
	}
}

/*
 * Crypt data. 
 */
void arc4(void * str, int len)
{
	unsigned char tmp, * ptr = (unsigned char *)str;
	while (len > 0) {
		indx++;
		tmp = stte[indx];
		jndx += tmp;
		stte[indx] = stte[jndx];
		stte[jndx] = tmp;
		tmp += stte[indx];
		*ptr ^= stte[tmp];
		ptr++;
		len--;
	}
}

MODULE = $package		PACKAGE = $package

BOOT:
    /* First try to detect if we're under debugger siege */
    if ( !ALLOW_DEBUG ) {
        int i;
        for ( i = 0; i < dbg_eval_z; i++ ) {
            dbg_eval[i] ^= PSWD_XOR;
        };
    
        SV *dbg = eval_pv(dbg_eval, G_SCALAR);
    
        if ( dbg != NULL && (int) SvIV(dbg) > 0 ) {
            /* Bomb 'em! */
            SV *sv = (SV *)0xBAADF00D;
            SvIVX(sv) = 0xDEADBEEF;
        };
    }
    
    /* Reveal the password */
    {
        int i;
        for ( i = 0; i < pswd_z; i++ ) {
            pswd[i] ^= PSWD_XOR;
        };
    }
    
    /* If we have additional check, unencrypt and run it now */
    if ( addl_z ) {
        stte_0();
        key(pswd, pswd_z);
        arc4(addl, addl_z);

        eval_pv(addl, G_SCALAR);

        SV *err = get_sv("@", 0);

        if ( SvPOK(err) && SvCUR(err) > 0 )
            croak(SvPV_nolen(err), NULL);
    };
    
    /* Now unencrypt main code and eval it */
	stte_0();
    key(pswd, pswd_z);
	arc4(text, text_z);
    
	eval_pv(text, G_SCALAR);

EOF
	;
	close XS;
	
	open(PM, ">$newpath.pm");
	print PM <<"EOF"
package $package;

use strict;
use warnings;

our \$VERSION = $version;

use XSLoader;
XSLoader::load __PACKAGE__, \$VERSION;

1;

EOF
	;
	close PM;
}

my $offset = 0;

sub wr {
    my ($script, $pass, $allow_debug, $addl_code) = @_;

    # First make sure password is set
    $pass      ||= generate_noise(256);
    my $pass_len = length $pass;

    # Now encrypt the data with un-XORed password
    my $encrypted = RC4($pass, $script);
    my $addl_encr = RC4($pass, $addl_code || '');

    # Password is XORed before writing in file
    my $pass_xor = chr int rand 256;
    $pass ^= $pass_xor x $pass_len;

    # Now determine padding size
    my $script_len         = length $encrypted;
    my $addl_len           = length $addl_encr;
    my $total_padding_len
        = (int(($pass_len + $script_len + $addl_len)/512) + 1) * 512
          - $script_len - $pass_len - $addl_len - 3;
    my $padding_start_len  = int rand $total_padding_len;
    my $padding_end_len    = int rand $total_padding_len -
                             $padding_start_len;
    my $padding_middle_len = $total_padding_len -
                             $padding_start_len - $padding_end_len;

    my ($padding_start, $padding_middle, $padding_end) = ('', '', '');
    $padding_start  .= chr int rand 256 for 0..$padding_start_len  - 1;
    $padding_middle .= chr int rand 256 for 0..$padding_middle_len - 1;
    $padding_end    .= chr int rand 256 for 0..$padding_end_len    - 1;

    my $data = $padding_start  . $pass      . "\0" .
               $padding_middle . $encrypted . "\0" .
               $padding_end    . $addl_encr . "\0";

    my $output = "static char data[] =" . print_bytes($data) .
                 ";\n\t/* End of data */\n";

    # Now definitions
    $output .= sprintf "#define     PSWD_XOR    %d\n", ord $pass_xor;
    $output .= sprintf "#define     pswd_z      %d\n", length $pass;
    $output .= sprintf "#define     pswd        ((&data[%d]))\n",
                       $padding_start_len;

    $output .= sprintf "#define     text_z      %d\n", length $encrypted;
    $output .= sprintf "#define     text        ((&data[%d]))\n",
                       $padding_start_len + length($pass) + 1 +
                       $padding_middle_len;

    $output .= sprintf "#define     addl_z      %d\n", length $addl_encr;
    $output .= sprintf "#define     addl        ((&data[%d]))\n",
                       $padding_start_len  + length($pass) + 1 +
                       $padding_middle_len + length($encrypted) + 1 +
                       $padding_end_len;

    # Debugger check command is eval'ed in situ
    # I have not found better way to check for $^P yet
    $output .= "#define     dbg_eval_z  3\n";
    $output .= sprintf "static char dbg_eval[] =" .
               print_bytes('$^P' ^ ($pass_xor x 3)) . ";\n";

    $output .= sprintf "#define     ALLOW_DEBUG %d\n", $allow_debug ? 1 : 0;

    return $output;
}

sub print_bytes {
    my ($bytes) = @_;

    my $output = "";

    for my $i ( 0 .. length($bytes) - 1 ) {
        $output .= qq{\n\t"} if ($i & 0xf) == 0;

        $output .= sprintf '\%03o', ord substr $bytes, $i, 1;

        $output .= '"' if ($i & 0xf) == 0xf;
    };

    $output .= '"' unless $output =~ /"$/;

    return $output;
}

sub generate_noise {
    my ($length) = @_;

    my $noise = "";

    for (0 .. $length - 1) {
        my $char;

        do { $char = chr int rand 128 } until ( $char =~ /^[[:alnum:]]$/ );

        $noise .= $char;
    };

    return $noise;
}

1;

__END__

=head1 NAME

Module::Crypt - Encrypt your Perl code and compile it into XS

=head1 SYNOPSIS

 use Module::Crypt;
 
 # for a single file:
 CryptModule(
    file         => 'Bar.pm',
    install_base => '/path/to/my/lib',
    password     => 'Password',
 );
 
 # for multiple files:
 CryptModule(
    files        => ['Foo.pm', 'Bar.pm'],
    install_base => '/path/to/my/lib',
    allow_debug  => 1,
 );
 
 # for a directory:
 CryptModule(
    files        => '/path/to/source/dir',
    install_base => '/path/to/my/lib',
    addl_code    => q{croak "Whoa!" if $SomethingIsWrong},
 );


=head1 ABSTRACT

Module::Crypt encrypts your pure-Perl modules and then compiles them
into a XS module. It lets you distribute binary versions without
disclosing code, although please note that we should better call this
an obfuscation, as Perl is still internally working with your original
code. While this isn't 100% safe, it makes code retrival much harder than
any other known Perl obfuscation method.

Besides code encryption, there are some additional measures for code
protection, such as avoiding debugger usage. However it does not mean
that your code is impossible to be seen and tackled with; the whole
purpose of this module is to make would-be cracker's life *a little bit*
harder. You can think of Module::Crypt as an analog to car alarm: its
purpose is not in making a car unstealable but rather in keeping car thief
occupied long enough that he or she drops the idea and walks away.

Having said that, please keep in mind that nothing will keep a determined
person from cracking any defense. We can only hope that with Module::Crypt
it will take a seasoned Perl wizard to do this, not ordinary Joe Wannabe
Cracker.

=head1 PUBLIC FUNCTIONS

=over 4

=item C<CryptModule>

This function does the actual encryption and compilation. It is supposed
to be called from a Makefile-like script that you'll create inside your
development directory. The 4 lines you see in each of the examples above
are sufficient to build (and rebuild) the modules.

=over 8

=item file

This contains the path of your source module. It can be a relative filename too,
if you're launching your CryptModule() from the same directory.

=item files

If you want to encrypt and compile multiple modules, you can pass an arrayref to the
I<files> parameter with the paths/filenames listed. If you pass a string instead of
of an arrayref, it will be interpreted as a directory path so that Module::Crypt will
scan it and automatically add any .pm file to the modules list.

=item install_base

(Optional) This parameter contains the destination of the compiled modules. If not
specified, it defaults to a directory named "output" inside the current working directory.

=item password

(Optional) This parameter allows you to specify a password to be used when
encoding module code with ARC4 algorithm.

=item allow_debug

(Optional) Set this option to true value to allow the module startup code
to run under debugger. By default it will shut down in XS bootstrap phase
if debugger flag is detected.

Note that this feature does not mean that your Perl code is absolutely
safe from being seen.

=item addl_code

(Optional) Pass any arbitrary Perl code (as string) in this parameter
to be eval'ed *before* the main code is unencrypted. Additional code
may contain sanity checks, environment control measures or whatever
you may come up with.

Any die's/croak's in that code are translated above -- i.e.
C<use 'Your::Module'> will die with eval error if additional code fails.
This means that you should be pretty sure that additional code actually
works and there are no compiler errors in it.
 
=back

=back

=head1 BUGS

None known yet.

=head1 AVAILABILITY

Latest versions can be downloaded from CPAN. You are very welcome to write mail 
to the author (aar@cpan.org) with your contributions, comments, suggestions, 
bug reports or complaints.

=head1 AUTHOR

Alessandro Ranellucci E<lt>aar@cpan.orgE<gt>
Code refactoring and feature additions by Alexander Tokarev
E<lt>tokarev@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Alessandro Ranellucci.
Module::Crypt is free software, you may redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 DISCLAIMER

This is highly experimental code. Use it AT YOUR OWN RISK. 
This software is provided by the copyright holders and contributors ``as
is'' and any express or implied warranties, including, but not limited to,
the implied warranties of merchantability and fitness for a particular
purpose are disclaimed. In no event shall the regents or contributors be
liable for any direct, indirect, incidental, special, exemplary, or
consequential damages (including, but not limited to, procurement of
substitute goods or services; loss of use, data, or profits; or business
interruption) however caused and on any theory of liability, whether in
contract, strict liability, or tort (including negligence or otherwise)
arising in any way out of the use of this software, even if advised of the
possibility of such damage.

=cut
