package Path::Class::Tiny;

use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.04'; # VERSION

use Exporter;
our @EXPORT = qw< cwd path file >;

sub import
{
	no strict 'refs';
	*{ caller . '::dir' } = \&_global_dir if @_ <= 1 or grep { $_ eq 'dir' } @_;
	goto \&Exporter::import;
}


use Carp;
use Module::Runtime qw< require_module >;


use File::Spec ();
use Path::Tiny ();
our @ISA = qw< Path::Tiny >;


sub path
{
	bless Path::Tiny::path(@_), __PACKAGE__;
}

sub cwd
{
	require Cwd;
	path(Cwd::getcwd());
}

*file = \&path;
sub _global_dir { @_ ? path(@_) : path(Path::Tiny->cwd) }

# just like in Path::Tiny
sub new { shift; path(@_) }
sub child { path(shift->[0], @_) }


# This seemed like a good idea when I originally conceived this class.  Now,
# after further thought, it seems wildly reckless.  Who knows?  I may swing
# back the other way before we're all done.  But, for now, I think we're
# leaving this out, and that may very well end up being a permanent thing.
#
# sub isa
# {
#	my ($obj, $type) = @_;
#	return 1 if $type eq 'Path::Class::File';
#	return 1 if $type eq 'Path::Class::Dir';
#	return 1 if $type eq 'Path::Class::Entity';
#	return $obj->SUPER::isa($type);
# }


# essentially just reblessings
sub parent		{ path( &Path::Tiny::parent   )          }
sub realpath	{ path( &Path::Tiny::realpath )          }
sub copy_to		{ path( &Path::Tiny::copy     )          }
sub children	{ map { path($_) } &Path::Tiny::children }

# simple correspondences
*dir		=	\&parent;
*subdir		=	\&child;
*rmtree		=	\&Path::Tiny::remove_tree;

# more complex corresondences
sub cleanup		{ path(shift->canonpath) }
sub open		{ my $io_class = -d $_[0] ? 'IO::Dir' : 'IO::File'; require_module $io_class; $io_class->new(@_) }


# wrappers
sub touch
{
	my ($self, $dt) = @_;
	$dt = $dt->epoch if defined $dt and $dt->can('epoch');
	$self->SUPER::touch($dt);
}

sub move_to
{
	my ($self, $dest) = @_;
	$self->move($dest);
	# if we get this far, the move must have succeeded
	# this is basically the way Path::Class::File does it:
	my $new = path($dest);
	my $max_idx = $#$self > $#$new ? $#$self : $#$new;
	# yes, this is a mutator, which could be considered bad
	# OTOH, the file is actually mutating on the disk,
	# so you can also consider it good that the object mutates to keep up
	$self->[$_] = $new->[$_] foreach 0..$max_idx;
	return $self;
}


# reimplementations

sub dir_list
{
	my $self = shift;
	my @list = ( File::Spec->splitdir($self->parent), $self->basename );

	# The return value of dir_list is remarkably similar to that of splice: it's identical for all
	# cases in list context, and even for one case in scalar context.  So we'll cheat and use splice
	# for most of the cases, and handle the other two scalar context cases specially.
	if (@_ == 0)
	{
		return @list;			# will DTRT regardless of context
	}
	elsif (@_ == 1)
	{
		return wantarray ? splice @list, $_[0] : $list[shift];
	}
	else
	{
		return splice @list, $_[0], $_[1];
	}
}
# components is really just an alias for `dir_list`
*components	=	\&dir_list;


# This is more or less how Path::Class::File does it.
sub slurp
{
	my ($self, %args) = @_;
	my $splitter     = delete $args{split};
	$args{chomp}   //= delete $args{chomped} if exists $args{chomped};
	$args{binmode} //= delete $args{iomode};
	$args{binmode}  =~ s/^<// if $args{binmode};	# remove redundant openmode, if present

	if (wantarray)
	{
		my @data = $self->lines(\%args);
		@data = map { [ split $splitter, $_ ] } @data if $splitter;
		return @data;
	}
	else
	{
		croak "'split' argument can only be used in list context" if $splitter;
		croak "'chomp' argument not implemented in scalar context" if exists $args{chomp};
		return $self->Path::Tiny::slurp(\%args);
	}
}

