package
    threadsx::shared;	## no index
use strict;
use warnings;
use threads::shared;

our $VERSION = '0.14';

######################################################################
#
# useful edits and extensions to threads::shared
#
# 1. support splice on shared arrays
# 2. support CODE refs in shared data structures
# 3. support GLOB refs in shared data structures
#

$threadsx::shared::shared = 0;
our $share_code;
our $share_glob;
our $make_shared;

sub import {
    no warnings 'redefine';
    if ($threadsx::shared::shared++) {

    }
    if (!defined &share_orig) {
	*share_orig = \&threads::shared::share;
    }
    *threads::shared::shared_clone = \&threadsx::shared::_shared_clone;
    *threads::shared::share = \&threadsx::shared::_share;
    *threads::shared::tie::SPLICE = \&threadsx::shared::_tie_SPLICE;
    $share_code = 1;
    $share_glob = 1;
    my $caller = caller();
    foreach my $sym (qw(share is_shared cond_wait cond_timewait
		        cond_signal cond_broadcast shared_clone bless)) {
	next if $sym eq 'bless' && !$threads::threads;
	no strict 'refs';
	*{$caller . '::' . $sym} = \&{'threads::shared::' . $sym};
    }
}

sub _tie_SPLICE {
    use B;
    my ($tied,$off,$len,@list) = @_;
    my @bav = B::AV::ARRAY($tied);
    my $arraylen = 0 + @bav;
#   ::xdiag("SPLICE \@A,$off,$len/$arraylen,\@B:" . (0+@list));

    $off ||= 0;
    if ($off < 0) {
	$off += $arraylen;
	if ($off < 0) {
	    require Carp;
	    Carp::croak("Modification of non-createable array value "
			. "attempted, subscript $_[1]");
	}
    }
    if (!defined $len || $len eq 'undef') {
	$len = $arraylen - $off;
    }
    if ($len < 0) {
	$len += $arraylen - $off;
	if ($len < 0) {
	    $len = 0;
	}
    }
#    if ($off+$len > $arraylen) {
#	$len = $arraylen-$off;
#    }

    my (@tmp, @val);

    for (my $i=0; $i<$off; $i++) {
	my $fetched = $bav[$i]->object_2svref;
	push @tmp, $$fetched;
    }
    for (my $i=0; $i<$len; $i++) {
	last if $i+$off > $arraylen;
	my $fetched = $bav[$i+$off]->object_2svref;
	push @val, defined($fetched) && $$fetched;
    }
    push @tmp, map { _shared_clone($_) } @list;
    for (my $i=$off+$len; $i<$arraylen; $i++) {
	my $fetched = $bav[$i]->object_2svref;
	push @tmp, $$fetched;
    }

    # is there a better way to clear the array?
    $tied->POP for 0..$arraylen;
    $tied->PUSH(@tmp);
    return wantarray ? @val : @val ? $val[-1] : undef;
}

sub _share (\[$@%]) {
    if (ref($_[0]) eq 'CODE' && $share_code) {
	return $_[0] = threadsx::shared::code->new( $_[0] );
    } elsif (ref($_[0]) eq 'GLOB' && $share_glob) {
	return $_[0] = threadsx::shared::glob->new( $_[0] );
    } elsif (ref($_[0]) eq 'REF') {
	if (ref(${$_[0]}) eq 'CODE' && $share_code) {
	    return $_[0] = threadsx::shared::code->new( ${$_[0]} );
	} elsif (ref(${$_[0]}) eq 'GLOB' && $share_glob) {
	    return $_[0] = threadsx::shared::glob->new( ${$_[0]} );
	}
    }
    share_orig( $_[0] );
}

sub _shared_clone {
    return $make_shared->(shift, {});
};


