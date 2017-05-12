package OpenInteract::SampleStash;

# $Id: sample-Stash.pm,v 1.3 2002/01/02 02:43:54 lachoy Exp $

use strict;

@OpenInteract::SampleStash::ISA     = ();
$OpenInteract::SampleStash::VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

# This is where we do the stashing

my %ITEMS = ();

# Specify the items that will survive the purge by clean_stash(),
# which is typically called at the end of every request.

my %KEEP  = map { $_ => 1 }
            qw( cache ipc-cache config template_object error_handlers );

sub get_stash { return $ITEMS{ lc $_[1] } }

sub set_stash { return $ITEMS{ lc $_[1] } = $_[2] }

sub clean_stash {
    foreach my $item ( keys %ITEMS ) {
        delete $ITEMS{ $item } unless ( $KEEP{ $item } );
    }
}

1;

=pod

=head1 NAME

OpenInteract::SampleStash - Default stash class and an example of what one looks like

=head1 SYNOPSIS

 # Define your stash class in the base.conf file
 ...
 StashClass    MyApp::Stash

=head1 DESCRIPTION

Note: This class template is used when generating a new website via
'oi_manage' and is not meant to be used directly.

The existence of the 'stash class' is necessitated by the fact that we
can have more than one application running at the same time. Certain
aspects of that application -- such as the cache, configuration,
database handle, template object and more -- must be kept absolutely
separate.

To do this, we keep them in separate classes. When the
L<OpenInteract::Request> object is initialized, it sets the
'stash_class' key of the request object to the package name of the
stash class, and all requests for config objects, database handles and
the like are handed off to it.

The stash itself is incredibly simple. We could even keep the methods
in a superclass and inherit them; however, we are currently keeping
the stashed information in a lexical hash, and to access it from a
separate class we would need to write an accessor method, and by the
time that happens what is the point?

Note that a stash class should be automatically created for you when
you run the scripts packaged with OpenInteract to create a new
application.

=head1 METHODS

B<get_stash( $key )>

Retrieve a value from the stash matching up to $key. Note that this is
case-insensitive, so the following are equivalent:

 $class->get_stash( 'DB' );
 $class->get_stash( 'db' );
 $class->get_stash( 'Db' );

B<set_stash( $key, $item )>

Save a value into the stash. Replaces any value previously left there.

B<clean_stash>

Cleans up any information in the stash that is not persistent from
request to request. To ensure that your information sticks around, put
the key into the lexical %KEEP hash with a true value.

=back

=head1 TO DO

=head1 BUGS

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
