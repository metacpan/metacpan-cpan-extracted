package Test::BDD::Infrastructure;

use strict;
use warnings;

use Test::BDD::Infrastructure::File;
use Test::BDD::Infrastructure::Process;
use Test::BDD::Infrastructure::HTTP;
use Test::BDD::Infrastructure::Compare;
use Test::BDD::Infrastructure::DNS;
use Test::BDD::Infrastructure::Filesystem;
use Test::BDD::Infrastructure::Swap;
use Test::BDD::Infrastructure::Socket;
use Test::BDD::Infrastructure::Exec;
use Test::BDD::Infrastructure::Logfile;
use Test::BDD::Infrastructure::SystemUser;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: a collection of step file definitions for Test Driven Infrastructure


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure - a collection of step file definitions for Test Driven Infrastructure

=head1 VERSION

version 1.005

=head1 Description

This is a collection of generic step definitions for infrastructure testing
with Test::BDD::Cucumber.

=head1 What is Test Driven Infrastructure?

TDI takes the concept of Test Driven Development used for software development
and applies it to infrastructure.

Instead of software it is used to test infrastructure.
Instead of function and classes it is used to test daemons and configuration.

=head1 Overview

=over

=item L<Test::BDD::Infrastructure::File>

Checks for testing existence, attributes, size, mode
and content of files and directories.

=item L<Test::BDD::Infrastructure::DNS>

Checks for constructing DNS queries and checking response
and records.

=item L<Test::BDD::Infrastructure::Process>

Checks for testing the process table.

=item L<Test::BDD::Infrastructure::HTTP>

Checks for testing a HTTP server.

=item L<Test::BDD::Infrastructure::Compare>

Checks for testing configuration variables.

=item L<Test::BDD::Infrastructure::Filesystem>

Checks for testing file system usage.

=item L<Test::BDD::Infrastructure::Swap>

Check for testing swap space usage.

=item L<Test::BDD::Infrastructure::Socket>

Checks for tcp/udp/unix-socket based checks.

=item L<Test::BDD::Infrastructure::Exec>

Checks for executing commands and checking their output.

=item L<Test::BDD::Infrastructure::Logfile>

Checks for watching log files.

=item L<Test::BDD::Infrastructure::SystemUser>

Checks for system user/groups.

=back

=head1 Example

First include the steps from a step_file:

  # features/step_files/00use_steps.pl
  use Test::BDD::Infrastructure;

Or just include individual steps:

  # features/step_files/00use_steps.pl
  use Test::BDD::Infrastructure::File;
  use Test::BDD::Infrastructure::HTTP;
  use Test::BDD::Infrastructure::Process;
  ...

Then define features of your infrastructure:

  # features/webserver.feature
  Feature: Example application is running on a webserver
  For the example application to work it is necessary that the webserver
  is configured and running.

  Scenario: The webserver process must be running
    Given a parent process like ^/usr/sbin/apache2.prefork is running
    Then the uid of the process must be root
    And the gid of the process must be root
    And the RSS size of the process must be smaller than 32 megabyte
    When there are at least 5 child processes like ^/usr/sbin/apache2.prefork
    Then the uid of the child processes must be www-data
    And the gid of the child processes must be www-data
    And the RSS size of the child processes must be smaller than 64 megabyte

  Scenario: The start page of the webserver must be accessible
    Given the http URL http://www.example.mydomain.de/
    When the http request is sent
    Then the http response must be successfull
    And the http response header Content-Type must be like text/html
    And the http response content must be like Welcome to Example

  Scenario: The webserver must log access
    Given the file /var/log/apache2/access.log exists
    Then the file mode must be 0640
    And the file must be owned by user root
    And the file must be owned by group adm
    And the file must contain at least 1 line
    And the file mtime must be newer than 5 minutes

=head1 See also

=over

=item Test::BDD::Cucumber

The perl cucumber implementation.

=item Test::BDD::Cucumber::Harness::Nagios

Report your test results to nagios for monitoring.

=item Test::BDD::Cucumber::Harness::Html

Generate HTML reports for your documentation, meetings etc.

=back

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