# copied and modified from threads::shared 1.48
$make_shared = sub {
    package
	threads::shared;
    use Scalar::Util qw(reftype refaddr blessed);
    my ($item,$cloned) = @_;
    return $item if (!ref($item) || threads::shared::is_shared($item)
		     || !$threads::threads);
    my $addr = refaddr($item);
    return $cloned->{$addr} if exists $cloned->{$addr};
    my ($ref_type,$copy) = reftype($item);
    if ($ref_type eq 'ARRAY') {
	$copy = &threads::shared::share( [] );
	$cloned->{$addr} = $copy;
	push @$copy, map { $make_shared->($_,$cloned) } @$item;
    } elsif ($ref_type eq 'HASH') {
	my $ccc = {};
	$copy = &threads::shared::share( $ccc );
	$cloned->{$addr} = $copy;
	while (my ($k,$v) = each %$item) {
	    $copy->{$k} = $make_shared->($v,$cloned);
	}
    } elsif ($ref_type eq 'SCALAR') {
	$copy = \do{ my $scalar = $$item };
	threads::shared::share($copy);
	$cloned->{$addr} = $copy;
    } elsif ($ref_type eq 'REF') {
	if ($addr == refaddr($$item)) {
	    $copy = \$copy;
	    threads::shared::share($copy);
	    $cloned->{$addr} = $copy;
	} else {
	    my $tmp;
	    $copy = \$tmp;
	    threads::shared::share($copy);
	    $cloned->{$addr} = $copy;
	    $tmp = $make_shared->($$item,$cloned);
	}
    } elsif ($ref_type eq 'CODE') {
	$copy = $cloned->{$addr} = threadsx::shared::code->new($item);
    } elsif ($ref_type eq 'GLOB') {
	$copy = $cloned->{$addr} = threadsx::shared::glob->new($item);
    } else {
	require Carp;
	if (! defined $threads::shared::clone_warn) {
	    Carp::croak("Unsupported ref type: ", $ref_type);
	} elsif ($threads::shared::clone_warn) {
	    Carp::carp("Unsupported ref type: ", $ref_type);
	}
	return undef;   
    }

    # If input item is an object, then bless the copy into the same class
    if (my $class = blessed($item)) {
        CORE::bless($copy, $class);
    }

    # Clone READONLY flag
    if ($ref_type eq 'SCALAR') {
        if (Internals::SvREADONLY($$item)) {
            Internals::SvREADONLY($$copy, 1) if ($] >= 5.008003);
        }
    }
    if (Internals::SvREADONLY($item)) {
        Internals::SvREADONLY($copy, 1) if ($] >= 5.008003);
    }

    return $copy;
};

package
    threadsx::shared::code;
use overload fallback => 1, '&{}' => 'code';
use Carp;
our %CODE_LOOKUP;
sub new {
    my ($pkg,$ref) = @_;
    if (ref($ref) eq $pkg) {
	carp "threadsx::shared::code: ref is already shareable code";
	return $ref;
    } elsif (ref($ref) ne 'CODE') {
	croak "usage: $pkg->new(CODE)";
    }
    my $id = Scalar::Util::refaddr($ref);
    $CODE_LOOKUP{$id} //= $ref;
    threads::shared::shared_clone(CORE::bless \$id, $pkg);
}
sub code {
    return $CODE_LOOKUP{${$_[0]}} || 
	sub { croak "threadsx::shared::code: bad ",__PACKAGE__," id ${$_[0]}" };
}

package
    threadsx::shared::glob;
use overload fallback => 1, '*{}' => 'glob';
use Carp;
our %GLOB_LOOKUP;
sub new {
    my ($pkg,$ref) = @_;
    if (ref($ref) eq $pkg) {
	carp "threadsx::shared::glob: ref is already shareable glob";
	return $ref;
    } elsif (ref($ref) ne 'GLOB') {
	croak "usage: $pkg->new(GLOB)";
    }
    my $id = Scalar::Util::refaddr($ref);
    $GLOB_LOOKUP{$id} //= $ref;
    threads::shared::shared_clone(CORE::bless \$id, $pkg);
}
sub glob { return $GLOB_LOOKUP{${$_[0]}} || *STDERR }

1;

=head1 NAME

threadsx::shared - useful extensions to threads::shared

=head1 VERSION

0.14

=head1 DESCRIPTION



=head1 NAME

threadsx::shared - extension to C<threads::shared>, the Perl extension
for sharing data structures between threads

=head1 VERSION

This document describes threadsx::shared version 0.14

=head1 DESCRIPTION

See L<threads::shared> for the synopsis and API of the C<threads::shared>
module. This module extends C<threads::shared> to give it three new
capabilities:

