package Selenium::Driver::SeleniumHQ::Jar;
$Selenium::Driver::SeleniumHQ::Jar::VERSION = '1.03';
use strict;
use warnings;

use v5.28;

no warnings 'experimental';
use feature qw/signatures/;

use Carp qw{confess};
use File::Basename qw{basename};
use File::Path qw{make_path};
use File::Spec();
use XML::LibXML();
use HTTP::Tiny();

#ABSTRACT: Download the latest version of seleniumHQ's selenium.jar, and tell Selenium::Client how to spawn it


our $index = 'http://selenium-release.storage.googleapis.com';

sub build_spawn_opts($class,$object) {
    $object->{driver_class}       = $class;
    $object->{driver_interpreter} //= 'java';
    $object->{driver_version}     //= '';
    $object->{log_file}           //= File::Spec->catfile($object->{client_dir},"perl-client","selenium-$object->{port}.log");
    ($object->{driver_file}, $object->{driver_major_version}) = find_and_fetch( File::Spec->catdir($object->{client_dir},"jars"), $object->{driver_version},$object->{ua});
    $object->{driver_config} //= _build_config($object);

    #XXX port in config is currently IGNORED
    my @java_opts;
    my @config = ((qw{standalone --config}), $object->{driver_config}, '--port', $object->{port});

    # Handle older seleniums that are WC3 compliant
    if ( $object->{driver_major_version} < 4 ) {
        $object->{prefix} = '/wd/hub';
        @java_opts = qw{-Dwebedriver.gecko.driver=geckodriver -Dwebdriver.chrome.driver=chromedriver};
        @config = ();
    }

    # Build command string
    # XXX relies on gecko/chromedriver in $PATH
    $object->{command} //= [
        $object->{driver_interpreter},
        @java_opts,
        qw{-jar},
        $object->{driver_file},
        @config,
    ];
    return $object;
}

sub _build_config($self) {
    my $dir = File::Spec->catdir($self->{client_dir},"perl-client");
    make_path( $dir ) unless -d $dir;


    my $file = File::Spec->catfile($dir,"config-$self->{port}.toml");
    return $file if -f $file;

    # TODO add some self-signed SSL to this
    my $config = <<~EOF;
[node]
detect-drivers = true
[server]
allow-cors = true
hostname = "localhost"
max-threads = 36
port = --PORT--
[logging]
enable = true
log-encoding = UTF-8
log-file = --REPLACE--
plain-logs = true
structured-logs = false
tracing = true
EOF

    #XXX double escape backslash because windows; like YAML, TOML is a poor choice always
    #XXX so, you'll die if there are backslashes in your username or homedir choice (lunatic)
    my $log_corrected = $self->{log_file};
    $log_corrected =~ s/\\/\\\\/g;

    $config =~ s/--REPLACE--/\"$log_corrected\"/gm;
    $config =~ s/--PORT--/$self->{port}/gm;

    File::Slurper::write_text($file, $config);
    return $file;
}


sub find_and_fetch($dir, $version='', $ua='') {
    $ua ||= HTTP::Tiny->new();
    my $res = $ua->get($index);
    confess "$res->{reason} :\n$res->{content}\n" unless $res->{success};
    my $parsed = XML::LibXML->load_xml(string => $res->{content});

    #XXX - XPATH NO WORKY, HURR DURR
    my @files;
    foreach my $element ($parsed->findnodes('//*')) {
        my $contents = $element->getChildrenByTagName("Contents");
        my @candidates = sort { $b cmp $a } grep { m/selenium-server/ && m/\.jar$/ } map {
            $_->getChildrenByTagName('Key')->to_literal().'';
        } @$contents;
        push(@files,@candidates);
    }

    @files = grep { m/\Q$version\E/ } @files if $version;
    my $jar = shift @files;
    my $url = "$index/$jar";

    make_path( $dir ) unless -d $dir;
    my $fname = File::Spec->catfile($dir, basename($jar));
    my ($v) = $fname =~ m/-(\d)\.\d\.\d.*\.jar$/;
    return ($fname,$v) if -f $fname;

    $res = $ua->mirror($url, $fname);

    confess "$res->{reason} :\n$res->{content}\n" unless $res->{success};
    return ($fname,$v);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Driver::SeleniumHQ::Jar - Download the latest version of seleniumHQ's selenium.jar, and tell Selenium::Client how to spawn it

=head1 VERSION

version 1.03

=head1 Mode of Operation

Downloads the latest Selenium JAR (or the provided driver_version).
Expects java to already be installed.

Spawns a selnium server on the provided port (which the caller will assign randomly)
Pipes log output to ~/.selenium/perl-client/$port.log
Uses a config file ~/.selenium/perl-client/$port.toml if the selenium version supports this

=head1 SUBROUTINES

=head2 build_spawn_opts($class,$object)

Builds a command string which can run the driver binary.
All driver classes must build this.

=head2 find_and_fetch($dir STRING, $version STRING, $user_agent HTTP::Tiny)

Does an index lookup of the various selenium JARs available and returns either the latest one
or the version provided.  Stores the JAR in the provided directory.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
