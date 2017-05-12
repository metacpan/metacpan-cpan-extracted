package Module::AnyEvent::Helper;

use strict;
use warnings;

use Try::Tiny;
use AnyEvent;
use Carp;

# ABSTRACT: Helper module to make other modules AnyEvent-friendly
our $VERSION = 'v0.0.5'; # VERSION

require Exporter;
our (@ISA) = qw(Exporter);
our (@EXPORT_OK) = qw(strip_async strip_async_all bind_scalar bind_array);

sub _strip_async
{
	my ($pkg, @func) = @_;
	foreach my $func (@func) {
		croak "$func does not end with _async" unless $func =~ /_async$/;
		my $new_func = $func;
		$new_func =~ s/_async$//;

		no strict 'refs'; ## no critic (ProhibitNoStrict)
		*{$pkg.'::'.$new_func} = sub {
			shift->$func(@_)->recv;
		};
	}
}

sub strip_async
{
	shift if eval { $_[0]->isa(__PACKAGE__); };
	my $pkg = caller;
	_strip_async($pkg, @_);
}

sub strip_async_all
{
	shift if eval { $_[0]->isa(__PACKAGE__); };
	my $pkg = caller;
	my %arg = @_;
	$arg{-exclude} ||= [];
	my %exclude = map { $_.'_async', 1 } @{$arg{-exclude}};
	no strict 'refs'; ## no critic (ProhibitNoStrict)
	_strip_async($pkg, grep { /_async$/ && defined *{$pkg.'::'.$_}{CODE} && ! exists $exclude{$_}  } keys %{$pkg.'::'});
}

my $guard = sub {};

sub bind_scalar
{
	shift if eval { $_[0]->isa(__PACKAGE__); };
	my ($gcv, $lcv, $succ) = @_;

	if(!defined $lcv || ref($lcv) ne 'AnyEvent::CondVar') {
		my $ret = $lcv;
		$lcv = AE::cv;
		$lcv->send($ret);
	}
	confess 'unexpected undef code reference' unless ref($succ) eq 'CODE';

	$lcv->cb(sub {
		my $arg = shift;
		try {
			my $ret = $succ->($arg);
			$gcv->send($ret) if ref($ret) ne 'CODE' || $ret != $guard;
		} catch {
			$gcv->croak($_);
		}
	});
	$guard;
}

sub bind_array
{
	shift if eval { $_[0]->isa(__PACKAGE__); };
	my ($gcv, $lcv, $succ) = @_;

	if(!defined $lcv || ref($lcv) ne 'AnyEvent::CondVar') {
		my $ret = $lcv;
		$lcv = AE::cv;
		$lcv->send($ret);
	}
	confess 'unexpected undef code reference' unless ref($succ) eq 'CODE';

	$lcv->cb(sub {
		my $arg = shift;
		try {
			my @ret = $succ->($arg);
			$gcv->send(@ret) if @ret != 1 || ref($ret[0]) ne 'CODE' || $ret[0] != $guard;
		} catch {
			$gcv->croak($_);
		}
	});
	$guard;
}

1;

__END__

=pod

=head1 NAME

Module::AnyEvent::Helper - Helper module to make other modules AnyEvent-friendly

=head1 VERSION

version v0.0.5

=head1 SYNOPSIS

By using this module, ordinary (synchronous) method:

  sub func {
    my $ret1 = func2();
    # ...1
  
    my $ret2 = func2();
    # ...2
  }

can be mechanically translated into AnyEvent-friendly method as func_async:

  use Module::AnyEvent::Helper qw(bind_scalar strip_async_all)

  sub func_async {
    my $cv = AE::cv;
  
    bind_scalar($cv, func2_async(), sub {
      my $ret1 = shift->recv;
      # ...1
      bind_scalar($cv, func2_async(), sub {
        my $ret2 = shift->recv;
        # ...2
      });
    });

    return $cv;
  }

At the module end, calling strip_async_all makes synchronous versions of _async methods in the calling package.

  strip_async_all;

=head1 DESCRIPTION

AnyEvent-friendly versions of modules already exists for many modules.
Most of them are intended to be drop-in-replacement of original module.
In this case, return value should be the same as original.
Therefore, at the last of the method in the module, blocking wait is made usually.

  sub func {
    # some asynchronous works
    $cv->recv; # blocking wait
    return $ret;
  }

However, this blocking wait almost prohibit to use the module with plain AnyEvent, because of recursive blocking wait error.
Using Coro is one solution, and to make a variant of method to return condition variable is another.
To employ the latter solution, semi-mechanical works are required.
This module reduces the work bit.

=head1 FUNCTIONS

All functions can be exported but none is exported in default.
They can be called as class methods, also.

=head2 C<strip_async(@names)>

Make synchronous version for each specified method by C<@names>.
All method names MUST end with C<_async>.
If C<'func_async'> is passed, the following C<'func'> is made into the calling package.

  sub func { shift->func_async(@_)->recv; }

Therefore, C<func_async> MUST be callable as method.

=head2 C<strip_async_all>

=head2 C<strip_async_all(-exclude =E<gt> \@list)>

strip_async is called for all methods end with _async in the calling package.
NOTE that error occurs if function, that is not a method, having _async suffix exists.

You can specify excluding fuction name as C<@list>. Function names SHOULD NOT include _async suffix.

=head2 C<bind_scalar($cv1, $cv2, \&successor)>

C<$cv1> and C<$cv2> MUST be AnyEvent condition variables. C<\&successor> MUST be code reference.

You can consider C<$cv2> is passed to C<\&successor>, then return value of C<\&successor>, forced in scalar-context, is sent by C<$cv1>.
Actually, there is some more treatment for nested call of bind_scalar/bind_array.

=head2 C<bind_array($cv1, $cv2, \&successor)>

Similar as C<bind_scalar>, but return value of successor is forced in array-context.

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
