# -*- perl -*-

# Net::FTPServer A Perl FTP Server
# Copyright (C) 2000 Bibliotech Ltd., Unit 2-3, 50 Carnwath Road,
# London, SW6 3EG, United Kingdom.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use ExtUtils::MakeMaker;

# PREREQ_PM is crap! It doesn't enforce the prerequisites, and
# doesn't print an intelligible error message. Nor does it understand
# that some modules are optional, while others are absolutely
# required. Do our own prerequisite checking here. A lot of this
# code was borrowed from the Makefile.PL supplied with libwww-perl.
#
# NB. 'status' field is either 'required', for modules which are
# required, or anything else for modules which are optional.

# OS check
if( $^O eq 'MSWin32' ){
    printf STDERR "No support for OS $^O.\n";
    #This message should be exact: http://wiki.cpantesters.org/wiki/CPANAuthorNotes
    exit 1;
}

my %modules
  = (
     'Archive::Zip' =>
     { status => "optional",
       version => "0.11",
       message =>
       "Archive::Zip is missing. This module is required if you want to\n".
       "enable archive mode, which allows users to create ZIP files on\n".
       "the fly from directories on the server.\n"
     },
     'Authen::PAM' =>
     { status => "recommended",
       version => "0.12",
       message =>
       "Authen::PAM is missing. This module is required in order to\n".
       "perform user authentication against the full FTP server\n".
       "personality on most Unix platforms. Therefore unless you install\n".
       "this module, normal FTP server configurations will most likely\n".
       "not work.\n"
     },
     'BSD::Resource' =>
     { status => "highly recommended",
       message =>
       "BSD::Resource is missing. This module is required in order to\n".
       "place limits on the size of the FTP server process. Without this\n".
       "module, the FTP server will still work, but it will be vulnerable\n".
       "to certain sorts of denial of service (DoS) attacks.\n"
     },
     'Carp' => { status => "required" },
     'Compress::Zlib' =>
     { status => "optional",
       version => "1.14",
       message =>
       "Compress::Zlib is missing. This module is required if you want to\n".
       "enable archive mode, which allows users to create ZIP files on\n".
       "the fly from directories on the server.\n"
     },
     'DBI' =>
     { status => "optional",
       message =>
       "DBI is missing. if you want to run the FTP server against a\n".
       "PostgreSQL database.\n"
     },
     'Digest::MD5' =>
     { status => "optional",
       message =>
       "Digest::MD5 is missing. This module is required in order for the\n".
       "SITE CHECKSUM command to work.\n"
     },
     'DynaLoader' => { status => "required" },
     'Fcntl' => { status => "required" },
     'File::Sync' =>
     { status => "optional",
       message =>
       "File::Sync is missing. The SITE SYNC command will not work.\n"
     },
     'File::Temp' =>
     { status => "option",
       message =>
       "File::Temp is missing. This is required for the proxy server.\n"
     },
     'Getopt::Long' => { status => "required" },
     'IO::Dir' => { status => "required", package => "IO" },
     'IO::File' => { status => "required", package => "IO" },
     'IO::Handle' => { status => "required", package => "IO" },
     'IO::Scalar' => { status => "required", package => "IO-stringy",
		       version => "1.126" },
     'IO::Seekable' => { status => "required" },
     'IO::Select' => { status => "required", package => "IO" },
     'IO::Socket' => { status => "required", package => "IO" },
     'IPC::Open2' => { status => "required" },
     'Net::FTP' =>
     { status => "optional",
       message =>
       "Net::FTP is missing. This is required for the proxy server.\n"
     },
     'POSIX' => { status => "required" },
     'Socket' => { status => "required" },
     'Sys::Hostname' => { status => "required" },
     'Sys::Syslog' => { status => "required" },
     'Test::More' => { status => "required" },
    );

$| = 1;

# Check for modules.

my $missing_modules = 0;
my $missing_required_modules = 0;

foreach (sort keys %modules)
  {
    print "Checking for $modules{$_}{status} ";
    print "module $_ ";
    print ">= $modules{$_}{version} " if $modules{$_}{version};
    print "... ";

    my $eval = "require $_; ";
    $eval .= "$_->VERSION >= $modules{$_}{version}" if $modules{$_}{version};

    my $r = eval $eval;
    if ($@ || !$r)
      {
	$missing_modules++;
	$missing_required_modules++ if $modules{$_}{status} eq "required";

	print "not found.\n\n";

	if (exists $modules{$_}{package})
	  {
	    print
	      "This module is provided by the $modules{$_}{package} ",
	      "package.\n\n";
	  }

	sleep 1 unless $ENV{NET_FTPSERVER_NO_SLEEP};

	if (exists $modules{$_}{message})
	  {
	    print "*** ", $modules{$_}{message}, "\n";
	    sleep 5 unless $ENV{NET_FTPSERVER_NO_SLEEP};
	  }

      }
    else
      {
	print "ok.\n";
      }
  }

print "\n";