# A bit trickier, as we have to distinguish between Path::Class::File style,
# which is optional hash + string-or-arrayref, and Path::Tiny style, which is
# optional hashref + string-or-arrayref.  But, since each one's arg hash(ref)
# only accepts a single option, we should be able to fake it fairly simply.
sub spew
{
	my ($self, @data) = @_;
	if ( @data == 3 and $data[0] eq 'iomode' )
	{
		shift @data;
		my $binmode = shift @data;
		$binmode =~ s/^(>>?)//;						# remove redundant openmode, if present
		unshift @data, {binmode => $binmode} if $binmode;
		# if openmode was '>>', redirect to `append`
		return $self->append(@data) if $1 and $1 eq '>>';
	}
	return $self->Path::Tiny::spew(@data);
}


my $_iter;
sub next
{
	$_iter //= Path::Tiny::path(shift)->iterator;
	my $p = $_iter->();
	return $p ? bless $p, __PACKAGE__ : undef $_iter;
}


# new methods

sub ef
{
	my ($self, $other) = @_;
	return $self->realpath eq path($other)->realpath;
}


sub mtime
{
	require Date::Easy::Datetime or croak("can't locate Date::Easy");
	return Date::Easy::Datetime->new(shift->stat->mtime);
}


1;


# ABSTRACT: a Path::Tiny wrapper for Path::Class compatibility
# COPYRIGHT

__END__

=pod

=head1 NAME

Path::Class::Tiny - a Path::Tiny wrapper for Path::Class compatibility

=head1 VERSION

This document describes version 0.04 of Path::Class::Tiny.

=head1 SYNOPSIS

    use Path::Class::Tiny;

    # creating Path::Class::Tiny objects
    $dir1 = path("/tmp");
    $dir2 = dir("/home");
    $foo = path("foo.txt");
    $foo = file("bar.txt");

    $subdir = $dir->child("foo");
    $bar = $subdir->child("bar.txt");

    # stringifies as cleaned up path
    $file = path("./foo.txt");
    print $file; # "foo.txt"

    # reading files
    $guts = $file->slurp;
    @lines = $file->slurp;

    # writing files
    $bar->spew( $data );
    $bar->spew( @data );

    # comparing files
    if ( $foo->ef($bar) ) { ... }

    # reading directories
    for ( $dir->children ) { ... }

=head1 DESCRIPTION

What do you do if you started out (Perl) life using L<Path::Class>, but then later on you switched
to L<Path::Tiny>?  Well, one thing you could do is relearn a bunch of things and go change a lot of
existing code.  Or, another thing would be to use Path::Class::Tiny instead.

Path::Class::Tiny is a thin(ish) wrapper around Path::Tiny that (mostly) restores the Path::Class
interface.  Where the two don't conflict, you can do it either way.  Where they do conflict, you use
the Path::Class way.  Except where Path::Class is totally weird, in which case you use the
Path::Tiny way.

Some examples:

=head2 Creating file/dir/path objects

Path::Class likes you to make either a C<file> object or a C<dir> object.  Path::Tiny says that's
silly and you should just make a C<path> object.  Path::Class::Tiny says you can use any of the 3
words you like; all the objects will be the same underneath.

    my $a = file('foo', 'bar');
    my $b = dir('foo', 'bar');
    my $c = path('foo', 'bar');
    say "true" if $a eq $b;         # yep
    say "true" if $b eq $c;         # also yep

=head2 Going up or down the tree

Again, both styles work.

    my $d = dir("foo");
    my $up = $d->dir;               # this works
    $up = $d->parent;               # so does this
    $up = $d->dir->parent;          # sure, why not?
    my $down = $d->child('bar');    # Path::Tiny style
    my $down = $d->subdir('bar');   # Path::Class style

=head2 Slurping files

This mostly works like Path::Class, in that the return value is context-sensitive, and options are
sent as a hash and B<not> as a hashref.

    my $data = $file->slurp;                        # one big string
    my @data = $file->slurp;                        # one element per line
    my @data = $file->slurp(chomp => 1);            # chomp every line
    my @data = $file->slurp(iomode => '<:crlf');    # Path::Class style; works
    my @data = $file->slurp(binmode => ':crlf');    # vaguely Path::Tiny style; also works
    my @data = $file->slurp({binmode => ':crlf'});  # this one doesn't work
    my $data = $file->slurp(chomp => 1);            # neither does this one, because it's weird

