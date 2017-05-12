package MouseX::YAML;

use 5.008_001;
use Mouse::Util; # turns on strict and warnings
use Mouse::Exporter;

our $VERSION = '0.001';

Mouse::Exporter->setup_import_methods(
    as_is  => [qw(Load LoadFile)],
    groups => {
        default => [],
    },
);

sub _is_object_with_meta;
Mouse::Util::generate_can_predicate_for(['meta'], '_is_object_with_meta');

our @Modules;

if(!@Modules){
    @Modules = qw(
        YAML::XS
        YAML::Syck
        YAML
    );
}

my $YAML = Mouse::Util::load_first_existing_class(@Modules);
sub backend(){ $YAML }

{
    package # hide from PAUSE
        MouseX::YAML::Backend;

    $YAML->import(qw(Load LoadFile));
}

sub Load {
    __PACKAGE__->load(@_);
}
sub LoadFile {
    __PACKAGE__->load_file(@_);
}

sub load {
    my($class, $yaml) = @_;

    return $class->_fixup(MouseX::YAML::Backend::Load($yaml));
}

sub load_file {
    my($class, $file) = @_;
    return $class->_fixup(MouseX::YAML::Backend::LoadFile($file));
}

sub _fixup {
    my($class, $proto) = @_;

    my $args = { %{$proto} };

    %{$proto} = ();

    foreach my $value(values %{$args}){
        if(_is_object_with_meta($value)){
            $class->_fixup($value);
        }
    }

    $proto->meta->_initialize_object($proto, $args);
    $proto->BUILDALL($args);
    return $proto;
}

1;
__END__

=head1 NAME

MouseX::YAML - DWIM loading of Mouse objects from YAML

=head1 VERSION

This document describes MouseX::YAML version 0.001.

=head1 SYNOPSIS

    # given some class:
    package My::Module;
    use Mouse;

    has package => (
        is => "ro",
        init_arg => "name",
    );

    has version => (
        is  => "rw",
        init_arg => undef,
    );

    sub BUILD { shift->version(3) }

    # load an object like so:
    use MouseX::YAML qw(Load);

    my $obj = Load(<<'    YAML');
    --- !!perl/hash:My::Module
    name: "MouseX::YAML"
    YAML

    print $obj->package; # MouseX::YAML
    print $obj->version; # 3

=head1 DESCRIPTION

This module provides DWIM loading of Mouse based objects from YAML
documents.

Any hashes blessed into a Mouse class will be replaced with a properly
constructed instance (respecting C<init_arg> and C<BUILD>).

=head1 INTERFACE

=head2 Exportable functions

=head3 Load($yaml)

=head3 LoadFile($file)

=head2 Class methods

=head3 MouseX::YAML->backend()

=head3 MouseX::YAML->load($yaml)

=head3 MouseX::YAML->load_file($file)

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 SEE ALSO

L<Mouse>

L<MooseX::YAML>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