=over 4

=item 1. Support the SPLICE operation on shared arrays

=item 2. Provide a workaround to share CODE references between threads

=item 3. Provide a workaround to share GLOB references between threads

=back

=head2 SPLICE operation on shared arrays

Current versions of L<threads::shared> do not support splice operationss
on arrays that have been shared.

    $ perl -Mthreads -Mthreads::shared -e \
        'share(@a);@a=(1..10);print splice @a,3,3'
    Splice not implemented for shared arrays at -e line 1.

The C<threadsx::shared> module works around this restriction by
hijacking the C<threads::shared::tie::SPLICE> method and emulating the
splice operation without a call to the builtin C<splice> function.
The performance isn't as good as a native C<splice> call, but it is
better than a sharp stick in the eye.

    $ perl -Mthreads -Mthreadsx::shared -e \
        'share(@a);@a=(1..10);print splice @a,3,3'
    456


=head2 Sharing CODE references

Current versions of L<threads::shared> do not support sharing of code
references or data structures that contain code references

    $ perl -Mthreads -Mthreads::shared -e \
        '$dispatch=shared_clone( {bar=>sub{42}, baz=>\&CORE::warn} )'
    Unsupported ref type: CODE at -e line 1.

The C<threadsx::shared> module employs a workaround, hijacking the method
used by C<threads::shared::shared_clone> to identify and share references.
The new method substitutes each CODE reference with a shareable,
overloaded object that behaves like the underlying CODE reference.

    $ perl -Mthreads -Mthreadsx::shared -e \
        '$dispatch=shared_clone( {bar=>sub{42}, baz=>\&CORE::warn} );
         print $dispatch->{bar}->()'
    42

This feature requires perl v5.18 or better.

=head2 Sharing GLOB references

Current versions of L<threads::shared> do not support sharing of GLOB
references or data structures that contain GLOB references

    $ perl -Mthreads -Mthreads::shared -e \
         'open my $fh,">foo";$x=shared_clone({foo=>$fh})'
    Unsupported ref type: GLOB at -e line 1.

The C<threadsx::shared> module employs a workaround, hijacking the
method used by C<threads::shared::shared_clone> to identify and share
referemces. The new method substitutes each GLOB reference with a
shareable, overloaded object that behaves like the underlying GLOB
reference.

    $ perl -Mthreads -Mthreadsx::shared -e \
         'open $fh,">foo";$x=shared_clone({foo=>$fh});
          print {$x->{foo}} "Hello world\n";close $x->{foo};
          print `cat foo`'
    Hello world

This feature requires perl 5.18 or better.

=head1 EXPORT

Like L<threads::shared>,
the following functions are exported by this module: C<share>,
C<shared_clone>, C<is_shared>, C<cond_wait>, C<cond_timedwait>, C<cond_signal>
and C<cond_broadcast>

Note that if this module is imported when L<threads> has not yet been loaded,
then these functions all become no-ops.  This makes it possible to write
modules that will work in both threaded and non-threaded environments.

=head1 FUNCTIONS

See L<threads::shared/"FUNCTIONS">. The features implemented in
C<threadsx::shared> do not define any new functions.

=head1 NOTES

Like L<threads::shared>, C<threadsx::shared> is designed to 
disable itself silently if threads are not
available.  This allows you to write modules and packages that can be used
in both threaded and non-threaded applications.

If you want access to threads, you must C<use threads> before you
C<use threadsx::shared>.  L<threads> will emit a warning if you use it after
L<threadsx::shared>.

=head1 WARNINGS

The warnings emitted by C<threadsx::shared> are the same as those
produced by L<threads::shared>.

=over 4

=item cond_broadcast() called on unlocked variable

=item cond_signal() called on unlocked variable

See L</"cond_signal VARIABLE">, above.

=back

=head1 BUGS AND LIMITATIONS

Treat shared CODE and GLOB references in shared data structures
as read-only.

When C<share> is used on arrays, hashes, array refs or hash refs, any data
they contain will be lost.

  my @arr = qw(foo bar baz);
  share(@arr);
  # @arr is now empty (i.e., == ());

  # Create a 'foo' object
  my $foo = { 'data' => 99 };
  bless($foo, 'foo');

  # Share the object
  share($foo);        # Contents are now wiped out
  print("ERROR: \$foo is empty\n")
      if (! exists($foo->{'data'}));

