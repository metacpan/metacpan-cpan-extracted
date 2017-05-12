#!/Users/jj/perl/perl-5.10.0/bin/perl

BEGIN {
    $ENV{CATALYST_ENGINE} ||= 'HTTP';
    $ENV{CATALYST_SCRIPT_GEN} = 32;
    require Catalyst::Engine::HTTP;
}

use strict;
use warnings;
use 5.010;
use Getopt::Long;
use Pod::Usage;
#use File::ShareDir qw/dist_dir/;
use File::Spec::Functions qw/tmpdir/;
use File::Temp qw/tempfile/;
use Data::Dumper;


#--Locate distribution directory for static files / templates--------------

#$ENV{PERLDOC_SERVER_HOME} = dist_dir('Perldoc-Server')
#  or die 'Cannot locate distribution directory for Perldoc-Server';
#say $ENV{PERLDOC_SERVER_HOME};

#--Process command-line options--------------------------------------------

my %options;
GetOptions(\%options,
  'perl=s',
  'port=i',
  'public',
  'debug',
  'help|h|?' => sub{pod2usage(1)},
);

unless ($options{perl}) {
  say "Option '--perl' is required";
  pod2usage(1);
}
  
#--Build configuration file------------------------------------------------

#my ($config_fh,$config_filename) = tempfile('Perldoc-Server-XXXXX',SUFFIX=>'.conf',DIR=>tmpdir())
#  or die 'Cannot create temporary configuration file';

#print $config_fh <<EOT;
#<Component View::TT>
#  INCLUDE_PATH $ENV{PERLDOC_SERVER_HOME}/templates
#</Component>
#<Component View::Pod2HTML>
#  INCLUDE_PATH $ENV{PERLDOC_SERVER_HOME}/templates
#</Component>
#
#root $ENV{PERLDOC_SERVER_HOME}
#EOT

if ($options{perl}) {
  perl_config($options{perl});   
}

#close $config_fh;
#$ENV{PERLDOC_SERVER_CONFIG} = $config_filename;


#--Start the server--------------------------------------------------------
  
my $debug             = $options{debug} ? 1 : 0;
my $fork              = 0;
my $help              = 0;
my $host              = $options{public} ? undef : 'localhost';
my $keepalive         = 0;
my $restart           = $ENV{PERLDOC_SERVER_RELOAD} || $ENV{CATALYST_RELOAD} || 0;
my $restart_delay     = 1;
my $restart_regex     = '(?:/|^)(?!\.#).+(?:\.yml$|\.yaml$|\.conf|\.pm)$';
my $restart_directory = undef;
my $follow_symlinks   = 0;

my @argv = @ARGV;





if ( $restart && $ENV{CATALYST_ENGINE} eq 'HTTP' ) {
    $ENV{CATALYST_ENGINE} = 'HTTP::Restarter';
}
if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
}

$ENV{PERLDOC_SERVER_HOME}   = "$ENV{PAR_TEMP}/inc/lib/Perldoc/Server";
$ENV{PERLDOC_SERVER_CONFIG} = "$ENV{PAR_TEMP}/inc/lib/Perldoc/Server/perldoc_server.conf";
unshift @INC,"$ENV{PAR_TEMP}/inc/lib";

# This is require instead of use so that the above environment
# variables can be set at runtime.
require Perldoc::Server;

my $port = $options{port} || 7375;

Perldoc::Server->run( $port, $host, {
    debug             => 0,
    argv              => \@ARGV,
    'fork'            => $fork,
    keepalive         => $keepalive,
    restart           => $restart,
    restart_delay     => $restart_delay,
    restart_regex     => qr/$restart_regex/,
    restart_directory => $restart_directory,
    follow_symlinks   => $follow_symlinks,
} );


#--------------------------------------------------------------------------

sub perl_config {
  my $perl         = shift;
  my $version_cmd  = 'printf("%vd",$^V)';
  my $perl_version = `$perl -e '$version_cmd'`;
  my $inc_cmd      = 'print "$_\n" foreach @INC';
  my $perl_inc     = `$perl -e '$inc_cmd'`;
  
  $ENV{PERLDOC_SERVER_PERL}         = $perl;
  $ENV{PERLDOC_SERVER_PERL_VERSION} = $perl_version;
  $ENV{PERLDOC_SERVER_SEARCH_PATH}  = $perl_inc;
  
  #$perl_inc =~ s/^/search_path /mg;
  
  
  #warn "Using perl INC $perl_inc";
#  return <<EOT;
#perl $perl
#perl_version $perl_version
#$perl_inc
#EOT
}


1;

=head1 NAME

perldoc-server - Local Perl documentation server

=head1 SYNOPSIS

 perldoc-server [options]

 Options:
 --perl /path/to/perl   Show documentation for this Perl installation
 --port 1234            Set server port number (defaults to 7375)
 --public               Run as a public server (defaults to private)
 --help                 Display help
   
=head1 DESCRIPTION

Perldoc::Server is a Catalyst application to serve local Perl documentation
in the same style as L<http://perldoc.perl.org>.

In addition to keeping the same look and feel of L<http://perldoc.perl.org>,
Perldoc::Server offer the following features:

=over

=item * View source of any installed module

=item * Improved syntax highlighting

=over

=item * Line numbering

=item * C<use> and C<require> statements linked to modules

=back

=item * Sidebar shows links to your 10 most viewed documentation pages

=back

=head1 CONFIGURATION

=over

=item --perl

By default, Perldoc::Server will show documentation for the Perl installation
used to run the server.

However, using the C<--perl> command-line option, it is also possible to
serve documentation for a different Perl installation, e.g.

 perldoc-server --perl /usr/bin/perl

Note that while Perldoc::Server requires Perl 5.10.0 or newer, the C<--perl>
option can be used to display documentation for older Perls.

=item --port

Sets the server's port number - defaults to 7375 ("PERL" on a phone keypad).

=item --public

Runs as a public server. If this option is not set, the server will default
to private mode, i.e. only accepting connections from localhost.

=back

=head1 AUTHORS

Jon Allen (JJ) <jj@jonallen.info>

Perldoc::Server was developed at the 2009 QA Hackathon L<http://qa-hackathon.org>
supported by Birmingham Perl Mongers L<http://birmingham.pm.org>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2009 Penny's Arcade Limited - L<http://www.pennysarcade.co.uk>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
