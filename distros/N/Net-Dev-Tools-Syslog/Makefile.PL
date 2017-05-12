# -*- mode: perl -*-
# ============================================================================
# $Id: Makefile.PL,v 4.5 2004/03/16 15:51:00 sparsons Exp $
# Makefile for the Perl module Net::Dev::Tools::Syslog.
# Copyright (c) 2006  Scott Parsons <sparsons@cpan.org>
# All rights reserved.
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
# ============================================================================

eval { require 5.6.0 } or die <<'EOD'; 

   Net::Dev Modules requires Perl 5.6.0 and above
   due to use of Net::SNMP

EOD

use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
   AUTHOR        => 'Scott Parsons <sparsons@cpan.org>',
   ABSTRACT      => 'Send, Listen, Parse Syslog messages',
   NAME          => 'Net::Dev::Tools::Syslog',
   DISTNAME      => 'Net-Dev-Tools-Syslog',
   VERSION       => '1.0.0',
   PREREQ_PM     => {
      Time::Local   => '0',
      IO::Socket    => '0',
      Sys::Hostname => '0',
   },
   dist          => { 
      CI       => 'ci -u -m\"Changes for v$(VERSION)\"',
      COMPRESS => 'gzip --best', 
      SUFFIX   => 'gz',
      TAR      => 'tar',
      TARFLAGS => 'cvf', 
   },
);

exit 0;

