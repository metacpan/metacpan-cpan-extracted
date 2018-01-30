package OpenERP::OOM::Class;


use 5.010;
use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => ['object_type'],
    also      => 'Moose',
);

sub init_meta {
    shift;
    return Moose->init_meta( @_, base_class => 'OpenERP::OOM::Class::Base' );
}

sub object_type {
    my ($meta, $name, %options) = @_;
    
    $meta->add_attribute(
        'object',
        isa     => 'Str',
        is      => 'ro',
        default => sub {$name},
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::Class

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    package Package::OpenERP::Class::Account;

    use 5.010;
    use OpenERP::OOM::Class;

    object_type 'Package::OpenERP::Object::Account';

    around 'create' => sub {
        my ($orig, $self, $object) = @_;
        
        # Make sure active is set to 1
        $object->{active} = 1;
        
        # Create the object
        return $self->$orig($object);
    };

    sub account_by_code
    {
        my $self = shift;
        my $code = shift;
        return $self->find([ 'code', '=', $code ]);
    }

    1;

=head1 DESCRIPTION

Use this module to create the 'classes' for your modules.  It also implicitly loads
Moose too.  In addition to the Moose bindings it also ties up the class with a 
corresponding class for your individual objects using the object_type property.  

=head1 NAME

OpenERP::OOM::Class

=head1 METHODS

=head2 init_meta

This is in internal method that hooks up your class to inherit the class C<OpenERP::OOM::Class::Base>.

See the C<OpenERP::OOM::Class::Base> class for the methods your objects that use 
this class will automatically have available.

=head2 object_type

This links the class to the object class.  When you create a new object using create
or you are returned objects after doing a find or search they will be of the type 
specified.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 OpusVL

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
