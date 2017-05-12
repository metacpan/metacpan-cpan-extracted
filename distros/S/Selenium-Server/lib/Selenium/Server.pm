package Selenium::Server;

use 5.008001;
use strict;
use warnings;
use Carp qw(croak);
use LWP::UserAgent;
use Test::TCP;
use File::Slurp qw(write_file);
use File::Temp;
use File::Spec;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

my $ua = LWP::UserAgent->new;

our $LATEST_VERSION;
sub latest_version {
    my $class = shift;

    unless ($LATEST_VERSION) {
        my $body = $ua->get('http://code.google.com/p/selenium/downloads/list')->content;
        my ($version) = $body =~ /selenium-server-standalone-(\d+.\d+.\d+).jar/i;
        $LATEST_VERSION = $version;
    }

    $LATEST_VERSION;
}

sub download {
    my ($class, $version, $path) = @_;

    my $name = "selenium-server-standalone-${version}.jar";
    my $url  = "http://selenium.googlecode.com/files/${name}";

    my $res = $ua->get($url);
    write_file($path, { binmode => ':raw' }, $res->content);
}

sub new {
    my ($class, %args) = @_;

    my $jar = exists $args{jar} ? $args{jar} : do {
        my $version = exists $args{version} ? $args{version} : $class->latest_version;

        my $dir  = File::Spec->tmpdir;
        my $name = "selenium-server-standalone-${version}.jar";
        my $path = File::Spec->catfile($dir, $name);

        $class->download($version, $path) unless -e $path;
        $path;
    };

    my $self = bless { jar => $jar }, $class;

    if ($args{auto_start}) {
        $self->start;
    }

    return $self;
}

sub jar {
    my $self = shift;
    return $self->{jar} || '';
}

sub host {
    my $self = shift;
    return $self->{server} ? '127.0.0.1' : '';
}

sub port {
    my $self = shift;
    return $self->{server} ? $self->{server}->port : '';
}

sub start {
    my ($self, $args) = @_;

    my $server = Test::TCP->new(
        code => sub {
            my $port = shift;

            my $fh = File::Temp->new(UNLINK => 1);
            open STDOUT, '>&', $fh or croak "dup(2) failed:$!";
            open STDERR, '>&', $fh or croak "dup(2) failed:$!";

            my $cmd = sprintf 'java -jar "%s" %s -port %s', $self->jar, ($args || ''), $port;
            system $cmd;
        },
    );
    $server->start;

    $self->{server} = $server;
}

sub stop {
    my $self = shift;

    if ($self->{server}) {
        my ($host, $port) = ($self->host, $self->port);
        my $url = "http://${host}:${port}/selenium-server/driver/?cmd=shutDownSeleniumServer";
        $ua->get($url);

        delete $self->{server};
    }
}

sub DESTROY {
    my $self = shift;
    $self->stop;
}

1;

=head1 NAME

Selenium::Server - A wrapper of selenium-server-standalone.jar

=head1 SYNOPSIS

  use Selenium::Server;

  # (default) download and use latest version jar
  my $server = Selenium::Server->new;
  # specify jar
  my $server = Selenium::Server->new(jar => '/path/to/selenium-server.jar');
  # specify version
  my $server = Selenium::Server->new(version => '2.11.0');

  $server->start;
  # with arguments
  $server->start('-timeout 60 -trustAllSSLCertificates');

  my $host = $server->host; # '127.0.0.1'
  my $port = $server->port;

  $server->stop;

=head1 DESCRIPTION

Selenium::Server is a wrapper of Selenium RemoteWebDriver Server;
selenium-server-standalone-{version}.jar file.

=head1 METHODS

=over 4

=item * new()

Creates a selenium-server wrapper instance.

=item * start($args)

Starts selenium-server, with $args if specified.

=item * stop()

Stops selenium-server.

=item * host()

Returns selenium-server host. (127.0.0.1)

=item * port()

Returns selenium-server port.

=item * jar()

Returns selenium-server JAR file path.

=item * latest_version()

Returns selenium-server latest version string.

=item * download($version, $path)

Downloads selenium-server jar file specified by $version to $path.

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Alien::SeleniumRC>

L<http://selenium.googlecode.com/svn/trunk/rb/lib/selenium/server.rb>

=cut
