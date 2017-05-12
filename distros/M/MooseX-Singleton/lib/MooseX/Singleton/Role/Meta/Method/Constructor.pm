package MooseX::Singleton::Role::Meta::Method::Constructor;
use Moose::Role;

our $VERSION = '0.30';

if ( $Moose::VERSION < 1.9900 ) {
    override _initialize_body => sub {
        my $self = shift;

        # TODO:
        # the %options should also include a both
        # a call 'initializer' and call 'SUPER::'
        # options, which should cover approx 90%
        # of the possible use cases (even if it
        # requires some adaption on the part of
        # the author, after all, nothing is free)
        my $source = 'sub {';
        $source .= "\n" . 'my $class = shift;';

        $source .= "\n"
            . 'my $existing = do { no strict "refs"; no warnings "once"; \${"$class\::singleton"}; };';
        $source .= "\n" . 'return ${$existing} if ${$existing};';

        $source .= "\n" . 'return $class->Moose::Object::new(@_)';
        $source
            .= "\n"
            . '    if $class ne \''
            . $self->associated_metaclass->name . '\';';

        $source .= $self->_generate_params( '$params', '$class' );
        $source .= $self->_generate_instance( '$instance', '$class' );
        $source .= $self->_generate_slot_initializers;

        $source .= ";\n" . $self->_generate_triggers();
        $source .= ";\n" . $self->_generate_BUILDALL();

        $source .= ";\n" . 'return ${$existing} = $instance';
        $source .= ";\n" . '}';
        warn $source if $self->options->{debug};

        my $attrs = $self->_attributes;

        my @type_constraints
            = map { $_->can('type_constraint') ? $_->type_constraint : undef }
            @$attrs;

        my @type_constraint_bodies
            = map { defined $_ ? $_->_compiled_type_constraint : undef; }
            @type_constraints;

        my $defaults = [map { $_->default } @$attrs];

        my ( $code, $e ) = $self->_compile_code(
            code        => $source,
            environment => {
                '$meta'                   => \$self,
                '$attrs'                  => \$attrs,
                '$defaults'               => \$defaults,
                '@type_constraints'       => \@type_constraints,
                '@type_constraint_bodies' => \@type_constraint_bodies,
            },
        );

        $self->throw_error(
            "Could not eval the constructor :\n\n$source\n\nbecause :\n\n$e",
            error => $e, data => $source )
            if $e;

        $self->{'body'} = $code;
    };
}

# Ideally we'd be setting this in the constructor, but the new() methods in
# what the parent classes are not well-factored.
#
# This is all a nasty hack, though. We need to fix Class::MOP::Inlined to
# allow constructor class roles to say "if the parent class has role X,
# inline".
override _expected_method_class => sub {
    my $self = shift;

    my $super_value = super();
    if ( $super_value eq 'Moose::Object' ) {
        for my $parent ( map { Class::MOP::class_of($_) }
            $self->associated_metaclass->superclasses ) {
            return $parent->name
                if $parent->is_anon_class
                    && grep { $_->name eq 'Moose::Object' }
                    map { Class::MOP::class_of($_) } $parent->superclasses;
        }
    }

    return $super_value;
};

no Moose::Role;

1;

# ABSTRACT: Constructor method role for MooseX::Singleton

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Singleton::Role::Meta::Method::Constructor - Constructor method role for MooseX::Singleton

=head1 VERSION

version 0.30

=head1 DESCRIPTION

This role overrides the generated object C<new> method so that it returns the
singleton if it already exists.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Singleton>
(or L<bug-MooseX-Singleton@rt.cpan.org|mailto:bug-MooseX-Singleton@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
