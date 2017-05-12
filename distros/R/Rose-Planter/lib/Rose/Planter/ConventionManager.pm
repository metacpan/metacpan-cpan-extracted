package Rose::Planter::ConventionManager;

=head1 NAME

Rose::Planter::ConventionManager - some handy convention defaults

=head1 DESCRIPTION

This is a subclass of Rose::DB::Object::ConventionManager with
a few tweaks.

=head1 METHODS

=cut

use base 'Rose::DB::Object::ConventionManager';

use strict;

=head2 auto_relationship_name_one_to_many

By default if "foo_params" is a child of a table "foo",
we remove the the "foo_" portion from "foo_params".

i.e.  If this table has only _one_ foreign key and the table name
referred to in the foreign key is a prefix of this table name plus
an underscore, then remove the table name and the underscore.  Got it?

=cut

sub auto_relationship_name_one_to_many {
    my $self = shift;
    my ($table,$class) = @_;
    my $name = $self->SUPER::auto_relationship_name_one_to_many(@_);

    my @fks = $class->meta->foreign_keys;
    return $name unless @fks==1;

    my $target = $fks[0]->class->meta->table;

    $name =~ s/^$target\_//;

    return $name;
}

1;

