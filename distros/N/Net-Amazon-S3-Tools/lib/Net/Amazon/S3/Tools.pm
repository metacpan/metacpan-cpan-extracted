package Net::Amazon::S3::Tools;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Amazon::S3::Tools ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.07';


# Preloaded methods go here.

1;
__END__

=head1 NAME

Net::Amazon::S3::Tools - command line tools for Amazon S3

=head1 SYNOPSIS

  s3acl [options] [[bucket|bucket/key] ...]
  s3ls [options]
  s3ls [options] [ bucket/item ... ]
  s3get [options] [ bucket/item ... ]
  s3put [options] [ bucket/item ... ]
  s3mkbucket [options] [ bucket ... ]
  s3rmbucket [options] [ bucket ... ]

=head1 OPTIONS

Each of the tools have their own specific command line options,
but the also all share some common command line options,
which are described here.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--verbose>

Output what is being done as it is done.

=item B<--access-key> and B<--secret-key>

Specify the "AWS Access Key Identifiers" for the AWS account.
B<--access-key> is the "Access Key ID", and B<--secret-key> is
the "Secret Access Key".  These are effectively the "username" and
"password" to the AWS account, and should be kept confidential.

The access keys MUST be specified, either via these command line
parameters, or via the B<AWS_ACCESS_KEY_ID> and
B<AWS_ACCESS_KEY_SECRET> environment variables.

Specifying them on the command line overrides the environment
variables.

=item B<--secure>

Uses SSL/TLS HTTPS to communicate with the AWS service, instead of
HTTP.

=head1 DESCRIPTION

These S3 command line tools allow you to manipulate and populate an S3
account.  Refer to the documentation (pod and man) for each of the
tools.

This L<Net::Amazon::S3::Tools> module is mostly just a stub, to hoist
the bundling and installation of the executable scripts that make up
the actual tools.

=head1 BUGS

Report bugs to Mark Atwood L<mark@fallenpegasus.com>.

Occasionally the S3 service will randomly fail for no externally
apparent reason.  When that happens, these tools should retry, with a
delay and a backoff.

Access to the S3 service can be authenticated with a X.509
certificate, instead of via the "AWS Access Key Identifiers".
These tools should support that.

It might be useful to be able to specify the "AWS Access Key Identifiers"
in the user's C<~/.netrc> file.
These tools should support that.

Errors and warnings are very "Perl-ish", and can be confusing.

=head1 SEE ALSO

These tools use the L<Net::Amazon::S3> Perl module.

The Amazon Simple Storage Service is documented at
L<http://aws.amazon.com/s3>.

These tools are hosted at
L<http://fallenpegasus.com/code/s3-tools>.

=head1 AUTHOR

Written by Mark Atwood L<mark@fallenpegasus.com>.

Many thanks to Wotan LLC L<http://wotanllc.com>, for supporting the
development of these S3 tools.

Many thanks to the Amazon AWS engineers for developing S3.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007,2008 by Mark Atwood

This module is not an official Amazon product or service.  Information
used to create this module was obtained only from publicly available
information, mainly from the published Amazon documentation.

    This module is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation, either version 2.1 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    and the GNU Lesser General Public License along with this program.
    If not, see <http://www.gnu.org/licenses/>.

=cut
