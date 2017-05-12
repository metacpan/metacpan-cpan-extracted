package TM::Index::Characteristics;

use strict;
use warnings;
use Data::Dumper;

use TM;
use base qw(TM::Index);

=pod

=head1 NAME

TM::Index::Characteristics - Topic Maps, Indexing support (match layer)

=head1 SYNOPSIS

    # somehow get a map (any subclass of TM will do)
    my $tm = ... 

    # one option: create a lazy index which learns as you go
    use TM::Index::Characteristics;
    my $idx = new TM::Index::Characteristics ($tm);
    
    # for most operations which involve match_forall to be called
    # for querying characteristics should be much faster

=head1 DESCRIPTION

This index can be attached to a map if querying it for characteristics (here names and occurrences)
is intensive.

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
	next if $a->[TM->KIND] == TM->ASSOC;                                     # these are not interesting here
	my $mid = $a->[TM->PLAYERS]->[0];                                        # the thing is ALWAYS here
	push @{ $cache->{"char.topic:1.$mid"} }, $a->[TM->LID];
    }
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Index>

=head1 COPYRIGHT AND LICENSE

Copyright 200[6] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.1;
our $REVISION = '$Id: Characteristics.pm,v 1.1 2006/12/01 08:01:00 rho Exp $';

1;

__END__
