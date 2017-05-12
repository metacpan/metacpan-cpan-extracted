package PPM::Repositories;

use strict;
use warnings;

use Config qw(%Config);

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(%Repositories);
our @EXPORT_OK = qw(get list used_archs);
our $VERSION = '0.20';

my %Default = (
    Type   => 'Webpage',
    Active => 1,
    PerlV  => [ 5.8 ],
    PerlO  => ['MSWin32'],
);

our %Repositories = (
    bioperl => {
        location => 'http://bioperl.org/DIST/',
        Notes    => 'BioPerl - Regular Releases',
        PerlV    => [ 5.8, '5.10' ],
    },
    'bioperl-rc' => {
        location => 'http://bioperl.org/DIST/RC/',
        Notes    => 'BioPerl - Releases Candidates',
        PerlV    => [ 5.8, '5.10' ],
    },
    bribes => {
        location => 'http://www.bribes.org/perl/ppm/',
        Notes    => 'Bribes de Perl',
        PerlV    => [ 5.6, 5.8, '5.10', 5.12, 5.14, 5.16, 5.18 ],
    },
    gtk2 => {
        location => 'http://www.lostmind.de/gtk2-perl/ppm/',
        Notes    => 'gtk2-perl bindings (check also \'voltar\' repository)',
    },
    'gtk2-old' => {
        location => 'http://gtk2-perl.sourceforge.net/win32/ppm/',
        Notes    => 'Old "official" Gtk2 repository',
    },
    log4perl => {
        location => 'http://log4perl.sourceforge.net/ppm',
        Notes    => 'log4perl (pure perl)',
        PerlV    => [ ],
        PerlO    => ['perl'],
    },
    roth => {
        location => 'http://www.roth.net/perl/packages/',
        Notes    => 'Dave Roth\'s modules',
        PerlV    => [ 5.6, 5.8 ],
    },
    sisyphusion => {
        location => 'http://www.sisyphusion.tk/ppm/',
        Notes    => 'Math, PDL, Gtk2 and other ad hoc',
        PerlV    => [ 5.6, 5.8, '5.10', 5.12, 5.14, 5.16, 5.18 ],
    },
    'tcool-ppm3' => {
        location => 'http://ppm.tcool.org/server/ppmserver.cgi?urn:PPMServer',
        Type     => 'PPMServer',
        Notes    => 'Kenichi Ishigaki\'s repository (PPM3))',
    },
    tcool => {
        location => 'http://ppm.tcool.org/archives/',
        Notes    => 'Kenichi Ishigaki\'s repository (PPM4)',
    },
    trouchelle58 => {
        location => 'http://trouchelle.com/ppm/',
        Notes    => 'Trouchelle: 5.8',
    },
    trouchelle510 => {
        location => 'http://trouchelle.com/ppm10/',
        Notes    => 'Trouchelle: 5.10',
        PerlV    => [ '5.10' ],
    },
    trouchelle512 => {
        location => 'http://trouchelle.com/ppm12/',
        Notes    => 'Trouchelle: 5.12',
        PerlV    => [ 5.12 ],
    },
    trouchelle514 => {
        location => 'http://trouchelle.com/ppm14/',
        Notes    => 'Trouchelle: 5.14',
        PerlV    => [ 5.14 ],
    },
    'uwinnipeg56-ppm3' => {
        location => 'http://theoryx5.uwinnipeg.ca/cgi-bin/ppmserver?urn:/PPMServer',
        Type     => 'PPMServer',
        Notes    => 'University of Winnipeg: 5.6 (PPM3)',
        PerlV    => [ 5.6 ],
    },
    uwinnipeg56 => {
        location => 'http://theoryx5.uwinnipeg.ca/ppmpackages',
        Notes    => 'University of Winnipeg: 5.6',
        PerlV    => [ 5.6 ],
    },
    'uwinnipeg58-ppm3' => {
        location => 'http://theoryx5.uwinnipeg.ca/cgi-bin/ppmserver?urn:/PPMServer58',
        Type     => 'PPMServer',
        Notes    => 'University of Winnipeg: 5.8 (PPM3)',
    },
    uwinnipeg58 => {
        location => 'http://theoryx5.uwinnipeg.ca/ppms',
        Notes    => 'University of Winnipeg: 5.8 (PPM4)',
		Active   => 0,
    },
    uwinnipeg510 => {
        location => 'http://cpan.uwinnipeg.ca/PPMPackages/10xx/',
        Notes    => 'University of Winnipeg: 5.10',
        PerlV    => [ '5.10' ],
		Active   => 0,
    },
    uwinnipeg512 => {
        location => 'http://cpan.uwinnipeg.ca/PPMPackages/12xx/',
        Notes    => 'University of Winnipeg: 5.12',
        PerlV    => [ 5.12 ],
		Active   => 0,
    },
    voltar => {
        location => 'http://voltar.org/active/5.8/',
        Notes    => 'Paul Miller\'s Games::RolePlay::MapGen and Gtk2 repository',
    },
    wxperl => {
        location => 'http://www.wxperl.co.uk/repository',
        Notes    => 'wxPerl modules',
        PerlV    => [ 5.8, '5.10', 5.12, 5.14, 5.16 ],
    },
);

