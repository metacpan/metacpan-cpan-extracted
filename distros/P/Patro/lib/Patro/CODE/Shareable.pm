package Patro::CODE::Shareable;

use threads;
use threads::shared;
use Scalar::Util;
use Carp;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw(share shared_clone);
our $VERSION = '0.11';

use overload
    fallback => 1,
    '&{}' => \&_invoke;

our %LOOKUP = (
    error => sub { croak "bad ", __PACKAGE__, " id ${$_[0]}" }
    );
our $share_orig;

sub new {
    my ($pkg, $coderef) = @_;
    if (ref($coderef) eq $pkg) {
	carp "Patro::CODE::Shareable: coderef is already shareable\n";
	return $coderef;
    }
    if (ref($coderef) ne 'CODE') {
	croak "usage: $pkg->new(CODEREF)";
    }
    my $id = Scalar::Util::refaddr($coderef);
    $LOOKUP{$id} //= $coderef;
    shared_clone( CORE::bless \$id, $pkg );
}

sub _invoke {
    my $id = ${$_[0]};
    $LOOKUP{$id} || $LOOKUP{"error"};
}

our $make_shared_with_code;
{
    no warnings 'redefine';

    # hijack  threads::shared::share  and  threads::shared::shared_clone
    *share = sub (\[$@%]) {
	if (ref($_[0]) eq 'CODE') {
	    # if prototype disabled
	    return $_[0] = new(__PACKAGE__, $_[0]);
	} elsif (ref($_[0]) eq 'REF' && ref(${$_[0]}) eq 'CODE') {
	    # if prototype coerces CODE to REF of CODE
	    return $_[0] = new(__PACKAGE__, ${$_[0]});
	}
	$share_orig->($_[0]);
    };

    *shared_clone = sub {
	return $make_shared_with_code->(shift, {});
    };
#    warn "Patro::CODE::Shareable::shared_clone is ",
#	\&Patro::CODE::Shareable::shared_clone;
}

$make_shared_with_code = sub {
    package threads::shared;
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
	push @$copy, map { $make_shared_with_code->($_,$cloned) } @$item;
    } elsif ($ref_type eq 'HASH') {
	my $ccc = {};
	$copy = &threads::shared::share( $ccc );
	$cloned->{$addr} = $copy;
	while (my ($k,$v) = each %$item) {
	    $copy->{$k} = $make_shared_with_code->($v,$cloned);
	}
    } elsif ($ref_type eq 'SCALAR') {
	$copy = \do{ my $scalar = $$item };
	share($copy);
	$cloned->{$addr} = $copy;
    } elsif ($ref_type eq 'REF') {
	if ($addr == refaddr($$item)) {
	    $copy = \$copy;
	    share($copy);
	    $cloned->{$addr} = $copy;
	} else {
	    my $tmp;
	    $copy = \$tmp;
	    share($copy);
	    $cloned->{$addr} = $copy;
	    $tmp = $make_shared_with_code->($$item,$cloned);
	}
    } elsif ($ref_type eq 'CODE') {
	$copy = $cloned->{$addr} = Patro::CODE::Shareable->new($item);
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

{
    no warnings 'redefine';
    $share_orig = \&threads::shared::share;
    *threads::shared::shared_clone = \&shared_clone;
    *threads::shared::share = \&share;
}

1;


=head1 NAME

Patro::CODE::Shareable - manipulate a code reference so it can be
shared across threads

=head1 SYNOPSIS

    use threads;
    use threads::shared;
    use Patro::CODE::Shareable;

    my $code = sub { print "This is an anonymous sub" };
    share($code);
    my $dispatch_table = shared_clone( { action => $code } );

=head1 DESCRIPTION

The default sharing mechanism in L<threads::shared> does not 
work for CODE references.

    use threads;
    use threads::shared;
    my $sub : shared = sub { "anonymous code ref" };
    # "Invalid value for shared scalar at ... line 3"

    use threads;
    use threads::shared;
    my $dispatch = {
        foo => sub { "taking action foo" },
        bar => sub { "taking action bar" }
    };
    $dispatch = shared_clone($dispatch);
    # "Unsupported ref type: CODE at ... line 7"

C<Patro::CODE::Shareable> describes a proxy object for a code reference
that overloads the code dereferencing operator to have the look and
feel of a C<CODE> reference, but since it's not really a C<CODE>
reference, it can be shared between threads.
    
Where possible, this module should be loaded B<after>
C<threads::shared> is loaded.

=head1 FUNCTIONS

=head2 share(SCALAR)

=head2 share(ARRAY)

=head2 share(HASH)

=head2 share(REF)

Like L<threads::shared\"share">, enables the variable in the input
to be shared across threads. Unlike C<threads::shared::share>,
this function also works when the input holds a C<CODE> reference.

=head2 $copy = shared_clone($data)

Like L<threads::shared\"shared_clone">, performs a deep inspection
of the input data structure and make any references within the
data structure shared across threads. Unlike L<threads::shared::shared_clone>,
this function supports the sharing of C<CODE> references within
the data structure.

=head1 LIMITATIONS

Using this module requires features of Perl that only work properly
on Perl v5.17.0 or better. If the code C<$shared_coderef->(@args)>
gives you a C<Not a CODE reference ...> error, a workaround is to
call C<$shared_coderef->_invoke->(@args)>. This is how the L<Patro>
distribution works around this problem for older versions of perl.

=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2017, Marty O'Brien

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
