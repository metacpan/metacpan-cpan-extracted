#!/usr/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
    AUTHOR           => 'Roberto Frenna <robertof@cpan.org>',
    NAME             => 'Net::Telnet::Netgear',
    VERSION_FROM     => 'lib/Net/Telnet/Netgear.pm',
    ABSTRACT         => 'Generate and send Netgear Telnet-enable packets through Net::Telnet',
    LICENSE          => 'artistic_2',
    PREREQ_PM        => {
        map { $_ => 0 } qw(Carp Crypt::Blowfish Crypt::ECB Digest::MD5 IO::Socket::INET),
                        qw(MIME::Base64 Net::Telnet Scalar::Util)
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
       (META_MERGE => {
            resources => {
                license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
                bugtracker => 'https://github.com/Robertof/perl-net-telnet-netgear/issues',
                repository => 'https://github.com/Robertof/perl-net-telnet-netgear'
            } 
        }) : ()
    )
);

# Create the target "README.md" used to generate the markdown version of the POD documentation.
# It uses the script gen_doc.pl, which requires Pod::Markdown.
# Thanks to the author of Mojolicious::Plugin::DigestAuth, who used a similar section in its
# makefile to do the same thing.
sub MY::postamble
{
    my $self = shift;
    <<END_MAKE;
README.md: $self->{VERSION_FROM}
\t\$(PERLRUN) gen_doc $self->{VERSION_FROM}
END_MAKE
}