=head1 DETAILS

B<This module is still undergoing active development.>  While the general UI is somewhat constrained
by the design goals, specific choices may, and almost certainly will, change.  I think this module
can be useful to you, but for right now I would only use it for personal scripts.

A Path::Class::Tiny C<isa> Path::Tiny, but I<not> C<isa> Path::Class::Entity.  At least not
currently.

Path::Class::Tiny is not entirely a drop-in replacement for Path::Class, and most likely never will
be.  In particular, I have no interest in implementing any of the "foreign" methods.  However, it
should work for most common cases, and, if it doesn't, patches are welcome.

Performance of Path::Class::Tiny should be comparable to Path::Tiny.  Again, if it's not, please let
me know.

The POD is somewhat impoverished at the moment.  Hopefully that will improve over time.  Again,
patches welcomed.

=head1 PATH::CLASS STYLE METHODS

=head2 cleanup

Redirects to L<Path::Tiny/canonpath>.

=head2 components

Basically just like C<components> from L<Path::Class::Dir>, which means that it accepts offset and
length arguments (which L<Path::Class::File> doesn't).  Another nice difference: calling
C<components> from Path::Class::File in scalar context doesn't do anything useful, whereas
Path::Class::Tiny always returns the number of components, which is (hopefully) what you expect.

The only real difference between Path::Class::Tiny's C<components> and Path::Class::Dir's
C<components> is that you don't get the volume returned in the Path::Class::Dir version.  In this
version, the volume (if any) will just be part of the first component in the list.

=head2 dir_list

Just an alias for L</components>, so it also works on files (L<Path::Class::File> doesn't have a
C<dir_list> method).  This means the basename is always the last entity in the list, even for files.
Basically this is just here for compatibility's sake, and you probably shouldn't use it for new
code, because the name doesn't really sound like what it does.

=head2 next

Uses L<Path::Tiny/iterator> (with its default value of no recursion) to implement the interface of
C<next> from L<Path::Class::Dir>.  The primary difference this engenders is that the
Path::Class::Dir version I<will> return C<.> and C<..>, whereas this version will I<not>.  I also
don't guarantee this version is re-entrant.

=head2 rmtree

Just an alias to L<Path::Tiny/remove_tree>.

=head2 subdir

Just an alias to L<Path::Tiny/child>.

=head2 touch

Basically just calls L<Path::Tiny/touch>, which is better than L<Path::Class::File/touch> in a
couple of ways:

=over

=item *

It returns the path object, which is useful for chaining.

=item *

It takes an argument, so you can set the time to something other than "now."

=back

However, C<Path::Class::Tiny::touch> is even better than that!  It adds another cool feature:

=over

=item *

If the argument is an object, and that object has an C<epoch> method, it will call it and pass the
result on to C<Path::Tiny::touch>.

=back

The practical result is that your argument to C<touch> can be an integer (number of epoch seconds),
or any of the most popular datetime objects: L<DateTime>, L<Time::Piece>, L<Time::Moment>,
L<Date::Easy>, and possibly others as well.

B<Potential Incompatibility:> The only way these additional features could be incompatible with
existing C<Path::Class> code is if it were relying on the return value from C<touch>, which in
C<Path::Class> is either the return from C<open> or the return from C<utime> (so theoretically it's
true if the C<touch> was successful and false otherwise).  C<Path::Tiny> (and thus
C<Path::Class::Tiny>) will instead throw an exception if the C<touch> was unsuccessful and return
the chained object.

=head2 copy_to

Just an alias to L<Path::Tiny/copy>.

=head2 move_to

There are two big differences between L<Path::Tiny/move> and L<Path::Class::File/move_to>:

=over

=item *

On failure, C<Path::Class::File::move_to> returns undef, while C<Path::Tiny::move> throws an
exception.

=item *

On success, C<Path::Tiny::move> just returns true.  C<Path::Class::File::move_to>, on the other
hand, returns the path object for chaining, B<which has been modified to have the new name>.

=back

C<Path::Class::Tiny> splits the difference by throwing an exception on error, and returning the
modified C<$self> on success.  B<That means this method is a mutator!>  Consequently, use of this
method means your objects are not immutable.  No doubt many people will object to this behavior.
However, after some internal debate, it was decided to retain this aspect of L<Path::Class>'s
interface for the following reasons:

=over

=item *

It keeps from breaking existing C<Path::Class> code that you're trying to convert over to
C<Path::Class::Tiny>.  While we do implement I<some> breaking changes, most of them feel a lot
less likely to be encountered in real code than this one.

=item *

The real-world thing that the object represents--that is, the file on disk--is itself being mutated.
If the object is not changed to reflect the new reality, then any stray copies of it lying around
now reference a file that doesn't exist.  So it seems just about as likely to I<fix> a problem as to
cause one.

=item *

If you don't like the mutability, just call L</move> instead.

=back

=head1 PATH::TINY STYLE METHODS

Since a C<Path::Class::Tiny> object C<isa> L<Path::Tiny> object, the vast majority of C<Path::Tiny>
methods just work the same way they always have.  Notable methods (with exceptions or just
clarifications) are listed below.

=head2 move

Unchanged from L<Path::Tiny>, which means it's I<quite> different from L</move_to>.  In particular,
C<move> does B<not> mutate the object, which means that code like this:

    my $file = path($whatever);
    $file->move($new_name);
    say $file->basename;

does B<not> give you the basename of the file-as-it-is, but rather the basename of the
file-as-it-was, which could be considered less useful.  But at least it doesn't mutate the object,
so it's got that going for it.  If you actually I<want> the object to be mutated, try L</move_to>
instead.

=head1 NEW METHODS

=head2 ef

Are you tired of trying to remember which method (or combination of methods) you have to call to
verify that two files are actually the same file, where one path might be relative and the other
absolute, or one might be a symlink to the other, or one might be a completely different path but
one directory somewhere in the middle is really a symlink to a directory in the middle of the other
path so they wind up being the same path, really?  Yeah, me too.  In C<bash>, this is super easy:

    if [[ $file1 -ef $file2 ]]

Well, why shouldn't it be easy in Perl too?  Okay, now it is:

    my $file1 = path($whatever);
    if ( $file1->ef($file2) )

While C<$file1> must obviously be a Path::Class::Tiny, C<$file2> can be another Path::Class::Tiny
object, or a Path::Class::Entity, or a Path::Tiny, or just a bare string.  Most anything should
work, really.  Do note that both files must actually exist in the filesystem though.  It's also okay
for both to be exactly the same object:

    if ( $file1->ef($file1) )   # always true

=head2 mtime

This is mostly just a shortcut for going through C<stat>, but it has the added benefit of producing
a L<Date::Easy::Datetime> object.  Thus:

    my $file = path($whatever);
    $file->mtime == $file->stat->mtime        # true, but maybe not for the reason you thought
    $file->mtime->epoch == $file->stat->mtime # true, and more reflective of reality
    $file->mtime->isa('Date::Easy::Datetime') # true, which can be handy:

    say $file->mtime->as('-Ymd')    # day portion of mtime, in YYYY-mm-dd format
    say "file is from the future!"  # this one will work, but only if you have
        if $file->mtime > now;      # previously done `use Date::Easy` (to get `now`)

Note that C<Date::Easy::Datetime> is loaded on demand, so:

=over

=item *

It is not necessary for you to load it ahead of time.

=item *

However, as the example above mentions, you don't get all the exports you would if you C<use
Date::Easy>, so you may wish to do that anyway.

=item *

If L<Date::Easy> is not installed, you get a runtime error when you call C<mtime>.

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Path::Class::Tiny

=head2 Bugs / Feature Requests

This module is on GitHub.  Feel free to fork and submit patches.  Please note that I develop
via TDD (Test-Driven Development), so a patch that includes a failing test is much more
likely to get accepted (or at least likely to get accepted more quickly).

If you just want to report a problem or suggest a feature, that's okay too.  You can create
an issue on GitHub here: L<http://github.com/barefootcoder/path-class-tiny/issues>.

=head2 Source Code

none
L<https://github.com/barefootcoder/path-class-tiny>

  git clone https://github.com/barefootcoder/path-class-tiny.git

=head1 AUTHOR

Buddy Burden <barefootcoder@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