for my $name (keys %Repositories) {
    for my $key (keys %Default) {
	next if $Repositories{$name}{$key};
	$Repositories{$name}{$key} = $Default{$key};
    }
}

#
# * An undef repo URL defaults to the "packlist" value, which
#   in turn defaults to the "home" value.
#
# * The "packlist" and "arch" keys are implementation details
#   and are not exposed outside the module.
#
my %REPO = (
    activestate => {
	home => 'http://ppm.activestate.com/',
	desc => 'Default ActivePerl repository from ActiveState',
	arch => {
	    # filled in below
	},
    },
    bioperl => {
	home => 'http://www.bioperl.org/wiki/Installing_Bioperl_on_Windows',
	desc => 'BioPerl - Regular Releases',
	packlist => 'http://bioperl.org/DIST/',
	arch => {
	    'MSWin32-x86-multi-thread-5.8' => undef,
	    'MSWin32-x86-multi-thread-5.10' => undef,
	},
    },
    'bioperl-rc' => {
	home => 'http://www.bioperl.org/wiki/Installing_Bioperl_on_Windows',
	desc => 'BioPerl - Release Candidates',
	packlist => 'http://bioperl.org/DIST/RC/',
	arch => {
	    'MSWin32-x86-multi-thread-5.8' => undef,
	    'MSWin32-x86-multi-thread-5.10' => undef,
	},
    },
    bribes => {
	home => 'http://www.bribes.org/perl/ppmdir.html',
	desc => 'Bribes de Perl',
	packlist => 'http://www.bribes.org/perl/ppm',
	arch => {
	    'MSWin32-x86-multi-thread' => undef,
	    'MSWin32-x86-multi-thread-5.8' => undef,
	    'MSWin32-x86-multi-thread-5.10' => undef,
	    'MSWin32-x86-multi-thread-5.12' => undef,
	    'MSWin32-x86-multi-thread-5.14' => undef,
	    'MSWin32-x86-multi-thread-5.16' => undef,
	    'MSWin32-x86-multi-thread-5.18-64int' => undef,
	},
    },
    gtk2 => {
	home => 'http://www.lostmind.de/gtk2-perl',
	desc => 'gtk2-perl bindings (check also \'voltar\' repository)',
	packlist => 'http://www.lostmind.de/gtk2-perl/ppm/',
	arch => {
	    'MSWin32-x86-multi-thread-5.8' => undef,
	},
    },
    log4perl => {
	home => 'http://log4perl.sourceforge.net',
	desc => 'log4perl',
	packlist => 'http://log4perl.sourceforge.net/ppm',
	arch => {
	    'noarch' => undef,
	},
    },
    roth => {
	home => 'http://www.roth.net/perl/packages/',
	desc => 'Dave Roth\'s modules',
	arch => {
	    'MSWin32-x86-multi-thread' => undef,
	    'MSWin32-x86-multi-thread-5.8' => undef,
	},
    },
    sisyphusion => {
	home => 'http://www.sisyphusion.tk/ppm/ppmindex.html',
	desc => 'Math, PDL, Gtk2 and other ad hoc',
	packlist => 'http://www.sisyphusion.tk/ppm',
	arch => {
	    'MSWin32-x86-multi-thread' => undef,
	    'MSWin32-x86-multi-thread-5.8' => undef,
	    'MSWin32-x86-multi-thread-5.10' => undef,
	    'MSWin32-x86-multi-thread-5.12' => undef,
	    'MSWin32-x64-multi-thread-5.12' => undef,
	    'MSWin32-x86-multi-thread-5.14' => undef,
	    'MSWin32-x64-multi-thread-5.14' => undef,
	    'MSWin32-x86-multi-thread-5.16' => undef,
	    'MSWin32-x86-multi-thread-5.16-64int' => undef,
	    'MSWin32-x64-multi-thread-5.16' => undef,
	},
    },
    tcool => {
	home => 'http://ppm.tcool.org/intro/register',
	desc => 'Kenichi Ishigaki\'s repository',
	packlist => 'http://ppm.tcool.org/archives/',
	arch => {
	    'MSWin32-x86-multi-thread-5.8' => undef,
	},
    },
    trouchelle => {
	home => 'http://trouchelle.com/perl/ppmrepview.pl',
	desc => 'Trouchelle',
	arch => {
	    'MSWin32-x86-multi-thread-5.8' =>
		'http://trouchelle.com/ppm/',
	    'MSWin32-x86-multi-thread-5.10' =>
		'http://trouchelle.com/ppm10/',
	    'MSWin32-x86-multi-thread-5.12' =>
		'http://trouchelle.com/ppm12/',
	    'MSWin32-x86-multi-thread-5.14' =>
		'http://trouchelle.com/ppm14/',
	},
    },
    uwinnipeg => {
	home => 'http://cpan.uwinnipeg.ca/',
	desc => 'University of Winnipeg',
	arch => {
	    'MSWin32-x86-multi-thread' =>
		'http://theoryx5.uwinnipeg.ca/ppmpackages/',
	    'MSWin32-x86-multi-thread-5.8' =>
		'http://theoryx5.uwinnipeg.ca/ppms/',
	    'MSWin32-x86-multi-thread-5.10' =>
		'http://cpan.uwinnipeg.ca/PPMPackages/10xx/',
	    'MSWin32-x86-multi-thread-5.12' =>
		'http://cpan.uwinnipeg.ca/PPMPackages/12xx/',
	},
    },
    voltar => {
	home => 'http://voltar.org/active/',
	desc => 'Paul Miller\'s Games::RolePlay::MapGen and Gtk2 repository',
	arch => {
	    'MSWin32-x86-multi-thread-5.8' =>
		'http://voltar.org/active/5.8/',
	},
    },
    wxperl => {
	home => 'http://www.wxperl.co.uk/ppm.html',
	desc => 'wxPerl modules',
	packlist => 'http://www.wxperl.co.uk/repository',
	arch => {
	    'MSWin32-x86-multi-thread-5.8'    => undef,
	    'MSWin32-x86-multi-thread-5.10'   => undef,
	    'MSWin32-x86-multi-thread-5.12'   => undef,
	    'MSWin32-x86-multi-thread-5.14'   => undef,
	    'MSWin32-x86-multi-thread-5.16'   => undef,
	    'MSWin32-x64-multi-thread-5.10'   => undef,
	    'MSWin32-x64-multi-thread-5.12'   => undef,
            'MSWin32-x64-multi-thread-5.14'   => undef,
            'MSWin32-x64-multi-thread-5.16'   => undef,
	    'i686-linux-thread-multi-5.8'     => undef,
	    'i686-linux-thread-multi-5.10'    => undef,
	    'i686-linux-thread-multi-5.12'    => undef,
	    'i686-linux-thread-multi-5.14'    => undef,
            'i686-linux-thread-multi-5.16'    => undef,
	    'x86_64-linux-thread-multi-5.10'  => undef,
	    'x86_64-linux-thread-multi-5.12'  => undef,
	    'x86_64-linux-thread-multi-5.14'  => undef,
            'x86_64-linux-thread-multi-5.16'  => undef,
	    'darwin-thread-multi-2level-5.8'  => undef,
	    'darwin-thread-multi-2level-5.10' => undef,
	    'darwin-thread-multi-2level-5.12' => undef,
	    'darwin-thread-multi-2level-5.14' => undef,
	    'darwin-thread-multi-2level-5.16' => undef,
	},
    },
);

