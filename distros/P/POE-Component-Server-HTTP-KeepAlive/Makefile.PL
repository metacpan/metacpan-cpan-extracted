#!/usr/bin/perl

use ExtUtils::MakeMaker;

my %MORE;

#####
my $v = eval {
        $SIG{__WARN__} = sub {};
        $SIG{__DIE__} = sub {};
        require POE::Component::Server::SimpleHTTP;
        return $POE::Component::Server::SimpleHTTP::VERSION;
    };
my $ONE;
$ONE++ if $v;
if( $v and $v < 1.30 ) {
    die "POE::Component::Server::HTTP::KeepAlive doesn't work with POE::Component::Server::SimpleHTTP before 1.30\n";
}

#####
$v = eval {
        $SIG{__WARN__} = 'IGNORE';
        $SIG{__DIE__} = 'IGNORE';
        require POE::Component::Server::HTTP;
        return $POE::Component::Server::HTTP::VERSION;
    };
$ONE++ if $v;
if( $v and $v < 0.10 ) {
    warn "POE::Component::Server::HTTP::KeepAlive doesn't work with POE::Component::Server::HTTP before 0.10.\n",
         "See http://rt.cpan.org/Ticket/Display.html?id=31810\n";
    $MORE{'POE::Component::Server::HTTP'} = '0.10';
}

#####
%MORE = (
        POE::Component::Server::SimpleHTTP => '1.30',
#        POE::Component::Server::HTTP       => 0.10
    ) unless $ONE;

package MY;

use strict;
use warnings;

sub init_PM
{
    my( $self, @args ) = @_;

    $self->SUPER::init_PM( @args );

    foreach my $file ( keys %{ $self->{PM} || {} } ) {
        next if $file =~ /^lib.+\.pm$/;
        delete $self->{PM}{$file};
    }
}

package main;

WriteMakefile(
    NAME           => 'POE::Component::Server::HTTP::KeepAlive',
    AUTHOR         => 'Philip Gwyn <gwyn -at- cpan.org>',
    VERSION_FROM   => 'lib/POE/Component/Server/HTTP/KeepAlive.pm', # finds $VERSION
    ABSTRACT_FROM  => 'lib/POE/Component/Server/HTTP/KeepAlive.pm',
    LICENSE        => 'perl',
    PREREQ_PM      => {
        POE => '1.311',
        'HTTP::Status' => 0,
        'HTTP::Response' => 0,
        'HTTP::Request' => 0,
        'LWP::UserAgent' => 6,
        %MORE
    },
   );
