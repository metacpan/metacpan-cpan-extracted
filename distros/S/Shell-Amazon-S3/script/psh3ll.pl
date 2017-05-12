#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION
 
The pSh3ll is a perl based command shell for managing your Amazon S3 objects.
It is built upon the Amazon S3 REST perl library.
 
=cut

use Shell::Amazon::S3;

my $shell = Shell::Amazon::S3->new;
$shell->load_plugins($_) for qw(ReadLineHistory Completion);
$shell->run;

__END__


=head1 NAME
 
psh3ll.pl - Amazon S3 command shell for Perl
 
=head1 SYNOPSIS

You need to setup aws key and secret key after run pSh3ll.pl.
These configuration is stored in ~/.psh3ll.

After configuring AWS settings, you can use psh3ll.
you can use commands with psh3ll.The commands are listed as below:
 
  bucket [bucketname]
  count [prefix]
  createbucket
  delete <id>
  deleteall [prefix]
  deletebucket
  exit
  get
  getacl ['bucket'|'item'] <id>
  getfile <id> <file>
  gettorrent <id>
  head ['bucket'|'item'] <id>
  host [hostname]
  list [prefix] [max]
  listatom [prefix] [max]
  listrss [prefix] [max]
  listbuckets
  pass [password]
  put <id> <data>
  putfile <id> <file>
  putfilewacl <id> <file> ['private'|'public-read'|'public-read-write'|'authenticated-read']
  quit
  setacl ['bucket'|'item'] <id> ['private'|'public-read'|'public-read-write'|'authenticated-read']
  user [username]
 
=head1 AUTHOR
 
Takatoshi Kitano E<lt>kitano.tk (at) gmail.comE<gt>
 
=head1 LICENSE
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=head1 SEE ALSO
 
L<http://rubyforge.org/projects/rsh3ll/>
 
=cut