Therefore, populate such variables B<after> declaring them as shared.  (Scalar
and scalar refs are not affected by this problem.)

It is often not wise to share an object unless the class itself has been
written to support sharing.  For example, an object's destructor may get
called multiple times, once for each thread's scope exit.  Another danger is
that the contents of hash-based objects will be lost due to the above
mentioned limitation.  See F<examples/class.pl> (in the CPAN distribution of
this module) for how to create a class that supports object sharing.

Destructors may not be called on objects if those objects still exist at
global destruction time.  If the destructors must be called, make sure
there are no circular references and that nothing is referencing the
objects, before the program ends.

=begin html

<strike>Does not support <code>splice</code> on arrays.</strike>
Does not support explicitly changing array lengths 
via $#array -- use <code>push</code> and <code>pop</code> instead.
</strike>

=end html

Taking references to the elements of shared arrays and hashes does not
autovivify the elements, and neither does slicing a shared array/hash over
non-existent indices/keys autovivify the elements.

C<share()> allows you to C<< share($hashref->{key}) >> and
C<< share($arrayref->[idx]) >> without giving any error message.  But the
C<< $hashref->{key} >> or C<< $arrayref->[idx] >> is B<not> shared, causing
the error "lock can only be used on shared values" to occur when you attempt
to C<< lock($hashref->{key}) >> or C<< lock($arrayref->[idx]) >> in another
thread.

Using C<refaddr()> is unreliable for testing
whether or not two shared references are equivalent (e.g., when testing for
circular references).  Use L<is_shared()|/"is_shared VARIABLE">, instead:

    use threads;
    use threads::shared;
    use Scalar::Util qw(refaddr);

    # If ref is shared, use threads::shared's internal ID.
    # Otherwise, use refaddr().
    my $addr1 = is_shared($ref1) || refaddr($ref1);
    my $addr2 = is_shared($ref2) || refaddr($ref2);

    if ($addr1 == $addr2) {
        # The refs are equivalent
    }

L<each()|perlfunc/"each HASH"> does not work properly on shared references
embedded in shared structures.  For example:

    my %foo :shared;
    $foo{'bar'} = shared_clone({'a'=>'x', 'b'=>'y', 'c'=>'z'});

    while (my ($key, $val) = each(%{$foo{'bar'}})) {
        ...
    }

Either of the following will work instead:

    my $ref = $foo{'bar'};
    while (my ($key, $val) = each(%{$ref})) {
        ...
    }

    foreach my $key (keys(%{$foo{'bar'}})) {
        my $val = $foo{'bar'}{$key};
        ...
    }

This module supports dual-valued variables created using C<dualvar()> from
L<Scalar::Util>.  However, while C<$!> acts
like a dualvar, it is implemented as a tied SV.  To propagate its value, use
the follow construct, if needed:

    my $errno :shared = dualvar($!,$!);

View existing bug reports at, and submit any new bugs, problems, patches, etc.
to: L<http://rt.cpan.org/Public/Dist/Display.html?Name=threadsx-shared>

For bugs in the underlying L<threads::shared> distribution, use
L<http://rt.cpan.org/Public/Dist/Display.html?Name=threads-shared>

=head1 SEE ALSO

L<threads::shared>, L<threads>, L<perlthrtut>

L<http://www.perl.com/pub/a/2002/06/11/threads.html> and
L<http://www.perl.com/pub/a/2002/09/04/threads.html>

Perl threads mailing list:
L<http://lists.perl.org/list/ithreads.html>

=head1 AUTHOR

Additional features for C<threadsx::shared> by
Marty O'Brien E<lt>mob@cpan.orgE<gt>.

Original L<threads::shared> by
Artur Bergman E<lt>sky AT crucially DOT netE<gt>

CPAN version of C<threads::shared>
produced by Jerry D. Hedden E<lt>jdhedden AT cpan DOT orgE<gt>.

=head1 LICENSE

C<threadsx::shared> and C<threads::shared> are released under the same 
license as Perl.

=cut

