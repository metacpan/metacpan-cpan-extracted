package Path::Class::Iterator;

use strict;
use warnings;
use Path::Class;
use Carp;
use Iterator;

use base qw/ Class::Accessor::Fast /;

our $VERSION = '0.07';
our $Err;
our $debug = $ENV{PERL_TEST} || $ENV{PERL_DEBUG} || 0;

if ($debug)
{
    require Data::Dump;
}

my @acc = qw/
  root
  start
  follow_symlinks
  follow_hidden
  iterator
  error_handler
  error
  show_warnings
  breadth_first
  interesting
  push_queue
  pop_queue
  queue
  depth

  /;

sub _listing
{
    my $self = shift;
    my $path = shift;

    my $d = $path->open;

    unless (defined $d)
    {
        $self->error("cannot open $path: $!");
        if ($self->error_handler->($self, $path, $!))
        {
            return Iterator->new(sub { Iterator::is_done(); return undef });
        }
        else
        {
            croak "can't open $path: $!";
        }
    }

    return Iterator->new(
        sub {

            # Get next file, skipping . and ..
            my $next;
            while (1)
            {
                $next = $d->read;

                if (!defined $next)
                {
                    undef $d;    # allow garbage collection
                    Iterator::is_done();
                }

                next if !$self->follow_hidden && $next =~ m/^\./o;

                last if $next ne '.' && $next ne '..';
            }

            # Return this item
            my $f = Path::Class::Iterator::Dir->new($path, $next);
            if (-d $f)
            {
                $self->{_depth} =
                  (scalar($f->cleanup->dir_list) - $self->{_root_depth});

            }
            else
            {
                $f = Path::Class::Iterator::File->new($path, $next);
                my $p = $f->parent->cleanup;
                $self->{_depth} =
                  (scalar($p->dir_list) - $self->{_root_depth} + 1);

            }

            return $f;

        }
    );
}

sub next
{
    my $self = shift;
    my $depth = $self->cur_depth;
    my $n = $self->iterator->value;
    $n->depth($depth);
    return $n;
}

sub done
{
    my $self = shift;
    return $self->iterator->is_exhausted;
}

sub cur_depth { return $_[0]->{_depth} }

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    my %opts  = @_;
    @$self{keys %opts} = values %opts;
    bless($self, $class);
    $self->mk_accessors(@acc);

    $self->start(time());
    $self->{_depth} = 0;    # internal tracking

    $self->root or croak "root param required";
    $self->root(dir($self->root));
    unless ($self->root->open)
    {
        $Err = $self->root . " cannot be opened: $!";
        return undef;
    }

    $self->{_root_depth} = scalar($self->root->dir_list);

    $self->error_handler(
        sub {
            my ($self, $path, $msg) = @_;
            warn "skipping $path: $msg" if $self->show_warnings;
            return 1;
        }
      )
      unless $self->error_handler;

    $self->breadth_first
      ? $self->pop_queue(
        sub {
            my $self = shift;
            return pop(@{$self->{queue}});
        }
      )
      : $self->pop_queue(
        sub {
            my $self = shift;
            return shift(@{$self->{queue}});
        }
      );

    $self->push_queue(sub { my $self = shift; push(@{$self->{queue}}, @_); });

    my $files = $self->_listing($self->root);

    $self->queue([]);
    $self->iterator(
        Iterator->new(
            sub {

                # If no more files in current directory,
                # get next directory off the queue
                while ($files->is_exhausted)
                {

                    # Nothing else on the queue? Then we're done .
                    if (!$self->queue->[0])
                    {
                        undef $files;    # allow garbage collection
                        Iterator::is_done();
                    }

                    # Create an iterator to return the files in that directory
                    carp Data::Dump::pp($self->queue) if $debug;

                    $files = $self->_listing($self->pop_queue->($self));
                }

                # Get next file in current directory
                my $next = $files->value;

                if (!$self->follow_symlinks)
                {
                    while (-l $next && $files->isnt_exhausted)
                    {
                        $next = $files->value;
                    }
                }

                # remember dirs for recursing later
                # unless they exceed depth
                carp join("\n", '=' x 50, "$next", $self->cur_depth) if $debug;
                if (-d $next)
                {

            # BUG?? does checking cur_depth() here invoke our bug?

                    unless (   $self->depth
                            && $self->cur_depth > $self->depth)
                    {
                        $self->push_queue->($self, $next);
                        if ($self->interesting)
                        {
                            my $new = $self->interesting->($self, $self->queue);
                            croak
                              "return value from interesting() must be an ARRAY ref"
                              unless ref $new eq 'ARRAY';
                            $self->queue($new);
                        }
                    }
                }

                return $next;
            }
        )
    );

    return $self;
}

1;


package Path::Class::Iterator::File;
use base qw( Path::Class::File Class::Accessor::Fast );
__PACKAGE__->mk_accessors('depth');

1;

package Path::Class::Iterator::Dir;
use base qw( Path::Class::Dir Class::Accessor::Fast );
__PACKAGE__->mk_accessors('depth');

1;


__END__

=pod

=head1 NAME

Path::Class::Iterator - walk a directory structure

=head1 SYNOPSIS

  use Path::Class::Iterator;
  
  my $dir = shift @ARGV || '';

  my $iterator = Path::Class::Iterator->new(
                        root            => $dir,
                        depth           => 2
                        interesting     => sub { return [sort {"$a" cmp "$b"} @{$_[1]}] }
                        follow_symlinks => 1,
                        follow_hidden   => 0,
                        breadth_first   => 1,
                        show_warnings   => 1
                        );

  until ($iterator->done)
  {
    my $f = $iterator->next;
    # do something with $f
    # $f is a Path::Class::Dir or Path::Class::File object
  }

