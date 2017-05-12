package Task::Module::Install::BINGOS;
$Task::Module::Install::BINGOS::VERSION = '1.04';
#ABSTRACT: A Task to install all BINGOS' Module::Install extensions

use strict;
use warnings;

'BINGOS';

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::Module::Install::BINGOS - A Task to install all BINGOS' Module::Install extensions

=head1 VERSION

version 1.04

=head1 SYNOPSIS

  perl -MCPANPLUS -e 'install Task::Module::Install::BINGOS'

=head1 DESCRIPTION

Task::Module::Install::BINGOS is a L<Task> that installs all of my (BINGOS) L<Module::Install>
extensions.

Why? Because I am lazy.

The following modules will be installed:

  Module::Install

  Module::Install::AssertOS

  Module::Install::AutoLicense

  Module::Install::AutomatedTester

  Module::Install::CheckLib

  Module::Install::GithubMeta

  Module::Install::NoAutomatedTesting

  Module::Install::ReadmeFromPod

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