# Add URLs for all ActiveState repos
for my $readonly_arch (qw(
                             MSWin32-x64
                             MSWin32-x86
                             darwin
                             i686-linux
                             x86_64-linux
                             sun4-solaris
                             sun4-solaris-64
                        ))
{
    my $arch = $readonly_arch;
    my $fullarch = "$arch-thread-multi";
    $fullarch = "$arch-thread-multi-2level" if $arch =~ /^darwin/;
    $fullarch = "$arch-multi-thread"        if $arch =~ /^MSWin/;

    for my $version (8, 10, 12, 14, 16, 18, 20) {
	# There are no 64-bit 5.8 repositories
        next if $version == 8 && $arch =~ /64/;

        # There are no PPM repos for 5.16 or later for Solaris
        last if $version == 16 && $arch =~ /^sun4-solaris/;

        # Starting with ActivePerl 5.18 all 32-bit builds use 64-bit ints
        if ($version == 18 && $arch =~ /^(MSWin32-x86|i686-linux)$/) {
            $_ .= "-64int" for $arch, $fullarch;
        }

        # There are no 32-bit PPM repos for 5.20 or later for Linux
        last if $version == 20 && $arch eq "i686-linux-64int";

        $REPO{activestate}{arch}{"$fullarch-5.$version"} =
          "http://ppm4.activestate.com/$arch/5.$version/${version}00/";
    }
}

