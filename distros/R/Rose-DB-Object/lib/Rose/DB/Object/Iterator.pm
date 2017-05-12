package Rose::DB::Object::Iterator;

use strict;

use Carp();

use Rose::Object;
our @ISA = qw(Rose::Object);

our $VERSION = '0.759';

use Rose::Object::MakeMethods::Generic
(
  scalar => 
  [
    'error',
    '_count',
    '_next_code',
    '_finish_code',
    '_destroy_code',
  ],

  'boolean' => 'active',
);

sub next
{
  my($self) = shift;
  my $ret = $self->_next_code->($self, @_);
  $self->active(0)  unless($ret);
  return $ret;
}

sub finish
{
  my($self) = shift;
  $self->active(0);
  $self->_next_code(sub { 0 });
  return $self->_finish_code->($self, @_);
}

sub DESTROY
{
  my($self) = shift;

  if($self->active)
  {
    $self->finish;
  }
  elsif(my $code = $self->_destroy_code)
  {
    $code->($self);
  }
}

sub total { shift->{'_count'} }

1;

__END__

=head1 NAME

Rose::DB::Object::Iterator - Iterate over a series of Rose::DB::Objects.

=head1 SYNOPSIS

    $iterator = Rose::DB::Object::Manager->get_objects_iterator(...);

    while($object = $iterator->next)
    {
      # do stuff with $object...

      if(...) # bail out early
      {
        $iterator->finish;
        last;
      }
    }

    if($iterator->error)
    {
      print "There was an error: ", $iterator->error;
    }
    else
    {
      print "Total: ", $iterator->total;
    }

=head1 DESCRIPTION

L<Rose::DB::Object::Iterator> is an iterator object that traverses a database query, returning L<Rose::DB::Object>-derived objects for each row.  L<Rose::DB::Object::Iterator> objects are created by calls to the L<get_objects_iterator|Rose::DB::Object::Manager/get_objects_iterator> method of L<Rose::DB::Object::Manager> or one of its subclasses.

=head1 OBJECT METHODS

=over 4

=item B<error>

Returns the text message associated with the last error, or false if there was no error.

=item B<finish>

Prematurely stop the iteration (i.e., before iterating over all of the available objects).

=item B<next>

Return the next L<Rose::DB::Object>-derived object.  Returns false (but defined) if there are no more objects to iterate over, or undef if there was an error.

=item B<total>

Returns the total number of objects iterated over so far.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
