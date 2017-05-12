package Pod::Abstract::Filter;
use strict;
use warnings;

use Pod::Abstract;

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter - Generic Pod-in to Pod-out filter.

=head1 DESCRIPTION

This is a superclass for filter modules using
Pod::Abstract. Subclasses should override the C<filter>
sub. Pod::Abstract::Filter classes in the Pod::Abstract::Filter
namespace will be used by the C<paf> utility.

To create a filter, you need to implement:

=over

=item filter

Takes a Pod::Abstract::Node tree, and returns either another tree, or
a string. If a string is returned, it will be re-parsed to be input to
any following filter, or output directly if it is the last filter in
the list.

It is recommended your filter method produce a Node tree if you are able
to, as this will improve interoperability with other C<Pod::Abstract>
based software.

=item require_params

If you want positional arguments following your filter in the style of:

 paf find [thing] Pod::Abstract

then override require_params to list the named arguments that are to
be accepted after the filter name.

=back

=head1 METHODS

=head2 new

Create a new filter with the specified arguments.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    return bless { %args }, $class;
}

=head2 require_params

Override to return a list of parameters that must be provided. This
will be accepted in order on the command line, unless they are first
set using the C<-flag=xxx> notation.

=cut

sub require_params {
    return ( );
}

=head2 param

Get the named param. Read only.

=cut

sub param {
    my $self = shift;
    my $param_name = shift;
    return $self->{$param_name};
}

=head2 filter

Stub method. Does nothing, just returns the original tree.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    return $pa;
}

=head2 run

Run the filter. If $arg is a string, it will be parsed
first. Otherwise, the Abstract tree will be used. Returns either a
string or an abstract tree (which may be the original tree, modified).

=cut

sub run {
    my $self = shift;
    my $arg = shift;
    
    if( eval { $arg->isa( 'Pod::Abstract::Node' ) } ) {
        return $self->filter($arg);
    } else {
        my $pa = Pod::Abstract->load_string($arg);
        return $self->filter($pa);
    }
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
