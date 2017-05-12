package OpenPlugin::Cache;

# $Id: Cache.pm,v 1.17 2003/04/03 01:51:23 andreychek Exp $

use strict;
use OpenPlugin::Plugin;

@OpenPlugin::Cache::ISA     = qw( OpenPlugin::Plugin );
$OpenPlugin::Cache::VERSION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'cache' }

sub fetch {}
sub save {}
sub delete {}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Cache - Base class for putting data in and getting information out of a cache

=head1 SYNOPSIS

 use OpenPlugin();
 $OP = OpenPlugin->new();
 my $id = $OP->cache->save( $large_data_set );

 ...

 my $data = $OP->cache->fetch( $id );

=head1 DESCRIPTION

This plugin is designed to save data to a cache, and later retrieve that
information from that cache.  It is very similar to sessions, but data which is
cached is meant for all users.  Session data is only meant for the user
associated with that particular session.

Data you'd typically want to cache includes information returned which requires
a lot of time or processing to retrieve.  One example is large database
queries.

=head1 METHODS

B<fetch( $id )>

Retrieves whatever is in the cache tagged by C<$id>.

B<save( $data, { id => $id, expires => $date })>

Saves data into the cache.

Returns: the cache ID used on success, undef on failure.

Basic parameters -- drivers may define others:

=over 4

=item *

B<data>: Data to cache.  Although it needs to be a scalar, it can be any sort
of scalar format, including a string, hash reference, or array reference.

=item *

B<id> (optional): Identifier (key) for the cached data. If not specified, an id
will be randomly chosen for you.

=item *

B<expires> (optional): Expiration time, in the format:

 "now"  - expire immediately
 "+180s - in 180 seconds
 "+2m"  - in 2 minutes
 "+12h" - in 12 hours
 "+1d"  - in 1 day
 "+3M"  - in 3 months
 "+2y"  - in 2 years
 "-3m"  - 3 minutes ago(!)

If not specified, the item will have the same cache time as is listed as a
default in the config file.

=back

B<delete( $id )>

Delete an existing item from the cache.

Returns true if successful.

=head1 BUGS

None known.

=head1 TO DO

See the TO DO list in the L<OpenPlugin::Session> plugin.

=head1 SEE ALSO

L<Cache::Cache>

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
