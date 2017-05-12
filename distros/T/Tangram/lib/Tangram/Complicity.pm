
=head1 NAME

Tangram::Complicity - How to make Tangram-friendly classes

=head1 SYNOPSIS

  package YourNastyXSClass;

  sub px_freeze {
      return [ (shift)->gimme_as_perl ];
  }

  sub px_thaw {
      my $class = shift;
      my $self = $class->new( @_ );
  }

  1;

=head1 DESCRIPTION

B<Tangram::Complicity> does not exist.  To make matters worse, it
isn't even implemented.  This page is a big FIXME for the code it
refers to.  This page merely documents the API that classes must
implement to be safely stored by C<Tangram::Type::Dump::flatten>.

Note that to avoid unnecessary copying of memory structures from A to
B, this method operates "in-place".

So, therefore it is necessary for the reference type used in the
return value, to be the same as the one in the real object.  This is
explained later under L<reftype mismatch>.

So - for instance, for L<Set::Object> objects, which have a
C<px_freeze> method of:

  sub px_freeze {
      my $self = shift;
      return $self->members;
  }

  sub px_thaw {
      my $class = shift;
      return $class->new(@_);
  }

[ note: This differs from the L<Storable> API (C<STORABLE_freeze> and
C<STORABLE_thaw>).  This interface is actually reasonably sane - the
Storable API required custom XS magic for Set::Object, for instance.
Which has been implemented, but we've learned the lesson now :) ]

In essence, the C<px_freeze> method means "marshall yourself to pure
Perl data types".  Note that different serialisation tools will treat
ties, overload and magic remaining on the structure in their own way -
so, create your own type of magic (a la L<Pixie::Info>) if you really
want to hang out-of-band information off them.

=head2 reftype mismatch

If you get a C<reftype mismatch> error, it is because your
B<YourClass-E<gt>px_thaw> function returned a different type of
reference than the one that was passed to store to
B<YourClass-E<gt>px_freeze>.

This restriction only applies to the return value of the constructor
C<px_thaw>, so this is usually fine.  The return value from
C<px_freeze> will be wrapped in a (blessed) container of the correct
reference type, regardless of its return type.

ie. your function is called as:

   %{ $object } = %{ YourClass->px_thaw(@icicle) };

   @{ $object } = @{ YourClass->px_thaw(@icicle) };

   ${ $object } = ${ YourClass->px_thaw(@icicle) };

   *{ $object } = *{ YourClass->px_thaw(@icicle) };

   my $tmp = YourClass->px_thaw(@icicle);
   $object = sub { goto $tmp };

This is an analogy, no temporary object is actually used in the scalar
case, for instance; due to the use of tie.

The reason for this is to allow for circular and back-references in
the data structure; those references that point back point to the real
blessed object, so to avoid the overhead of a two-pass algorithm, this
restriction is made.  This is why the value is passed into
STORABLE_thaw as $_[0].  For most people, it won't make a difference.

However, it I<does> have the nasty side effect that serialisers that
can't handle all types of pure Perl data structures (such as, all
current versions of YAML) are unable to store blessed scalars (eg,
Set::Object's).

=cut

