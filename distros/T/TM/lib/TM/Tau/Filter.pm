package TM::Tau::Filter;

use TM;
use base qw(TM);
use Class::Trait (TM::Synchronizable => { exclude => [ 'mtime', 'sync_out' ] });

use Data::Dumper;

=pod

=head1 NAME

TM::Tau::Filter - Topic Maps, abstract filter class

=head1 SYNOPSIS

   my $tm     = ... some map (or another filter)
   my $filter = new TM::Tau::Filter (left => $tm);

   $filter->sync_in; # this will pass on the sync in to the left operand

   # after that, the filter itself holds the result (which is a map)
   $filter->instances (....);

=head1 DESCRIPTION

Filters are special maps in that their content depends on another map and a particular
transformation to get the map result. If you consider the expression

   some_map.atm * some_transformation

then C<some_transformation> is applied to the map coming from the map C<some_map.atm>.
This scheme can be expanded to the left:

   some_map.atm * some_transformation1 * some_transformation2

so that a whole chain of transformations can be applied to a map. The expression has to be
interpreted left-associative, so as if written as

   (some_map.atm * some_transformation1) * some_transformation2

When you build a filter expression, then you have to respect this left-associativeness:

   my $map    = new TM....;
   my $trafo1 = new TM::Tau::Filter (left => $map);
   my $trafo2 = new TM::Tau::Filter (left => $trafo1);

The variable C<$trafo2> then holds this expression, but nothing is actually computed at this
stage. To trigger this process, the method C<sync_in> can be used (read: apply). It will trigger the
in-synchronisation of C<$trafo1> and that will pass it on to the C<$map>. That will do something (or
not) to ensure that the map is up-to-date relative to the resource it is possibly associated with.
Once this is done, the filter C<$trafo1> will do its work. Once the result is available, C<$trafo2>
will do its work.

=head2 Transformations

Filters are not constrained in what they are doing. Some filters might only extract a particular
portion out of a map. Others will make more complex conversions, say, to adapt to a different
background ontology. Others will completely change the map, or compute new stuff from it. It is also
possible to have transformers which actually do nothing, except than mediating between different
formats a map is written in.

To specify B<what> the transformation is supposed to do, you can either overload the method
C<sync_in>, or alternatively keep it and overload only C<transform>:

   sub transform {
       my $self = shift;       # this is the filter
       my $map  = shift;       # this is the left operand map

       ....                    # do whatever you need to do
       $result = .....         # this might be your result
       return $result;         # return it
   }

Your result will be used as content for the filter (which is a map itself, remember). See
L<TM::Tau::Filter::Analyze> for an example.

The default transformation is the empty one, i.e. the map is simply passed through (not copied,
btw).

=head1 INTERFACE

=head2 Constructor

The constructor of implementations should expect a hash as parameter with the following fields:

=over

=item I<left> (no default):

This must be an object of class L<TM>. i.e. it can also be another filter.

=item I<url> (default C<null:>)

If the URL is missing here (filters are resourced maps), then it defaults to C<null:>

=back

=cut

sub new {
    my $class   = shift;
    my %options = @_;

    $options{url} ||= 'null:'; # a filter may have nothing to which it is attached outgoingly
    if ($options{left}) {
	ref ($options{left}) and $options{left}->isa ('TM')
	    or $TM::log->logdie ( scalar __PACKAGE__ .": left operand must be an instance of TM" );
    }

    $options{sync_in}  ||= 0;                                                          # defaults
    $options{sync_out} ||= 0;
    my $self = bless $class->SUPER::new (%options), $class;
    
    $self->sync_in if $self->{sync_in};                                                 # if user wants to sync at constructor time, lets do it
    return $self;
}

# the DESTROY of the underlying map is done automatically, and that should try a sync_out (if materialized)
# in case the user does not want a synchronisation, I have to avoid it by overriding _sync_in (or even sync_in)
sub DESTROY {
    my $self = shift;
#warn "tau DESTROY"; #. Dumper $self;
    return if $@; # we do not do anything in case of errors/exceptions
#warn "{sync_out} is ".$self->{sync_out};
#warn "and we can? ".$self->can ('source_out');
#warn "and where to? ".$self->url;
    $self->sync_out if $self->{sync_out} && $self->can ('source_out');
}

=pod

=head2 Methods

=over

=item B<left>

I<$tm> = I<$filter>->left
I<$filter>->left (I<$tm>)

This is an accessor (read and write) to get the left operand. In any case the left component is
returned.

=cut

sub left {
    my $self = shift;
    my $left = shift;
    return $left ? $self->{left} = $left : $self->{left};
}

=pod

=item B<mtime>

I<$filter>->mtime

This retrieves the last modification time of the resource on which this filter operates on.

=cut

sub mtime {
    my $self = shift;
#warn "filter mtime with $self->{left}";
    return $self->{left}->mtime;
}

=pod

=item B<transform>

I<$tm2> = I<$filter>->transform (I<$tm>)

This method performs the actual transformation. If you develop your own filter, then this has to be
overloaded. The default implementation here only hands back the same map (I<identity> transformation).

=cut

sub transform {
    return $_[1];
}

sub source_in {
#warn "filtrer source in";
    my $self = shift;

#warn __PACKAGE__ . " source in ". $self->url;
#warn __PACKAGE__ . " baseuri ". $self->baseuri;
    $self->{left}->source_in;                             # lets get the upstream crap, uhm map
#warn "left before  melt".Dumper $self->{left};

#    my $m = $self->{left}->insane;

    $self->melt ( $self->transform ($self->{left}, $self->baseuri) );        
#warn __PACKAGE__ . " baseuri after melt". $self->baseuri;
#warn "whole thing after melt".Dumper $self;
}

sub sync_out {
    my $self = shift;
    {                                                     # temporarily delete left component, source_out should never see that
	my $left = delete $self->{left};
#warn "filter sync out ".$self->{left};
	$self->source_out; # do not think twice
	$self->{left} = $left;
    }
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Tau>, L<TM::Tau::Filter::Analyze>

=head1 AUTHOR INFORMATION

Copyright 200[4-6], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.4;
our $REVISION = '$Id: Filter.pm,v 1.13 2006/12/13 10:46:59 rho Exp $';

1;

__END__