sub _default_arch {
    my $arch = $Config{archname};
    if ($] >= 5.008) {
	$arch .= "-$Config{PERL_REVISION}.$Config{PERL_VERSION}";
    }
    return $arch;
}

sub get {
    my $name = shift;
    return () unless exists $REPO{$name};

    my %repo = %{$REPO{$name}};
    my $arch = shift || _default_arch();

    # Set up "packlist" and "packlist_noarch" keys
    my $packlist = $repo{packlist} || $repo{home};
    delete $repo{packlist};
    if (exists $repo{arch}{$arch}) {
	$repo{packlist} = $repo{arch}{$arch};
	$repo{packlist} ||= $packlist;
    }
    if (exists $repo{arch}{noarch}) {
	$repo{packlist_noarch} = $repo{arch}{noarch};
	$repo{packlist_noarch} ||= $packlist;
    }
    delete $repo{arch};

    return %repo;
}

sub list {
    my $arch = shift || _default_arch();
    return sort grep {
	exists $REPO{$_}{arch}{$arch} or
        exists $REPO{$_}{arch}{noarch}
    } keys %REPO;
}

sub used_archs {
    my %arch;
    $arch{$_} = 1 for map keys %{$REPO{$_}{arch}}, keys %REPO;
    return sort keys %arch;
}

1;

__END__

=head1 NAME

PPM::Repositories - List of Perl Package Manager repositories