if ($missing_modules)
  {
    print <<EOT;
Obtain missing modules from CPAN [http://www.cpan.org/].

EOT
    sleep 2 unless $ENV{NET_FTPSERVER_NO_SLEEP};
  }

if ($missing_required_modules)
  {
    print <<EOT;
Required modules are missing. Install these first.

EOT
    exit 1;
  }

# The code has only been verified on versions of Perl >= than
# the following. If you find an earlier version of Perl on which
# Net::FTPServer runs, please tell me. - rich@annexia.org.
if ($] < 5.00405)
  {
    print <<EOT;
Perl version >= 5.00405 is required.

EOT
    exit 1;
  }

my @args = (
	    NAME => "Net::FTPServer",
	    VERSION_FROM => "lib/Net/FTPServer.pm",

	    # Install start-up scripts under /usr/sbin.
	    EXE_FILES => [ 'bin/dbeg1-ftpd.pl',
			   'bin/ftpd.pl',
			   'bin/inmem-ftpd.pl',
			   'bin/proxy-ftpd.pl',
			   'bin/ro-ftpd.pl' ],
	    INSTALLSCRIPT => $ExtUtils::MakeMaker::VERSION < 5.45 ?
	    '$(PREFIX)/sbin' : # No SITEPREFIX before Perl 5.6.0
	    '$(SITEPREFIX)/sbin',

	    dist =>
	    {
	     COMPRESS => 'gzip --force --best',
#	     PREOP => 'cp Net-FTPServer.spec $(DISTVNAME)',
	    },

	    clean =>
	    {
	     FILES => '*.bak *~',
	    },

	    realclean =>
	    {
#	     FILES => 'Net-FTPServer.spec',
	    },

	    depend =>
	    {
#	     dist => 'Net-FTPServer.spec',
	     #'Net-FTPServer.spec' => "lib/Net/FTPServer.pm",
	     #Makefile => "lib/Net/FTPServer.pm",
	    },

	    # Despite what I say about PREREQ_PM above, we need it to
	    # satisfy various automatic tools, eg. CPAN.
	    PREREQ_PM   =>
	    {
	     'BSD::Resource'    => '0',
	     'Carp'		=> '0',
	     'DynaLoader'	=> '0',
	     'Fcntl'		=> '0',
	     'Getopt::Long'	=> '0',
	     'IO::Dir'		=> '0',
	     'IO::File'		=> '0',
	     'IO::Handle'	=> '0',
	     'IO::Scalar'	=> 1.126,
	     'IO::Seekable'	=> '0',
	     'IO::Select'	=> '0',
	     'IO::Socket'	=> '0',
	     'IPC::Open2'	=> '0',
	     'POSIX'		=> '0',
	     'Socket'		=> '0',
	     'Sys::Hostname'	=> '0',
	     'Sys::Syslog'	=> '0',
	    },
	    BUILD_REQUIRES => {
	      'Test::More'	=> '0',
	    },

	    LICENSE => 'gpl',
	    MIN_PERL_VERSION => '5.005',
	    META_MERGE => {
	      resources => {
	        repository => 'https://github.com/ryochin/p5-net-ftpserver',
	      },
	    },
);

WriteMakefile1(@args);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.58) {
    $params{META_ADD}->{author}=$params{AUTHOR};
    $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}


package MY;

sub processPL
  {
    my $self = shift;
    my $block = $self->SUPER::processPL(@_);
    # "Version:" in spec needs to match
    # "$VERSION" from VERSION_FROM
    $block =~ s%(spec.PL\s*)$%$1 \$\(VERSION_FROM\)%m;
    $block;
  }

sub libscan
  {
    my ($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
  }

sub postamble
  {
    '
sysconfdir	= $(DESTDIR)/etc

check-manifest:
	@for d in `find -type d -name CVS`; \
	do \
	b=`dirname $$d`/; \
	awk -F/ \'$$1 != "D" {print $$2}\' $$d/Entries | \
	sed -e "s|^|$$b|" -e "s|^\./||"; \
	done | sort > .check-manifest; \
	sort MANIFEST > .orig-manifest; \
	diff -u .orig-manifest .check-manifest; \
	rm -f .orig-manifest .check-manifest

install ::
	@if [ ! "${NOCONF}" ]; then \
	  if [ -w `dirname $(sysconfdir)` ]; then \
	    mkdir -p $(sysconfdir); \
	    if [ -w $(sysconfdir) ]; then \
	      if [ ! -f $(sysconfdir)/ftpd.conf ]; then \
	        install -c -m 0644 etc/ftpd.conf $(sysconfdir)/ftpd.conf; \
	        echo "Installing $(sysconfdir)/ftpd.conf"; \
	      else \
	        install -c -m 0644 etc/ftpd.conf $(sysconfdir)/ftpd.conf.dist; \
	        echo "Old configuration file $(sysconfdir)/ftpd.conf not overwritten."; \
	        echo "New configuration file installed as $(sysconfdir)/ftpd.conf.dist"; \
	      fi; \
	    fi; \
	  else \
	    echo "notice: ftpd.conf was not installed because you don\'t have write permission to $(sysconfdir)."; \
	  fi; \
	fi
	@echo
	@echo "Net::FTPServer has been installed. Before proceeding please"
	@echo "read the manual page. Type:"
	@echo
	@echo "  man Net::FTPServer"
	@echo
';
  }

__END__
