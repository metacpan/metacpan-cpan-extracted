package TM::Index::Taxonomy;

use strict;
use warnings;
use Data::Dumper;

use TM;
use base qw(TM::Index);

=pod

=head1 NAME

TM::Index::Taxonomy - Topic Maps, Indexing support (match layer)

=head1 SYNOPSIS

    # somehow get a map (any subclass of TM will do)
    my $tm = ... 

    # one option: create a lazy index which learns as you go
    use TM::Index::Taxonomy;
    my $idx = new TM::Index::Taxonomy ($tm)->populate;
    
    # for most operations which involve taxonometric functions to be called
    # that should be much faster

=head1 DESCRIPTION

This index can be attached to a map if querying it for subclass/superclass and/or
instances/classes is intensive.

The package inherits most of its functionality from L<TM::Index>.

=head1 INTERFACE

=head2 Constructor

The constructor/destructor is inherited from L<TM::Index>.

=head2 Methods

=over

=cut

sub populate {
    my $self  = shift;
    my $map   = $self->{map};
    my $cache = $self->{cache};

    foreach my $a (values %{ $map->{assertions} }) {
	next unless $a->[TM->KIND] == TM->ASSOC;                                     # these are not interesting here
	if      ($a->[TM->TYPE] eq 'isa') {
	    my ($class, $instance) = @{ $a->[TM->PLAYERS] };
	    push @{ $cache->{"class.type:$class.isa"} },                      $a->[TM->LID];
	    push @{ $cache->{"instance.type:$instance.isa"} },                $a->[TM->LID];

	} elsif ($a->[TM->TYPE] eq 'is-subclass-of') {
	    my ($subclass, $superclass) = @{ $a->[TM->PLAYERS] };
	    push @{ $cache->{"superclass.type:$superclass.is-subclass-of"} }, $a->[TM->LID];
	    push @{ $cache->{"subclass.type:$subclass.is-subclass-of"} },     $a->[TM->LID];

	} else {
	    # ignore everything else
	}
    }
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Index>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.1;

1;

__END__
