package MongoDBx::Tiny::Relation;
use strict;
use warnings; 

=head1 NAME

MongoDBx::Tiny::Relation - define relation

=cut

use Carp qw(carp confess);
our @ISA    = qw/Exporter/;
our @EXPORT = qw/RELATION_DEFAULT/;

{
    no warnings qw(once);
    *RELATION_DEFAULT = \&RELATION_BY;
}

=head1 EXPORT

=head2 RELATION_BY

  RELATION 'related_collection', RELATION_BY('method','related_field','field');
  RELATION 'bar', RELATION_BY('single','foo_id','id');

=cut

sub RELATION_BY {
    my ($meth,$field_name,$val_name) = @_;
    confess "RELATION_BY: invalid args"  if scalar @_ != 3; 

    return sub {
	my $self   = shift;
	my $c_name = shift; # relation
	my $tiny = $self->tiny;
	$tiny->$meth($c_name,{ $field_name => $self->$val_name() });
    }
}


1;
__END__

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
