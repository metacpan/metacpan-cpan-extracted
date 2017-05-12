package Template::Plugin::ArrayRef;
use base 'Template::Plugin';
use strict;
use warnings;
use Template::Exception;
use Scalar::Util qw();

our $VERSION   = 0.11;
our $MONAD     = 'Template::Monad::ArrayRef';
our $EXCEPTION = 'Template::Exception';
our $AUTOLOAD;

sub load {
    my $class   = shift;
    my $context = shift;

    # define .arrayref vmethods for hash and list objects
    $context->define_vmethod( hash => arrayref => \&arrayref_monad );
    $context->define_vmethod( list => arrayref => \&arrayref_monad );

    return $class;
}

sub arrayref_monad {
    # create a .arrayref monad which wraps the hash- or list-based object
    # and delegates any method calls back to it, calling them in scalar 
    # context, e.g. foo.arrayref.bar becomes $MONAD->new($foo)->bar and 
    # the monad calls $foo->bar in array context
    $MONAD->new(shift);
}

sub new {
    my ($class, $context, @args) = @_;
    # create a scalar plugin object which will lookup a variable subroutine
    # and call it.  e.g. arrayref.foo results in a call to foo() in array context
    my $self = bless {
        _CONTEXT => $context,
    }, $class;
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';
    
    # lookup the named values
    my $stash = $self->{ _CONTEXT }->stash;
    my $value = $stash->{ $item };

    if (! defined $value) {
        die $EXCEPTION->new( arrayref => "undefined value for arrayref call: $item" );
    }
    elsif (ref $value eq 'CODE') {
        $value = [ $value->(@_) ];
    }
    return $value;
}


package Template::Monad::ArrayRef;

our $EXCEPTION = 'Template::Exception';
our $AUTOLOAD;

sub new {
    my ($class, $this) = @_;
    bless \$this, $class;
}

sub AUTOLOAD {
    my $self = shift;
    my $this = $$self;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';

    my $method;
    if (Scalar::Util::blessed($this)) {
        # lookup the method...
        $method = $this->can($item);
    }
    else {
        die $EXCEPTION->new( arrayref => "invalid object method: $item" );
    }

    # ...and call it in array context
    my @results = $method->($this, @_);
    return \@results;
}

1;

__END__

=head1 NAME

Template::Plugin::ArrayRef - call object methods in array context and return it as arrayref

=head1 SYNOPSIS

    [% USE ArrayRef %]
    [% USE Dumper %]

    [% PERL %]
        $stash->set( get_zero  => sub { ()     } );
        $stash->set( get_one   => sub { (1)    } );
        $stash->set( get_two   => sub { (1, 2) } );
    [% END %]

    [% SET zero = get_zero %]
    [% SET one  = get_one %]
    [% SET two  = get_two %]
    [% Dumper.dump(zero) %] # $VAR1 = '';
    [% Dumper.dump(one) %]  # $VAR1 = 1;
    [% Dumper.dump(two) %]  # $VAR1 = [ 1, 2 ];

    [% SET zero = get_zero.list %]
    [% SET one  = get_one.list %]
    [% SET two  = get_two.list %]
    [% Dumper.dump(zero) %] # $VAR1 = '';
    [% Dumper.dump(one) %]  # $VAR1 = [ 1 ];
    [% Dumper.dump(two) %]  # $VAR1 = [ 1, 2 ];

    [% SET zero = ArrayRef.get_zero %]
    [% SET one  = ArrayRef.get_one %]
    [% SET two  = ArrayRef.get_two %]
    [% Dumper.dump(zero) %] # $VAR1 = [];
    [% Dumper.dump(one) %]  # $VAR1 = [ 1 ];
    [% Dumper.dump(two) %]  # $VAR1 = [ 1, 2 ];

    [% USE arrayref = ArrayRef %]
    [% SET zero = arrayref.get_zero %]
    [% SET one  = arrayref.get_one %]
    [% SET two  = arrayref.get_two %]
    [% Dumper.dump(zero) %] # $VAR1 = [];
    [% Dumper.dump(one) %]  # $VAR1 = [ 1 ];
    [% Dumper.dump(two) %]  # $VAR1 = [ 1, 2 ];

    # in DBIC cases...
    [% SET items = row.arrayref.items %]
    [% SET items = row.items_rs.arrayref.all %]

=head1 AUTHOR

Tomohiro Hosaka E<lt>bokutin@bokut.inE<gt>

=head1 COPYRIGHT

Copyright (C) 2011 Tomohiro Hosaka.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Scalar>

=cut
