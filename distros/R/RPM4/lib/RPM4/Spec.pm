##- Nanar <nanardon@zarb.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$

package RPM4::Spec;

use strict;
use warnings;

use RPM4;
use RPM4::Transaction::Problems;

sub rpmbuild {
    my ($spec, $flags, %options) = @_;

    $options{db} ||= RPM4::newdb();

    my ($f) = $flags =~ /^(?:-)?b([pcibas])/;
    $f or die "Unknown build options '$flags', should be b[pciabs]\n";
    my @buildflags;
    for (qw/p c i/) {
        $options{shortcircuit} && $f ne $_ and next;
        /^p$/ and push (@buildflags, "PREP");
        /^c$/ and push (@buildflags, "BUILD");
        /^l$/ and push (@buildflags, "FILECHECK");
        /^i$/ and push (@buildflags, qw/INSTALL CHECK/);
        $f eq $_ and last;
    }
    for ($f) {
        /^a$/ and push(@buildflags, qw/PACKAGESOURCE PACKAGEBINARY/);
        /^b$/ and push(@buildflags, qw/PACKAGEBINARY/);
        /^s$/ and push(@buildflags, qw/PACKAGESOURCE/);
    }
    $options{clean} and push(@buildflags, qw/RMBUILD RMSOURCE/);
    $options{rmspec} and push(@buildflags, qw/RMSPEC/);


    if (!$options{nodeps}) {
        my $sh = $spec->srcheader() or die "Can't get source header from spec object"; # Can't happend
        $options{db}->transadd($sh, "", 0);
        $options{db}->transcheck;
        my $pbs = RPM4::Transaction::Problems->new($options{db});
        $options{db}->transreset();
        if ($pbs) {
            $pbs->print_all(\*STDERR);
            return 1;
        }
    }
    return $options{db}->specbuild($spec, [ @buildflags ]);
}

1;

__END__

=head1 NAME

RPM4::Spec

=head1 SYNOPSIS

=head1 DESCRIPTION

Extend method availlable on RPM4::Spec objects

=head1 METHODS

=head2 new(file, var => value, ...)

Create a C<RPM4::Spec> instance, only the file values is mandatory.

=over 4

=item file

The spec file from wich to create the object

=item passphrase

If specified, the passphrase will be used for gpg signing after build.

=item rootdir

If specified, root dir will be use root instead '/'.

=item cookies

the cookies is string rpm will put into RPMCOOKIES tag, a way to know if a rpm
has been built from a specific src. You get this value from L<installsrpm>.

=item anyarch

If set, you'll get a spec object even the spec can't be build on the
current %_target_cpu. Notice if you set this value, starting a build over
the spec object will works !

=item force

Normally, source analyze is done during spec parsing, getting a spec object
failed if a source file is missing, else you set force value.

TAKE CARE: if force is set, rpm will not check source type, so patch will NOT
be gunzip/bunzip... If you want to compile the spec, don't set it to 1, if you
just want run clean/packagesource stage, setting force to 1 is ok.

=back

By default anyarch and force are set to 0.

=head2 RPM4::Spec->srcheader()

Returns a RPM4::Header object like source rpm will be.
Please notice that the header is not finish and header information you'll
get can be incomplete, it depend if you call the function before or after
RPM4::Spec->build().

=head2 RPM4::Spec->srcrpm()

Returns the source filename spec file will build. The function take care
about rpmlib configuration (build dir path).

=head2 RPM4::Spec->binrpm()

Returns files names of binaries rpms that spec will build. The function take
care about rpmlib configuration (build dir path).

=head2 RPM4::Spec->build([ @actions ])

Run build process on spec file.
Each value in @actions is one or more actions to do:

  - PACKAGESOURCE: build source package,
  - PREP: run prep stage,
  - BUILD: run build stage,
  - INSTALL: run install stage,
  - CHECK: check installed files,
  - FILECHECK: check installed files,
  - PACKAGEBINARY: build binaries packages,
  - CLEAN: run clean stage,
  - RMSPEC: delete spec file,
  - RMSOURCE: delete sources files,
  - RMBUILD: delete build files,

=head2 rpmbuild($flags, %options)

Build a spec using rpm same rpm options.

$flags should be -b[abspci]

%options is a list of optionnal options:

=over 4

=item db 

reuse an already existing RPM4::Db object (else a new one is created)

=item clean

if set, clean source and build tre (like rpmbuild --clean

=item rmspec

if set, delete the spec after build (like rpmbuild --rmspec)

=item nodeps

If set, don't check dependancies before build

=item shortcircuit

if set, run only the build stage asked, not all preceding (like rpmbuild
--short-circuit)

=back

=head1 SEE ALSO

L<RPM4>

=cut
