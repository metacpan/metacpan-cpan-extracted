package MooseX::Privacy::Meta::Attribute::Privacy;
BEGIN {
  $MooseX::Privacy::Meta::Attribute::Privacy::VERSION = '0.05';
}

use MooseX::Role::Parameterized;

parameter level => (isa => 'Str', is => 'ro', required => 1,);

role {
    my $p = shift;

    my $check_method    = '_check_' . $p->level;
    my $push_method     = '_push_' . $p->level . '_attribute';
    my $local_attribute = 'local_' . $p->level . '_attributes';

    method _generate_accessor_method => sub {
        my $meta         = shift;
        my $attr         = $meta->associated_attribute;
        my $package_name = $attr->associated_class->name;

        my $class = $package_name->meta;
        if ($class->meta->has_attribute($local_attribute)) {
            $class->$push_method($attr->name);
        }

        return sub {
            my $self   = shift;
            my $caller = (scalar caller());
            my $name   = $self->meta->name;
            $meta->$check_method($caller, $attr->name, $package_name, $name);
            $attr->set_value($self, $_[0]) if scalar(@_) == 1;
            $attr->get_value($self);
        };
    };

    method _generate_reader_method => sub {
        my $meta         = shift;
        my $attr         = $meta->associated_attribute;
        my $package_name = $attr->associated_class->name;

        return sub {
            my $self   = shift;
            my $caller = (scalar caller());
            my $name   = $self->meta->name;
            $meta->$check_method($caller, $attr->name, $package_name, $name);
            confess "Cannot assign a value to a read-only accessor" if @_ > 1;
            $attr->get_value($self);
        };
    };

    method _generate_writer_method => sub {
        my $meta         = shift;
        my $attr         = $meta->associated_attribute;
        my $package_name = $attr->associated_class->name;

        return sub {
            my $self   = shift;
            my $caller = (scalar caller());
            my $name   = $self->meta->name;
            $meta->$check_method($caller, $attr->name, $package_name, $name);
            $attr->set_value($self, $_[1]);
        };
    };

    method _generate_predicate_method => sub {
        my $meta         = shift;
        my $attr         = $meta->associated_attribute;
        my $package_name = $attr->associated_class->name;

        return sub {
            my $self   = shift;
            my $caller = (scalar caller());
            my $name   = $self->meta->name;
            $meta->$check_method($caller, $attr->name, $package_name, $name);
            $attr->has_value($self);
        };
    };

    method _generate_clearer_method => sub {
        my $meta         = shift;
        my $attr         = $meta->associated_attribute;
        my $package_name = $attr->associated_class->name;

        return sub {
            my $self   = shift;
            my $caller = (scalar caller());
            my $name   = $self->meta->name;
            $meta->$check_method($caller, $attr->name, $package_name, $name);
            $attr->clear_value($self);
        };
    };
};

1;

__END__
=pod

=head1 NAME

MooseX::Privacy::Meta::Attribute::Privacy

=head1 VERSION

version 0.05

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

