use strict;
use warnings;
package Task::OTRS::Win32;

our $VERSION = '1.12';
# ABSTRACT: Almost all of the modules required for installing OTRS Help Desk on win32.


1;

__END__

=pod

=head1 NAME

Task::OTRS::Win32 - Almost all of the modules required for installing OTRS Help Desk on win32.

=head1 VERSION

version 1.12

=head1 SYNOPSIS

This is just a Task module to install dependencies. There's no code to use
or run. 

=head1 DESCRIPTION

Installing this module will also install almost all the modules you'll need to run OTRS
on Win32. This module pulls in all the modules specified in L<Task::OTRS> and
then adds all modules needed specifically for use on Windows. This includes
modules to install the Scheduler service, as well as modules needed for CRONw.

Note that OTRS itself also ships some CPAN modules in Kernel/cpan-libs, these modules will
not be required by Task::OTRS. See for the bundled list of modules in OTRS 
L<Module::OTRS::CoreList>.

The only module that you need to run OTRS but that will not be installed is the database driver, because OTRS supports 
multiple database backends. Please note that if you install this module on 
Strawberry Perl this is generally not needed, because it ships with drivers for
MySQL, PostgreSQL and ODBC.

So after you're done installing Task::OTRS::Win32 you might also want to
install the database driver for your DMBS of choice:

=over 4

=item * for MySQL (the most popular database for OTRS): L<DBD::mysql>

=item * for PostgreSQL: L<DBD::Pg>

=item * for Oracle: L<DBD::Oracle>

=item * for Microsoft SQL Server: L<DBD::ODBC> (only on Windows platforms)

=item * for IBM DB2: L<DBD::DB2>

=back

Note that installing these drivers can require installation of database libraries on your 
system as well. 

All modules that will be installed are listed below. Note that if such a module is already on
your system, we will not install it again.

=over 4

=item * Task::OTRS

=item * Date::Manip

=item * Log::Dispatch

=item * Log::Dispatch::FileRotate

=item * Log::Log4perl

=item * Win32

=item * Win32::Console::ANSI

=item * Win32::Daemon

=item * Win32::Service

=back

=head1 CAVEATS

Apart from not installing the database dependencies, installing Task::OTRS::Win32 will get you 
possibly more modules than you'll be needing. For instance, if you use postfix for mail delivery
and sending, you might not be needing Net::POP3 and Net::SMTP. Also, in case you don't
care about generating PDF files with OTRS, you don't need PDF::API2. That said, installing
Task::OTRS::Win32 can help in setting up OTRS more quickly.

This module will install all modules for the current version of OTRS, 3.2.x. It could be possible 
that for other versions the requirements change. It would be feasible that by then I'll release specific
Task:: modules for specific OTRS versions.

=head1 AUTHOR

Michiel Beijen <michiel.beijen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by OTRS BV.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
