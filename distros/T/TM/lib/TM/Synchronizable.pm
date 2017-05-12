package TM::Synchronizable;

use strict;
use warnings;

use Data::Dumper;

use Class::Trait 'base';
use Class::Trait 'TM::ResourceAble';

#use TM::ResourceAble;
#use base qw(TM::ResourceAble);
##our @REQUIRES = qw(source_in source_out);

=pod

=head1 NAME

TM::Synchronizable - Topic Maps, trait for synchronizable resources

=head1 SYNOPSIS

   # you write an input/output driver
   # see for example TM::Synchronizable::MLDBM
   package My::WhatEver;

     # provides source_in and/or source_out methods
     sub source_in  { .... }

     sub source_out { .... }

     1;

   # you construct your map class
   package MySyncableMap;

     use TM;
     use base qw(TM);
     use Class::Trait qw(TM::ResourceAble TM::Synchronizable My::WhatEver);
 
     1;

   # you then use that
   my $tm = MySyncableMap (url => 'file:/where/ever');
   $tm->sync_in;
   # work with the map, etc...
   $tm->sync_out;

=head1 DESCRIPTION

This trait implements the abstract synchronization between in-memory topic maps and the resources
which are attached to them, i.e. files, web pages, etc. whatever can be addressed via a URI.
Consequently, this trait inherits from L<TM::ResourceAble>, although L<Class::Trait> does not do
this for you (sadly).

The trait provides the methods C<sync_in> and C<sync_out> to implement the synchronization. In this
process it uses the timestamp of the map (C<last_mod>) and that of the resource C<mtime>.

Unfortunately, the granularity of the two are different (at least on current UNIX systems): for the
I<last modification> time values from L<Time::HiRes> is used. UNIX resources only use an integer.

B<Note>: This needs a bit of consideration from the user's side.

=head1 INTERFACE

=head2 Methods

=over

=item B<sync_in>

I<$tm>->sync_in

This method provides only the main logic, whether a synchronisation from the resource into the
in-memory map should occur. If the last modification date of the resource (C<mtime>) is more recent
than that of the map (C<last_mod>), then synchronisation from the resource to the in-memory map will
be triggered. For this, a method C<source_in> has to exist for the map object; that will be invoked.

[Since TM 1.53]: Any additional parameters are passed through to the underlying C<source_in> method.

=cut

sub sync_in {
    my $self = shift;
    my $url  = $self->url;

    $self->source_in (@_) if $self->last_mod           # modification in map
                          <                            # earlier than
                          $self->mtime + 1;            # modification of resource
}

=pod

=item B<sync_out>

I<$tm>->sync_out

This method provides the logic, whether synchronisation from the in-memory map towards the attached
resource should occur or not. If the last modification date of the map (C<last_mod>) is more recent
than that of the resource (C<mtime>), then a method C<source_out> for the object is triggered.

[Since TM 1.53]: Any additional parameters are passed through to the underlying C<source_out> method.

=cut

sub sync_out {
    my $self = shift;
    my $url  = $self->url;

    $self->source_out (@_) if $self->last_mod         # map modification
                           >                          # later than
                           ( $self->mtime || 0 );     # resource modification
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::ResourceAble>

=head1 AUTHOR INFORMATION

Copyright 20(0[6]|10), Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.3;

1;

__END__
