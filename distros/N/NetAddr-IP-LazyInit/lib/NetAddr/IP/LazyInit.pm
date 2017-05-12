package NetAddr::IP::LazyInit;

use strict;
use warnings;
use NetAddr::IP qw(Zero Zeros Ones V4mask V4net netlimit);
use NetAddr::IP::Util;
use v5.10.1;

our $VERSION = eval '0.7';

=head1 NAME

NetAddr::IP::LazyInit - NetAddr::IP objects with deferred validation B<SEE DESCRIPTION BEFORE USING>

=head1 VERSION

0.6

=head1 SYNOPSIS

    use NetAddr::IP::LazyInit;

    my $ip = new NetAddr::IP::LazyInit( '10.10.10.5' );

=head1 DESCRIPTION

This module is designed to quickly create objects that may become NetAddr::IP
objects.  It accepts anything you pass to it without validation.  Once a
method is called that requires operating on the value, the full NetAddr::IP
object is constructed.

You can see from the benchmarks that once you need to instantiate NetAddr::IP
the speed becomes worse than if you had not used this module.  What I mean is
that this adds unneeded overhead if you intend to do IP operations on every
object you create.

=head1 WARNING


Because validation is deferred, this module assumes you will B<only ever give
it valid data>. If you try to give it anything else, it will happily accept it
and then die once it needs to inflate into a NetAddr::IP object.


=head1 CREDITS

This module was inspired by discussion with  Jan Henning Thorsen, E<lt>jhthorsen
at cpan.orgE<gt>, and example code he provided.  The namespace and part of the
documentation/source is inspired by DateTime::LazyInit by
Rick Measham, E<lt>rickm@cpan.orgE<gt>

I didn't have to do much so I hate to take author credit, but I am providing
the module, so complaints can go to me.

Robert Drake, E<lt>rdrake@cpan.orgE<gt>

=head1 TODO

If we could actually load NetAddr::IP objects in the background while nothing
is going on that would be neat.  Or we could create shortcut methods when the
user knows what type of input he has.  new_from_ipv4('ip','mask').  We might
be able to use Socket to build the raw materials and bless a new NetAddr::IP
object without going through it's validation.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Robert Drake

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(Compact Coalesce Zero Zeros Ones V4mask V4net netlimit);

=head1 METHODS

=head2 new

This replaces the NetAddr::IP->new method with a stub that stores the
arguments supplied in a temporary variable and returns immediately.  No
validation is performed.

Once you call a method that can't be handled by LazyInit, a full NetAddr::IP
object is built and the request passed into that object.

   my $ip = NetAddr::IP::LazyInit->new("127.0.0.1");

=cut

sub new { my $class = shift; bless {x=>[@_]}, $class }

=head2 addr

Returns the IP address of the object.  If we can extract the IP as a string
without converting to a real NetAddr::IP object, then we return that.
Currently it only returns IPv6 strings in lower case, which may break your
application if you aren't using the new standard.

    my $ip = NetAddr::IP::LazyInit->new("127.0.0.1");
    print $ip->addr;

=cut

sub addr {
    my $self = shift;
    if ($self->{x}->[0] =~ /^(.*?)(?:\/|$)/) {
        return lc($1);
    } else {
        return $self->inflate->addr;
    }
}

=head2 mask

Returns the subnet mask of the object.  If the user used the two argument
option then it returns the string they provided for the second argument.
Otherwise this will inflate to build a real NetAddr::IP object and return the
mask.

    my $ip = NetAddr::IP::LazyInit->new("127.0.0.1", "255.255.255.0");
    print $ip->mask;

=cut

sub mask {
    my $self = shift;
    if ($self->{x}->[1] && $self->{x}->[1] =~ /\D/) {
        return $self->{x}->[1];
    } else {
        return $self->inflate->mask;
    }
}

# everything below here aren't ment for speed or for users to reference.
# They're purely for compatibility with NetAddr::IP so that users can use this
# module like the real one.

sub can { NetAddr::IP->can($_[1]); }

sub Compact {
    for (@_) {
        $_->inflate if (ref($_) eq 'NetAddr::IP::LazyInit');
    }
    return NetAddr::IP::Compact(@_);
}



sub Coalesce {
    for (@_) {
        $_->inflate if (ref($_) eq 'NetAddr::IP::LazyInit');
    }
    return NetAddr::IP::Coalesce(@_);
}

