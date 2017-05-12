# $File: //depot/libOurNet/OurNet.pm $ $Author: autrijus $
# $Revision: #10 $ $Change: 2112 $ $DateTime: 2001/10/17 05:42:55 $

package OurNet;
use 5.005;

$OurNet::VERSION = '1.60';

use strict;

=head1 NAME

OurNet - Interface to BBS-based groupware platforms

=head1 SYNOPSIS

    # import modules automatically
    use OurNet qw/FuzzyIndex BBS BBSApp/;

    # the rest of code...
    my $BBS = OurNet::BBS->new(@ARGV); # etc

=head1 MODULES

The B<OurNet> line is currently split into two distinct projects:
the I<BBS> and I<Query> suites, represented by the B<Bundle::ebx>
and B<Bundle::Query> on CPAN, respectively.

Note that the old B<OurNet::BBSApp> interface is I<deprecated> as
of OurNet v1.6. We'll work on a set of equivalent module that
could work on the 1.6 series.

Here are a run-down of distributions offered by these two bundles:

In I<OurNet::BBS> distribution:

    BBS		RmpO    Component Object Model for BBS systems

In I<OurNet::BBSApp::Sync> distribution:

    Sync	RmpO    Sync between BBS article groups

In I<OurNet::BBSAgent> distribution:

    BBSAgent	RmpO    Scriptable telnet-based virtual users

In I<OurNet::FuzzyIndex> distribution:

    FuzzyIndex	RmcO    Inverted index for double-byte charsets
    ChatBot	RmpO    Context-free interactive Q&A engine

In I<OurNet::Query> distribution:

    Query	RmpO    Perform scriptable queries via LWP
    Site	RmpO    Extract web pages via templates
    Template	ampO    Template extraction and generation
    WebBuilder	bmpO    HTML rendering for BBS-based services

=head1 SCRIPTS

    bbsboard	Internet to BBS email-post handler	# BBS
    bbsboard	Internet to BBS email-gateway handler	# BBS
    bbscomd	OurNet BBS remote access daemon		# BBS
    ebx		Elixir BBS Exchange Suite		# BBSApp::Sync

    fianjmo	Chat with a virtual personality		# FuzzyIndex
    fzindex	FuzzyIndex index utility		# FuzzyIndex
    fzquery	FuzzyIndex query utility		# FuzzyIndex
    sitequery	Metaseach multiple sites		# Query

=head1 DESCRIPTION

The OurNet:* modules are interfaces to I<Telnet BBS>-based groupware
projects, whose platform was used in Hong Kong, China and Taiwan by
est. 1 million users. Used collaboratively, they glue BBSes together
to form a distributed service network, called B<OurNet>.

This module is merely a bundle over the seperated distributions on
CPAN, so please refer to each individual modules and scripts'
documentation for detailed information.

Please see L<http://melix.elixus.org/> for further references, and
binary releases for Win32 and other platforms.

=head1 WHAT IS THIS TELNET-BBS THING?

Below is an excerpt from Autrijus Tang's lightning talk session in
TPC5, which gives a context of the OurNet development.

=head2 The BBS Culture of Zh-* region

I<Most heavily hacked piece of code>

OurNet is a cross-protocol distributed network built on top of
telnet-based BBS systems, which is used exclusively in the Chinese
speaking world, as they never got translated back. The server code
is 'the' major GPL project in these regions, and was under heavy 
hacking for 8+ years.

I<Who is using it, and for what>

There are est. 2-3 million regular users on thousands of sites,
and many of them doesn't use browser as often; some doesn't use
web at all. Lots of university departments, dorms, organizations 
are running their own BBS sites.

I<The BBS Mindset, or why Web hadn't replaced it (yet)>
 
So for the users, the BBS is "the Unix shell for the rest of us". It
provides public access to services resembling mutt, pine, irsii, talk, 
write, finger, lynx (and MUD), but organized in a consistent text-based
interface. 

People love it because it's real-time, and it perserved the 'community'
flavor of the dial-up BBS era where you feel you're interacting with 
real people, instead of abstracted URLs and e-mails. You'll probably 
understand it better if you came from a dial-up BBS culture.

=head2 Challanges of The Current Model

I<Inflexible Interface & Architecture>

