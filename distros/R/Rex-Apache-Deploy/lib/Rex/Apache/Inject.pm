#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Inject - Configuration Injection module for Rex::Apache::Deploy

=head1 DESCRIPTION

This is a (R)?ex module to inject configuration parameters into packages (*.tar.gz, *.tar.bz2, *.zip or *.war).

You can find examples and howtos on L<http://rexify.org/>

=head1 GETTING HELP

=over 4

=item * Web Site: L<http://rexify.org/>

=item * IRC: irc.freenode.net #rex

=back

=head1 DEPENDENCIES

=over 4

=item *

L<Rex>

=back

=head1 SYNOPSIS

 use Rex::Apache::Inject Properties;

 template_file "inject.conf";
 template_search_for "*.properties";

 desc "Inject LIVE Configuration";
 task "inject", sub {
   inject "mypkg-1.0.1.tar.gz";
 };

 desc "Inject LIVE Configuration";
 task "inject", sub {
   inject "mypkg-1.0.1.tar.gz",
        pre_pack_hook => sub {
            say "Pre Pack Hook";
        },
        post_pack_hook => {
            say "Post Pack Hook";
        };
 };


=head1 INJECT METHODS

=over 4

=item Properties

This method is for Java-Like Property files.

 use Rex::Apache::Inject Properties;

 template_file "inject.conf";
 template_search_for "*.properties";

 task "inject", sub {
    inject "myapp.war";
 };

This will search all files named I<*.properties> inside of myapp.war and replace the parameters with these defined in I<template_file>.

Format of the I<template_file> is the same as the property files.

 my.property.one = Value1
 my.property.two = Value no two

=item Template

This is a special method. It will search for template files within the archive and will generate new ones with the parameters defined in I<template_file>.

 use Rex::Apache::Inject Template;

 template_file "inject.conf";
 template_search_for "*.template.*";

 generate_real_name sub {
   my ($template_file_name) = @_;
   $template_file_name =~ s/\.template//;
   return $template_file_name;
 };

 task "inject", sub {
    inject "myapp.tar.gz";
 };

This will search for files named I<*.template.*> inside of myapp.tar.gz. And will generate new files on the basis of I<generate_real_name>.

Example:

 # Template Configuration file (inside myapp.tar.gz): config.template.php
 <?php
   $db['host'] = "@db.host@";
   $db['port'] = @db.port@;
   $db['user'] = "@db.user@";
   $db['pass'] = "@db.pass@";
 ?>

 # Template file (specified by ,,template_file'')
 db.host = "db01"
 db.port = 3306
 db.user = "myuser"
 db.pass = "mypass"


The I<inject> action will generate a file called I<config.php> with the following content:

 <?php
   $db['host'] = "db01";
   $db['port'] = 3306;
   $db['user'] = "myuser";
   $db['pass'] = "mypass";
 ?>

=item YAML

This method will parse YAML files inside the archive. For this method you need to have the I<YAML> Module installed.

 template_file "live_config.yml";
 template_search_for "application.yml";

 task "inject", sub {
    inject "myapp.tar.gz",
      pre_pack_hook => sub {
         run "BUNDLE_PATH=vendor/bundle bundle install";
      };
 };

This will search the file I<application.yml> inside of myapp.tar.gz and replace the configuration values inside of it with these defined in I<live_config.yml>. Also it do a pre pack hook that will run I<bundle install>.

=back

=cut

package Rex::Apache::Inject;

our $VERSION = "0.12.0";

use strict;
use warnings;

use Data::Dumper;

sub import {

  my ($call_class) = caller;

  return unless $_[1];

  die("Invalid input format") unless ( $_[1] =~ m/^[a-z0-9_]+$/i );

  eval "use $_[0]::$_[1] '$call_class';";

}

1;