sub import {
    if (grep { $_ eq ':rfc3021' } @_)
    {
        $NetAddr::IP::rfc3021 = 1;
        @_ = grep { $_ ne ':rfc3021' } @_;
    }
    if (grep { $_ eq ':old_storable' } @_) {
        @_ = grep { $_ ne ':old_storable' } @_;
    }
    if (grep { $_ eq ':old_nth' } @_)
    {
        $NetAddr::IP::Lite::Old_nth = 1;
        @_ = grep { $_ ne ':old_nth' } @_;
    }
    if (grep { $_ eq ':lower' } @_)
    {
        NetAddr::IP::Util::lower();
        @_ = grep { $_ ne ':lower' } @_;
    }
    if (grep { $_ eq ':upper' } @_)
    {
        NetAddr::IP::Util::upper();
        @_ = grep { $_ ne ':upper' } @_;
    }

  NetAddr::IP::LazyInit->export_to_level(1, @_);
}

# need to support everything that NetAddr::IP does
use overload (
    '@{}'   => sub { return [ $_[0]->inflate->hostenum ]; },
    '""'    => sub { return $_[0]->inflate->cidr() },
    '<=>'   => sub { inflate_args_and_run(\&NetAddr::IP::Lite::comp_addr_mask, @_); },
    'cmp'   => sub { inflate_args_and_run(\&NetAddr::IP::Lite::comp_addr_mask, @_); },
    '++'    => sub { inflate_args_and_run(\&NetAddr::IP::Lite::plusplus, @_); },
    '+'     => sub { inflate_args_and_run(\&NetAddr::IP::Lite::plus, @_); },
    '--'    => sub { inflate_args_and_run(\&NetAddr::IP::Lite::minusminus, @_); },
    '-'     => sub { inflate_args_and_run(\&NetAddr::IP::Lite::minus, @_); },
    '='     => sub { inflate_args_and_run(\&NetAddr::IP::Lite::copy, @_); },
    '=='    => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) =~ /NetAddr::IP::LazyInit/;
        my $b = $_[1];
        $b->inflate if ref($_[1]) =~ /NetAddr::IP::LazyInit/;
        return ($a eq $b);
    },
    '!='    => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) eq 'NetAddr::IP::LazyInit';
        my $b = $_[1];
        $b->inflate if ref($_[1]) eq 'NetAddr::IP::LazyInit';
        return ($a ne $b);
    },
    'ne'    => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) eq 'NetAddr::IP::LazyInit';
        my $b = $_[1];
        $b->inflate if ref($_[1]) eq 'NetAddr::IP::LazyInit';
        return ($a ne $b);
    },
    'eq'    => sub {
        my $a = $_[0];
        $a->inflate if ref($_[0]) eq 'NetAddr::IP::LazyInit';
        my $b = $_[1];
        $b->inflate if ref($_[1]) eq 'NetAddr::IP::LazyInit';
        return ($a eq $b);
    },
    '>'     => sub { return &comp_addr_mask > 0 ? 1 : 0; },
    '<'     => sub { return &comp_addr_mask < 0 ? 1 : 0; },
    '>='    => sub { return &comp_addr_mask < 0 ? 0 : 1; },
    '<='    => sub { return &comp_addr_mask > 0 ? 0 : 1; },

);

sub comp_addr_mask {
    return inflate_args_and_run(\&NetAddr::IP::Lite::comp_addr_mask, @_);
}

sub inflate_args_and_run {
    my $func = shift;
    $_[0]->inflate if ref($_[0]) eq 'NetAddr::IP::LazyInit';
    $_[1]->inflate if ref($_[1]) eq 'NetAddr::IP::LazyInit';
    return &{$func}(@_);
}

sub AUTOLOAD {
  my $self = shift;
  my $obj = NetAddr::IP->new(@{ $self->{x} });
  %$self = %$obj;
  bless $self, 'NetAddr::IP';
  our $AUTOLOAD =~ /::(\w+)$/;
  return $self->$1(@_);
}

sub inflate {
    my $self = shift;
    my $method = shift;
    my $obj = NetAddr::IP->new(@{ $self->{x} });
    %$self = %$obj;
    bless $self, 'NetAddr::IP';
    return $method ? $self->method( @_ ) : $self;
}

1;