The BBS daemon code in C is comparable in size with the perl5 core, 
and has no clean plug-in interfaces, so things like Tamaguchi gets
implemented like 20 times across 10 different forked versions. Also, 
there's no offline browsing, so you only gets to access your mail 
and usenet news when you're online.

I<Limited Interconnectivity>

The lack of Jabber-like presence and federated authentication presents
another problem -- people have to remember twenty sets of passwords
for different BBS sites, and instant message between these sites are all
but impossible. Also, the only communication between BBS sites are
limited to NNTP and Gopher; there's no frames, RSS, or hyperlinks at 
all.

I<No Privacy Whatsoever>

Of course, sending your password over through a telnet connection
is terrible, as is storing all your private mail and profiles
unencrypted on server. but the real shock is because of this,
governments actualy get to pass laws to say all BBS servers 
have to obtain real name, social security id and phone numbers 
for all users, and keep logs of their activities.

=head2 Perl Comes to Rescue

I<Hybrid Decentralized Authentication>

So, about one year ago I gathered the Taipei.pm people working on 
gluing these isolated nodes together. One thing we tackled is 
the authentication model, in which your identity is just the
GPG or PGP key ID, so we can get all mails one-way encrypted, 
etc. 
   
It couldn't rely on any keyservers since the government could
monitor them, so I'm going to implement "transient mini CA" objects 
that basically get store-and-forwarded in FreeNet and OurNet nodes,
and each server could alias those keyID into their local usernames.

I<The Ultimate Jukebox: telnet://localhost/>

So the new model is that every user installs a transient BBS server
at home, which comes with a unified rendering and object model that 
renders queries from freenet, napster, mailbox, usenet, rss or 
even livejournal. We've also done a locale-enabled full-text 
inverted index engine that could work on all those services.

I<Syndication Everywhere>

There's a couple CPAN modules I've developed over the past year 
that helped making wrappers around existing services. There's 
OurNet::Template, which is a subclass of the Template Toolkit, 
but instead of calling process() with a template file and a 
hash reference of parameters to produce a HTML, you can call 
extract() with a HTML file and template and get the parameter 
hash back! 

We're working on the much more magical generate() function, 
which should take a HTML file and hashref to produce the 
appropriate template. There are also wrappers around telnet 
sessions (OurNet::BBSAgent), slashcode (Slash::OurNet) and 
other plugins that could render syndicated data back and 
forth in an improved, more secure PlRPC protocol that works 
with tied variables.

=head2 What We're Doing Next

I<Agent Deployment and Code Injection>

Since it is now possible to develop bbs components in perl, 
we're working on a system that lets the author sign it and 
distribute it across OurNet, so each node could look at the
source code, run it in a Safe compartment, and if they like
it, they could sign it to vouch for its integrity. 

There should also be ircbot-like agents which could deserialize 
and walk through nodes, and do things like translating requests 
across heterogenous services.

I<Distributed Economy & Moderation>

We're contemplating about how people could use it to form
trust-ring-based economy system like Mojo Nations and Advocado.
Also, we have a reasonable chance to solve the Slash => NNTP
problem now.

I<Bring Power To The Masses>

Currently we're doing i18n support and translating messages to 
English, and our company is sponsoring people to write related 
OSS packages, and users seem to like it, too. 

At the very least, this OurNet thing got my mom started advocating
on strong crypto and online privacy, so I think it's kind of cool. 

=head1 CAVEATS

The HOWTO documentation and BBSCOM API is still lacking; we'll be
very grateful if anybody from the telnet BBS circle could contribute
to it.

=cut

sub import {
    my $self = shift;
    my $package = (caller())[0];

    my @failed;

    foreach my $module (@_) {
        eval("package $package; use OurNet::$module;");

        if ($@) {
            warn $@;
            push(@failed, $module);
        }
    }

    die "could not import qw(" . join(' ', @failed) . ")" if @failed;
}

sub new {
    my $package = join('::', splice(@_, 0, 2));

    eval "use $package";
    die $@ if $@;

    return $package->new(@_);
}

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>,
Chia-Liang Kao E<lt>clkao@clkao.org>.

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>,
		  Chia-Liang Kao E<lt>clkao@clkao.org>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
