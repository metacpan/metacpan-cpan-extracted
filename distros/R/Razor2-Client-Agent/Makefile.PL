#!/usr/bin/perl -s
##
## Makefile for Vipul's Razor v2.
##
## Copyright (c) 1998-2002
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Makefile.PL,v 1.30 2007/05/08 22:47:53 rsoderberg Exp $

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME          => 'Razor2::Client::Agent',
    AUTHOR        => 'Vipul Ved Prakash <mail@vipul.net>',
    ABSTRACT      => 'Collaborative, content-based spam filtering network agent.',
    VERSION_FROM  => 'lib/Razor2/Client/Version.pm', 
    EXE_FILES     => [ qw( bin/razor-client bin/razor-admin bin/razor-check bin/razor-report bin/razor-revoke ) ], 
    PREREQ_PM     => { 
                       'Digest::SHA1'     => 0,
                       'File::Copy'       => 0,
                       'File::Spec'       => 0,
                       'Getopt::Long'     => 0,
                       'MIME::Base64'     => 0,
                       'Test::More'       => 0,
                       'Time::HiRes'      => 0,
                       'URI::Escape'      => 0,
                     },
	MAN1PODS      => { 
                       'docs/razor-check.pod'    => '$(INST_MAN1DIR)/razor-check.1',
                       'docs/razor-report.pod'   => '$(INST_MAN1DIR)/razor-report.1',
                       'docs/razor-admin.pod'    => '$(INST_MAN1DIR)/razor-admin.1',
                       'docs/razor-revoke.pod'   => '$(INST_MAN1DIR)/razor-revoke.1',
                     },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Razor2-Client-Agent*' },
    META_MERGE  => {
        build_requires => {
            'Test::More' => 0,  # For testing
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://razor.sourceforge.net/',
            bugtracker => 'http://sourceforge.net/projects/razor',
            repository => 'http://github.com/toddr/Razor2-Client-Agent',
            MailingList => 'https://sourceforge.net/mailarchive/forum.php?forum_name=razor-users',
        },
    },
);

{
package MY;

sub constants {

    my $self = shift;
    my $inherited = $self->SUPER::constants(@_);

    my $prefix = $ExtUtils::MakeMaker::VERSION >= 6.18 ? 'SITEPREFIX' : 
                                                         'PERLPREFIX';

    my $man5 = sprintf <<'MAKE', $prefix;

# begin razor-agents
MAN5PODS = docs/razor-agent.conf.pod \
	   docs/razor-whitelist.pod  \
	   docs/razor-agents.pod
INST_MAN5DIR = blib/man5
INSTALLMAN5DIR = $(DESTDIR)$(PREFIX)/share/man/man5
INSTALLSITEMAN5DIR = $(DESTDIR)$(SITEPREFIX)/share/man/man5
INSTALLVENDORMAN5DIR = $(DESTDIR)$(VENDORPREFIX)/share/man/man5
MAN5EXT = 5
# end razor-agents

MAKE

    return $inherited . $man5;

}


sub MY::top_targets {

    use Config;

    my $self = shift;
    my $inherited = $self->SUPER::top_targets(@_);

    my ($perlh) = $self->catfile($Config{archlibexp}, 'CORE', "perl.h");

    my $noecho = q{NOECHO = @} unless $inherited =~ /NOECHO/;

    my $man5 = sprintf <<'MAKE_FRAG', $perlh, $perlh;

# begin razor-agents
config :: $(INST_MAN5DIR)/.exists
	@$(NOOP)

$(INST_MAN5DIR)/.exists :: %s
	@$(MKPATH) $(INST_MAN5DIR)
	@$(EQUALIZE_TIMESTAMP) %s $(INST_MAN5DIR)/.exists
	-@$(CHMOD) $(PERM_RWX) $(INST_MAN5DIR)
# end razor-agents

MAKE_FRAG

    return $inherited . $man5;
}


sub MY::manifypods {
    my $self = shift;
    my $inherited = $self->SUPER::manifypods(@_);

    $inherited =~ s{^(manifypods : .*)\\}{$1 manifypods-razor \\}m;

    # MakeMaker 6.06_x through 6.13 eliminated the POD2MAN macro.
    my $pod2man = $inherited =~ /^POD2MAN\b/m ? ''
                                              : 'POD2MAN = $(POD2MAN_EXE)';

    my $manifypods_razor = sprintf <<'MAKE_FRAG', $pod2man;

# begin razor-agents
%s

manifypods-razor : docs/razor-agent.conf.pod \
	docs/razor-agents.pod                \
	docs/razor-whitelist.pod
	$(POD2MAN) \
	docs/razor-agent.conf.pod \
	$(INST_MAN5DIR)/razor-agent.conf.$(MAN5EXT) \
	docs/razor-agents.pod \
	$(INST_MAN5DIR)/razor-agents.$(MAN5EXT) \
	docs/razor-whitelist.pod \
	$(INST_MAN5DIR)/razor-whitelist.$(MAN5EXT)

#end razor-agents
MAKE_FRAG

    return $inherited . "\n" . $manifypods_razor;

}


sub MY::install {

  my $self = shift;
  my $inherited = $self->SUPER::install(@_);

  my $man5 = q{ \\
		$(INST_MAN5DIR) $(INSTALLMAN5DIR)};

  $inherited =~ s/(\$\((?:DEST)?INSTALL\w*MAN1DIR\))/$1$man5/gm;

  return $inherited;
}

}