=head1 DESCRIPTION

Path::Class::Iterator walks a directory structure using an iterator.
It combines the L<Iterator> closure technique
with the magic of L<Path::Class>.

It is similar in idea to L<Iterator::IO> and L<IO::Dir::Recursive> 
but uses L<Path::Class> objects instead of L<IO::All> objects. 
It is also similar to the L<Path::Class::Dir>
next() method, but automatically acts recursively. In fact, it is similar
to many recursive L<File::Find>-type modules, but not quite exactly like them.
If it were exactly like them, I wouldn't have written it. I think.

I cribbed much of the Iterator logic directly from L<Iterator::IO> and married
it with Path::Class. This module is inspired by hearing Mark Jason Dominus's
I<Higher Order Perl> talk at OSCON 2006. L<Iterator::IO> is also inspired by MJD's
iterator ideas, but takes it a slightly different direction.

=head1 METHODS

=head2 new( %I<opts> )

Instantiate a new iterator object. %I<opts> may include:

=over

=item root

The root directory in which you want to start iterating. This
parameter is required.

=item follow_hidden

Files and directories starting with a dot B<.> are skipped by default.
Set this to true to include these hidden items in your iterations.

=item follow_symlinks

Symlinks (or whatever returns true with the built-in B<-l> flag on your system)
are skipped by default. Set this to true to follow symlinks.

=item error_handler

A sub ref for handling L<IO::Dir> open() errors. Example would be if you lack
permission to a directory. The default handler is to simply skip that directory.

The sub ref should expect 3 arguments: the iterator object, the L<Path::Class>
object, and the error message (usually just $!).

The sub ref MUST return a true value or else the iterator will croak.

=item show_warnings

If set to true (1), the default error handler will print a message on stderr each
time it is called.

=item breadth_first

Iterate over all the contents of a dir before descending into any subdirectories.
The default is 0 (depth first), which is similar to L<File::Find>.
B<NOTE:> This feature will likely not do what you expect if you also use the 
interesting() feature.

=item interesting

A sub ref for manipulating the queue. It should expect 2 arguments: the iterator object
and an array ref of L<Path::Class::Dir> objects. It should return an array ref of
L<Path::Class::Dir> objects.

This feature implements what MJD calls I<heuristically guided search>.

=item depth

Do not recurse past I<n> levels. You could also implement the depth feature with 
interesting, but this is easier. Default is undef (exhaustive recursion).

B<NOTE:> I<n> is calculated relative to I<root>, not the absolute depth of the item.
A depth of B<1> means do not recurse deeper than I<root> itself, while a depth of B<2>
means "descend one level below I<root>".

=back

=head2 next

Returns the next file or directory from the P::C::I object. The return value will
be either a Path::Class::Iterator::File object or Path::Class:Iterator::Dir object.
Both object types are subclasses of their respective Path::Class types and inherit
all their methods and features, plus a B<depth()> method for getting the depth of the
object relative to the I<root>. 

B<NOTE:> The depth() method returns the depth of the P::C::I::Dir or P::C::I::File object.
See cur_depth() to get the current depth of the P::C::I object.

=head2 start

Returns the start time in Epoch seconds that the P::C::I object was
first created.

=head2 done

Returns true if the P::C::I object has run out of items to iterate over.

=head2 iterator

Returns the internal Iterator object. You probably don't want that, but just in case.

=head2 root

Returns the B<root> param set in new().

=head2 follow_symlinks

Get/set the param set in new().

=head2 follow_hidden

Get/set the param set in new().

=head2 error_handler

Get/set the subref used for handling errors.

=head2 error

Get the most recent object error message.

=head2 show_warnings

Get/set flag for default error handler.

=head2 breadth_first

Returns value set in new().

=head2 interesting

Get/set subref for manipulating the queue().

=head2 depth

Get/set the Iterator recursion depth. Default is undef (infinite).

B<NOTE:> This is not the same depth() method as on the return value of next().
This depth() method affects the recursion level for the Iterator object itself.

=head2 push_queue->( I<iterator_object>, I<P::C_object> )

Add a I<Path::Class> object to the internal queue. This method
is used internally.

=head2 pop_queue->( I<iterator_object> )

Remove a I<Path::Class> object from the queue. This method is used
internally. Returns the next I<Path::Class> object for iteration,
based on I<breadth_first> setting.

=head2 queue

Get/set current queue. Value must be an ARRAY ref.

=head2 cur_depth

Returns the current Iterator depth relative to I<root>.

B<CAVEAT:> Because of the way the iterator logic works internally, the value of
cur_depth() may change after you call next(), so the order you call next() and
cur_depth() may create an off-by-1 error in your code if you're not careful. 
That's because cur_depth() returns the current depth of the Iterator, 
not the next() value.

 my $depth = $iterator->cur_depth;
 my $f = $iterator->next;
 # $depth == $f->depth()
 
 my $f = $iterator->next;
 my $depth = $iterator->cur_depth;
 # $depth might not == $f->depth()
 
It's likely you want to use the depth() method on the return value of next() anyway.
See the next() method.

=head1 EXAMPLES

See the t/ directory for examples of error_handler() and interesting().

=head1 SEE ALSO

I<Higher Order Perl>, Mark Jason Dominus, Morgan Kauffman 2005.

L<http://perl.plover.com/hop/>

L<Iterator>, L<Iterator::IO>, L<Path::Class>, L<IO::Dir::Recursive>, L<IO::Dir>

=head1 BUGS

The cur_depth() caveat is a probably a bug, but since we have a depth() method

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
