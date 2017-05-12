1;
package OpenERP::OOM::Tutorial::Schema;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::Tutorial::Schema

=head1 VERSION

version 0.44

=head1 DESCRIPTION

=head2 Object model

OpenERP::OOM uses an object model consisting of a Schema, Classes, and Objects.
These are organised as shown below, with methods to traverse up and down the tree.

    +-------------------------------+
    |            Schema             |
    |          e.g. MyApp           |
    +-------------------------------+
         /|\                |
          |               class
       schema               |
          |                \|/
    +-------------------------------+
    |             Class             |
    |  e.g. MyApp::Class::Partner   |
    +-------------------------------+
         /|\                |
          |              search
        class           retrieve
          |              create
          |                 |
          |                \|/ 
    +-------------------------------+
    |             Object            |
    |  e.g. MyApp::Object::Partner  |
    +-------------------------------+
                    |
                 update
                 delete
                    |
                   \|/
    +-------------------------------+
    |          OpenERP model        |
    |         e.g res.partner       |
    +-------------------------------+

=head2 Schema

The schema class extends the OpenERP::OOM::Schema module, i.e.:

    package MyApp;
    
    use Moose;
    extends 'OpenERP::OOM::Schema';
    
    1;

To create a new instance of your schema, pass the OpenERP connection details in
the call to C<new()>.

    use MyApp;
    
    my $schema = MyApp->new(
        openerp_connect => {
            host     => 'localhost',
            dbname   => 'openerp_db',
            username => 'admin',
            password => 'admin',
        }
    );

=head2 Classes

A typical class definition is as follows:

    package MyApp::Class::Partner;
    use OpenERP::OOM::Class;
    
    object_type 'MyApp::Object::Company';
    
    1;

From your schema, you can then access classes.

    my $class = $schema->class('Partner');

The class provides methods to search, retrieve, and create objects.

=head2 Objects

    package MyApp::Object::Partner;
    use OpenERP::OOM::Object;
    
    openerp_model 'res.partner';
    
    has 'name' => (isa=>'Str', is=>'rw');
    
    1;

Objects are created and retrieved from the class:

    my $partner = $schema->class('Partner')->create({
        name => 'My Partner',
    });

    foreach my $partner ($schema->class->('Partner')->search) {
        say $partner->name;
    }

__END__

=head1 NAME

OpenERP::OOM::Tutorial::Schema - Setting up an OpenERP::OOM Schema

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
