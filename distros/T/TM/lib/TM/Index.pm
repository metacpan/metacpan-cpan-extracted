package TM::Index;

use Data::Dumper;

=pod

=head1 NAME

TM::Index - Topic Maps, generic indexing support

=head2 SYNOPSIS

   # this package only provides generic functionality
   # see TM::Index::* for specific indices

=head1 DESCRIPTION

One performance bottleneck when using the L<TM> package or any of its subclasses are the low-level
query functions C<match_forall> and C<match_exists>. They are looking for assertions of a certain
nature. Almost all high-level functions, and certainly L<TM::TS> (TempleScript) use these.

This package (actually more its subclasses) provides an indexing mechanism to speed up the
C<match_*> functions by caching some results in a very specific way. When an index is attached to a
map, then it will intercept all queries going to these functions.

=head2 Open vs. Closed Index

There are two options:

=over

=item C<open>:

The default is to keep the index I<lazy>. In this mode the index is empty at the start and it will
learn more and more on its own. In this sense, the index lives under an I<open world assumption>
(hence the name), as the absence of information does not mean that there is no result.

=item C<closed>:

A I<closed world> index has to be populated to be useful. If a query is launched and the result is
stored in the index, then it will be used, like for an open index. If no result in the index is
found for a query, the empty result will be assumed.

=back

=head2 Map Attachment

To activate an index, you have to attach it to a map. This is done at constructor time.

It is possible (not sure how useful it is) to have one particular index to be attached to several
different maps. It is also possible to have several L<TM::Index::*> indices attached to one
map. They are then consulted in the sequence of attachments:

    my $idx1 = new TM::Index::Whatever  ($tm);
    my $idx2 = new TM::Index::Whatever2 ($tm);

If C<$idx1> cannot help, then C<$idx2> is tried.

B<NOTE>: If you use I<several> indices for the I<same> map, then all of them B<MUST> be declared as
being I<open>. If one of them were closed, it would give a definite answer and would make the
machinery not look further into other indices. This implies that you will have to populate your index
explicitly.

=head2 Hash Technology

The default implementation uses an in-memory hash, no further fancy. Optionally, you can provide
your own hash object, also one which is I<tied> to an DBM file, etc.

=head1 INTERFACE

=head2 Constructor

The only mandatory parameter for the constructor is the map for which this index should apply. The
map must be an instance of L<TM> or any of its subclasses, otherwise an exception is the
consequence.

Optional parameters are

=over

=item C<closed> (default: C<0>)

This controls whether the index is operating under closed or open world assumptions. If it is
specified to be I<closed> the method C<populate> will be triggered at the end of the constructor.

=item C<cache> (default: C<{}>)

You optionally can pass in your own HASH reference.

=back

Example:

   my $idx = new TM::Index::Match ($tm)

B<NOTE>: When the index object goes out of scope, the destructor will make the index detach itself
from the map. Unfortunately, the exact moment when this happens is somehow undefined in Perl, so it
is better to do this manually at the end.

Example:

   {
    my $idx2 = new TM::Index::Match ($tm, closed => 1);
    ....
    } # destructor called and index detaches automatically, but only in theory

   {
    my $idx2 = new TM::Index::Match ($tm, closed => 1);
    ....
    $idx2->detach; # better do things yourself
    }

=cut

sub new {
    my $class = shift;
    my $tm    = shift;
    $TM::log->logdie (scalar __PACKAGE__.": first parameter must be an instance of TM") unless ref ($tm) && $tm->isa ('TM');

    my %options = @_;
    $options{closed} //= 0;                          # we assume that this is 'open' and not 'closed'
    $options{cache}  //= {};
    $options{loose}  //= 0;                          # unless specified otherwise, we will couple tightly with the map (cyclic reference!)

    my $self = bless \ %options, $class;             # create the object
    $self->{map} = $tm unless $self->{loose};        # here we avoid to create a cyclic dependency (bites with MLDBM backed TMs)

    $self->attach ($tm);
#warn Dumper $self;
    $self->populate ($tm) if $self->{closed};
    return $self;
}

# has to be done, if reattachment is the plan

sub DESTROY {
    shift->detach;
}

=pod

=head2 Methods

=over

=item B<attach>

I<$idx>->attach

This method attaches the index to the configured map. Normally you will not call this as the
attachment is implicitly done at constructor time. The index itself is not destroyed; it is just
deactivated to be used together with the map.

@@ optional TM

=cut

sub attach {
    my $self = shift;
    my $tm   = shift || $self->{map};
    push @{ $tm->{indices} }, $self;      # append to the list
}

=pod

=item B<detach>

I<$idx>->detach

Makes the index detach safely from the map. The map is not harmed in this process.

=cut

sub detach {
    my $self = shift;
    my $tm   = shift || $self->{map};
    $tm->{indices} = _del ($tm->{indices}, $self);
    $tm->{indices} = undef if (  $tm
			   &&    $tm->{indices} 
                           && @{ $tm->{indices} } == 0); # make it undef, allows for a faster test
    $self->{map}            = undef;

sub _del {         # gets rid of a particular entry in a list
    my $s = shift; # the list
    my $i = shift; # the entry

    my $t = [];
    while (my $j = shift @$s) {
        push @$t, $j == $i ? () : $j;
    }
    return $t;
}

}

=pod

=item B<discard>

I<$idx>->discard

This throws away the index content.

=cut

sub discard {
    my $self = shift;
    $self->{cache} = {};
}

=pod

=item B<is_cached>

I<$bool> = I<$idx>->is_cached (I<$key>)

Given a key parameter, the cache is consulted whether it already has a result for this key. If the
index is I<closed> it will return the empty list (reference), if it has no result, otherwise it will
give back C<undef>.

=cut

sub is_cached {
    my $self = shift;
    my $key  = shift;
    $self->{reads}->{$key}++;
    return $self->{closed} ? $self->{cache}->{$key} || []  # we this is to be understood 'closed', then "Not stored" means "not true", i.e. empty result
                           : $self->{cache}->{$key};       # in an open interpretation, we never know
}

=pod

=item B<do_cache>

I<$idx>->do_cache (I<$key>, I<$list_ref>)

Given a key and a list reference, it will store the list reference there in the cache.

=cut

sub do_cache {
    my $self = shift;
    my $key  = shift;
    my $data = shift;
    return $self->{cache}->{$key} = $data;
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Index::Characteristics>, L<TM::Index::Match>

=head1 COPYRIGHT AND LICENSE

Copyright 20(0[6]|10) by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.5;

1;

__END__

