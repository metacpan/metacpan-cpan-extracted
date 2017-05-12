use strict;
use warnings;

package Template::Resolver;
$Template::Resolver::VERSION = '1.13';
# ABSTRACT: A powerful, and simple, library for resolving placeholders in templated files
# PODNAME: Template::Resolver

use Carp;
use Log::Any;
use Scalar::Util qw(blessed);
use Template::Transformer;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub _entity_to_properties {
    my ( $entity, $properties, $prefix ) = @_;

    $properties = {} unless $properties;

    my $ref = ref($entity);
    if ( ( $ref && $ref eq 'HASH' ) || blessed($entity) ) {
        foreach my $key ( keys( %{$entity} ) ) {
            _entity_to_properties( $entity->{$key}, $properties,
                ( $prefix ? "$prefix.$key" : $key ) );
        }
    }
    elsif ( $ref && $ref eq 'ARRAY' ) {
        my $index = 0;
        foreach my $array_entity ( @{$entity} ) {
            _entity_to_properties( $array_entity, $properties,
                ( $prefix ? "$prefix\[$index\]" : "[$index]" ) );
            $index++;
        }
    }
    elsif ($ref) {
        croak("unsupported ref type '$ref'");
    }
    else {
        $properties->{$prefix} = $entity;
    }

    return $properties;
}

sub _get_property {
    my ( $self, $value, $transform ) = @_;
    my $transformed = $self->{transformer}->transform( $value, $transform );
    croak( "undefined value $value" . ( $transform ? ", using transform $transform" : '' ) )
        unless ( defined($transformed) );
    return $transformed;
}

sub _init {
    my ( $self, $entity, %options ) = @_;

    my $os = $options{os} || $^O;

    $logger->debug('creating new Resolver');

    $self->{entity}      = $entity;
    $self->{transformer} = Template::Transformer->new(
        $os,
        _entity_to_properties($entity),
        (   $options{additional_transforms}
            ? ( additional_transforms => $options{additional_transforms} )
            : ()
        )
    );

    return $self;
}

sub resolve {
    my ( $self, %options ) = @_;

    my $key = $options{key} || 'TEMPLATE';

    my $content;
    if ( $options{content} ) {
        $content = $options{content};
    }
    elsif ( $options{handle} ) {
        $content = do { local ($/) = undef; <$options{handle}> };
    }
    elsif ( $options{filename} ) {
        $content = do { local ( @ARGV, $/ ) = $options{filename}; <> };
    }
    else {
        croak('Must provide one of [content, handle, filename]');
    }

    $content =~ s/\$\{$key(?:_(.*?))?\{(.*?)\}\}/$self->_get_property($2,$1)/egs;
    return $content;
}

1;

__END__

=pod

=head1 NAME

Template::Resolver - A powerful, and simple, library for resolving placeholders in templated files

=head1 VERSION

version 1.13

=head1 SYNOPSIS

  use Template::Resolver;
  my $resolver = Template::Resolver->new($entity);
  $resolver->resolve(file => '/path/to/file', key => 'REPLACEME');

=head1 DESCRIPTION

This module provides a powerful way to resolve placeholders inside of a templated file.
It uses L<Template::Transformer> to interpolate the the placeholder values.

=head1 CONSTRUCTORS

=head2 new(\%entity, %options)

Creates a new resolver with properties from C<\%entity> and C<%options> if any.  The
available options are:

=over 4

=item additional_transforms

Additional custom transforms that will be added to the standard transforms.
Must be a hashref containing transform name to sub reference mappings.  
The sub reference(s) will be called as a method(s) with a single parameter
containing the contents of the placeholder.

=item os

The operating system path format used when resolving C<${TEMPLATE_os{xxx}}> placeholders.

=back

=head1 METHODS

=head2 resolve(%options)

Will read the template and replace all placeholders prefixed by C<key>. One of the 
options C<content>, C<handle>, or C<filename> is required.  The available options are:

=over 4

=item content

A string containing templated content.

=item filename

The name of a file containing templated content.

=item handle

A handle to a file containing templated content.

=item key

The template key, defaults to C<TEMPLATE>.

=back

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Template::Transformer|Template::Transformer>

=item *

L<Template::Overlay|Template::Overlay>

=item *

L<https://github.com/lucastheisen/template-resolver|https://github.com/lucastheisen/template-resolver>

=back

=cut
