package Neo4j::Client;
use Neo4j::ClientLocal;
use Cwd qw/realpath/;
use File::ShareDir qw/module_dir/;
use File::Spec;

use strict;
use warnings;

$Neo4j::Client::VERSION="0.17";

$Neo4j::Client::LIBS =
  join(' ', "-L".realpath(module_dir(__PACKAGE__))." -lClient",
       $Neo4j::Client::LOCAL_LIBS);

$Neo4j::Client::CCFLAGS =
  join(' ', "-I".realpath(module_dir(__PACKAGE__)),
       $Neo4j::Client::LOCAL_CCFLAGS);

$Neo4j::Client::DEV_CCFLAGS =
  join(' ',"-I".realpath(module_dir(__PACKAGE__))."/include",
       $Neo4j::Client::CCFLAGS);
       
sub Neo4j::Client::LIBS_ARY { split /\s+/,$Neo4j::Client::LIBS }
sub Neo4j::Client::CCFLAGS_ARY { split /\s+/,$Neo4j::Client::CCFLAGS }
sub Neo4j::Client::DEV_CCFLAGS_ARY { split /\s+/,$Neo4j::Client::DEV_CCFLAGS }

sub dir { realpath(module_dir(__PACKAGE__)) }

=head1 NAME

Neo4j::Client - Build and use the libneo4j-client library

=head1 SYNOPSIS

 use ExtUtils::MakeMaker;
 use Neo4j::Client;
 
 WriteMakefile(
   LIBS => join(' ',$YOURLIBS, $Neo4j::Client::LIBS),
   CCFLAGS => join(' ',$YOURCCFLAGS, $Neo4j::Client::CCFLAGS),
   ...
 );

=head1 DESCRIPTION

Chris Leishman's
L<libneo4j-client|https://github.com/cleishm/libneo4j-client> is a C
library for communication with a Neo4j (<v4.0) server via the Bolt
protocol. Installing this module will attempt to build the (static)
library on your machine (particularly for the use of
L<Neo4j::Bolt>). It will build with TLS support if OpenSSL
libraries/includes are found.

Use the (fully qualified) C<$Neo4j::Client::LIBS> and C<$Neo4j::Client::CCFLAGS>
to fold the library in to compilation and linking.

The script C<neoclient.pl> will provide these on the command line.

=head1 VARIABLES

=over

=item $Neo4j::Client::LIBS

=item $Neo4j::Client::CCFLAGS

=item $Neo4j::Client::DEV_CCFLAGS

CCFLAGS plus an '-I' flag pointing to installed E<lt>archE<gt>/auto/Neo4j/Client/include,
which contains config.h for the build and all libneo4j-client src/lib/*.h files.

=back

=head1 FUNCTIONS

=over

=item Neo4j::Client::LIBS_ARY()

LIBS tokenized as plain array.

=item Neo4j::Client::CCFLAGS_ARY()

CCFLAGS tokenized as plain array.

=item Neo4j::Client::DEV_CCFLAGS_ARY()

DEV_CCFLAGS tokenized as plain array.

=item Neo4j::Client::dir()

Absolute path to installed E<lt>archE<gt>/auto/Neo4j/Client.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>.

=head1 AUTHOR

 Mark A. Jensen < majensen -at- cpan -dot- org >
 CPAN: MAJENSEN

=head1 LICENSE

This packaging software is Copyright (c) 2020 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

The L<libneo4j-client|https://github.com/clieshm/libneo4j-client> software 
is Copyright (c) by Chris Leishman. 

It is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

1;