=head1 SYNOPSIS

    # Print all repositories for all architectures
    use PPM::Repositories qw(get list used_archs);
    for my $arch (used_archs()) {
        print "$arch\n";
        for my $name (list($arch)) {
	    my %repo = get($name, $arch);
	    next unless $repo{packlist};
	    print "  $name\n";
	    for my $field (sort keys %repo) {
	        printf "    %-12s %s\n", $field, $repo{$field};
            }
	}
    }

=head1 DESCRIPTION

This module contains a list of PPM repositories for Perl 5.6 and later.
For backwards compatibility reasons it exposes the data in 2 different
mechanism.

The new interface uses API functions and is supplied for the benefit
of PPM version 4 and later.  The old interface directly exposes the
%Repositories hash and should be used for PPM version 2 and 3.

=head2 The new interface

The "new" interface is aimed primarily at PPM version 4 users, but also
contains information about Perl 5.6 and 5.8 repositories that can be
used by PPM version 2 and 3.

=over

=item get(NAME, ARCH)

The get() function returns a hash describing the NAME repository
for architecture ARCH. It looks like this:

  (
    home            => 'http://cpan.example.com/',
    desc            => 'Example Repository',
    packlist        => 'http://cpan.example.com/PPMPackages/10xx/',
    packlist_noarch => 'http://cpan.example.com/PPMPackages/noarch/',
  )

The C<home> key provides a URL that will display additional information
about the repository in a browser (for human consumption, not structured
data for any tools).

The C<desc> key contains a description string, giving either a more
verbose description of the repository host, or an indication of the
provided content for more specialized repositories (e.g. C<<
"gtk2-perl bindings" >>).

The C<packlist> key will point to the repository for the architecture
ARCH and will only be defined if the repository supports this
architecture.  Similarly the C<packlist_noarch> key may point to an
architecture-independent repository hosted by the same system.  Either
or both of C<packlist> and C<packlist_noarch> may be undefined.

ARCH will default to the current Perl version and architecture (it is
the same as $Config{archname} under Perl 5.6, and has the major Perl
version appended for later versions, such as "$Config{archname}-5.8"
for Perl 5.8).

The get() function will return an empty list if the repository NAME
does not exist at all.

=item list(ARCH)

The list() function returns a list of names for all repositories that
contain modules for architecture ARCH.  This will include all
repositories providing architecture-independent modules as well.

ARCH will default to the current Perl version and architecture.

=item used_archs()

This function returns a list of all architectures that have at least
one repository recorded in this module.  This list will include the
pseudo-architecture C<noarch> for architecture-independent modules.

=back

=head2 The old interface

The "old" interface is supported mainly for backwards compatibility. It
uses the old structure layout, and continues to list SOAP style
repositories (called "PPMServer") that are no longer supported in PPM
version 4.

=over

=item %Repositories

An example entry in %Repositories looks like:

    bribes => {
        location => 'http://www.bribes.org/perl/ppm/',
        Type     => 'Webpage',
        Active   => 1,
        Notes    => 'Digest::*, Net::Pcap, Win32::* ...',
        PerlV    => [ 5.6, 5.8 ],
        PerlO    => ['MSWin32'],
    },

The meaning of the key/value pairs should be obvious.

Active is either 1, or 0, and it indicates whether or not that
particular repository was reachable and contained ppm packages at the
time this module was released.

PerlO is the value of $^O.  See L<perlport> for a list of values for
this variable.

=back

=head2 EXPORT

%Repositories is exported by default.

get(), list(), and used_archs() are only exported on demand.

=head1 BUGS/ADDITIONS/ETC

Please use https://rt.cpan.org/NoAuth/Bugs.html?Dist=PPM-Repositories
to report bugs, request additions etc.

=head1 AUTHOR

D.H. (PodMaster)

Maintained since 2008 by Jan Dubois <jand@activestate.com>

=head1 LICENSE

Copyright (c) 2003,2004,2005 by D.H. (PodMaster). All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<PPM>, L<PPM::Make>, L<CPANPLUS>, L<CPAN>.

=cut
