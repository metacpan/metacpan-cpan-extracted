use strict;
use warnings;
use ExtUtils::MakeMaker;

sub has_module {
    my $module = @_;
    my $moduleFile = $module . ".pm";
    $moduleFile =~ s/::/\//g;
    eval { require $moduleFile; };
    return !$@;
}

sub recommend {
    my $module = @_;
    if (!has_module) {
        warn "It is recommended you install $module.\n";
    }
}

my %requires = (
    'Test::More'            => 0,
    'LWP'                   => 6,
    'LWP::Protocol::https'  => 6,
    'Net::SSLeay'           => 1.33,
    'Mozilla::CA'           => 0,
    'MIME::Base64'          => 0,
    'Digest::HMAC_SHA1'     => 0,
    'URI::Escape'           => 0
);

if (has_module('XML::Parser::Lite') and !has_module('XML::Parser')) {
    warn "You have module XML::Parser::Lite but not XML::Parser.\n" .
         "It is recommended that you install XML::Parser.";
}
else {
    $requires{'XML::Parser'} = 0;
}

foreach my $module (qw{ IO::String }) {
    recommend($module);
}

WriteMakefile(
    NAME                => 'Net::Amazon::MechanicalTurk',
    VERSION_FROM        => 'lib/Net/Amazon/MechanicalTurk.pm',
    ABSTRACT_FROM       => 'lib/Net/Amazon/MechanicalTurk.pm',
    PL_FILES            => {},
    PREREQ_PM           => \%requires, 
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Amazon-MechanicalTurk-*' },
);

