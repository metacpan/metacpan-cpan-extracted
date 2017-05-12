package SAL;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SAL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '3.03';


# Preloaded methods go here.

1;
__END__

=head1 Name

SAL - A Sub Application Layer for Perl

=head1 Synopsis

  use SAL;

=head1 Description

This is a stub.  Documentation needs to be done for all SAL::* modules unfortunately.

=head2 What it is, and what it is not

SAL is library for building multi-platform tools (shell, desktop, web).  It's primary purpose is to allow for rapid 
development of business reporting tools.  As with Perl, it's flexible enough to be used in a wide variety of 
environments, and for all kinds of needs.

SAL-proper IS NOT an application framework, although some tinkering has gone on in that neck of the woods.  (SAL::Kernel and SAL::VFS are still on the drawing 
board, but GUI widgets and SDL integration will probably be coming first.)

=head1 Required Modules

Installing SAL through CPAN requires the following:

SAL requires at least DBD::SQLite.  DBD::mysql and DBD::odbc are also supported database drivers

SAL also requires GD::Graph and it's prerequisites.  GD::Graph3d is optional, though it might replace GD::Graph as a prerequisite in the future.

=head1 Samples

In the installation tarball, you'll find a samples directory with the following quick-and-dirty examples.  They are 
(lol) not anywhere near real programs, but will hopefully help get you started.

  lsql           - a very simple shell for working with SQLite databases
  salsquid       - a very simple authenticator for Squid.  Requires MySQL database (or modification)
  salreport.cgi  - a very simple data-driven report example.
  salgraph.cgi   - a very simple graphing example.
  salsurvey.cgi  - a simple but effective web survey script.  Requires MySQL database (or modification)

=head1 Author

Scott Elcomb <psema4@gmail.com>

=head1 See Also

SAL::DBI, SAL::WebDDR, SAL::Graph, SAL::WebApplication

=cut
