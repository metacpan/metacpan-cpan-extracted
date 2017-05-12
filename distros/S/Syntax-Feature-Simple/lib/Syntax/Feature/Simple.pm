use strictures 1;

# ABSTRACT: DWIM syntax extensions

package Syntax::Feature::Simple;
{
  $Syntax::Feature::Simple::VERSION = '0.002';
}
BEGIN {
  $Syntax::Feature::Simple::AUTHORITY = 'cpan:PHAYLON';
}

use Syntax::Feature::Function           0.001;
use Syntax::Feature::Method             0.001;
use Syntax::Feature::Sugar::Callbacks   0.002;

use Carp                    qw( croak );
use Sub::Install    0.925   qw( reinstall_sub );
use syntax                  qw( method );

my $role_meta = 'MooseX::Role::Parameterized::Meta::Role::Parameterizable';

method install ($class: %args) {
    croak q{You cannot use 'simple' as a syntax extension. You need to }
        . q{select a specific version, for example 'simple/v1'}
        if $class eq __PACKAGE__;
    my $target     = $args{into};
    my @extensions = $class->_available_extensions;
    $class->_setup_extension($_, $target)
        for @extensions;
    return 1;
}

method _check_is_moose_param_role ($class: $target) {
    return $class->_check_meta_isa($target, $role_meta);
}

method _check_has_meta ($class: $target) {
    return $INC{'Moose.pm'}
        ? do { require Moose::Util; Moose::Util::find_meta($target) }
        : undef;
}

method _check_meta_isa ($class: $target, $check) {
    my $meta = $class->_check_has_meta($target)
        or return undef;
    return $meta->isa($check);
}

method _setup_extension ($class: $extension, $target) {
    my $setup_method = "_setup_${extension}_ext";
    my $check_method = "_can${setup_method}";
    return undef
        if $class->can($check_method)
           and not $class->$check_method($target);
    return $class->$setup_method($target);
}

method _setup_moose_param_role_body_sugar_ext ($class: $target) {
    Syntax::Feature::Sugar::Callbacks->install(
        into    => $target,
        options => {
            -invocant   => '',
            -callbacks  => {
                role    => {
                    -only_anon  => 1,
                    -stmt       => 1,
                    -default    => ['$parameter'],
                },
            },
        },
    );
}

method _setup_function_keyword_ext ($class: $target) {
    Syntax::Feature::Function->install(
        into    => $target,
        options => { -as => 'fun' },
    );
    return 1;
}

method _setup_moose_param_role_method_sugar_ext ($class: $target) {
    my $orig = $target->can('method')
        or croak qq{There is no 'method' callback installed in '$target'};
    reinstall_sub {
        into    => $target,
        as      => 'method',
        code    => sub {
            return $_[0] if ref $_[0] eq 'CODE';
            goto $orig;
        },
    };
    Syntax::Feature::Sugar::Callbacks->install(
        into    => $target,
        options => {
            -invocant   => '$self',
            -callbacks  => {
                method  => { -allow_anon => 1 },
            },
        },
    );
    return 1;
}

method _setup_method_keyword_ext ($class: $target) {
    Syntax::Feature::Method->install(
        into    => $target,
        options => { -as => 'method' },
    );
    return 1;
}

method _setup_modifier_sugar_ext ($class: $target) {
    Syntax::Feature::Sugar::Callbacks->install(
        into    => $target,
        options => {
            -invocant   => '$self',
            -callbacks  => {
                before  => {},
                after   => {},
                around  => { -before => ['$orig'] },
            },
        },
    );
    return 1;
}

1;



=pod

=head1 NAME

Syntax::Feature::Simple - DWIM syntax extensions

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This is a more of a syntax extension package than a simple extension by
itself. It will detect what kind of package it is imported into, and setup
appropriate syntax extensions depending on the type.

=head2 Moose Classes and Roles

If a L<Moose> class or role is detected, this extension will setup a C<fun>
keyword for function declarations, a C<method> keyword, and one keyword
each for C<before>, C<after> and C<around>.

The modifiers behave exactly like normal method declarations, except for
C<around> which will provide the original method in a lexical named C<$orig>.

    package MyProject::MooseClassOrRole;
    use Moose;
    # or use Moose::Role
    # or use MooseX::Role::Parameterized,
    #    but with body inside role { ... }
    use syntax qw( simple/v2 );

    fun foo ($x) { ... }
    my $anon_f = fun ($x) { ... };

    method bar ($x) { $self->say($x) }
    my $anon_m = method ($x) { $self->say($x) };

    before baz ($x) { $self->say($x) }
    after  baz ($x) { $self->say($x) }
    around baz ($x) { $self->say($self->$orig($x)) }

    1;

In case of a L<parameterizable role|MooseX::Role::Parameterized> the right
callback will be called, but compatibility with anonymous method declarations
will be preserved:

    package MyProject::ParamRole;
    use MooseX::Role::Parameterized;
    use syntax qw( simple/v2 );

    parameter method_name => (is => 'ro');

    # defaults to $parameter
    role ($param) {
        my $name = $param->method_name;
        method "$name" ($n) { $self->say($n) }
        my $anon = method ($n) { $self->say($n) };
    }

    1;

As of L<version 2|Syntax::Feature::Simple::V2> you will also get sugar for
the C<role> body that allows you to specify a signature. By default, the
parameter object will be available in a variable named C<$parameter>.

=head2 Plain Packages

By default, if no other kind of package type is detected, C<simple/v1> will
only setup the function syntax, while C<simple/v2> will setup the function
and the method extension.

    package MyProject::Util;
    use strictures 1;
    use syntax qw( simple/v2 );

    fun foo ($x) { ... }
    my $anon_f = fun ($x) { ... };

    method bar ($class: $x, $y) { ... }
    my $anon_m = method ($x) { ... };

    1;

=head1 FUTURE CANDIDATES

=head2 C<simple/v*> (basic set)

=over

=item * C<no indirect>

=item * C<use true>

=item * L<Try::Tiny>

=back

=head2 C<simple/x*> (extended set)

=over

=item * L<Smart::Match> if a valid Perl version was declared

=back

=head1 SEE ALSO

=over

=item L<Syntax::Feature::Simple::V1>

Version 1 of the extension set.

=item L<Syntax::Feature::Simple::V2>

Version 2 of the extension set.

=item L<syntax>

The syntax dispatching module.

=item L<Syntax::Feature::Simple>

Contains general information about this extension.

=item L<Syntax::Feature::Method>

Specifics about the C<method> and modifier keywords.

=item L<Syntax::Feature::Function>

Specifics about the C<fun> function keyword.

=item L<Moose>

Post-modern object-orientation.

=item L<MooseX::Role::Parameterized>

Parameterizable roles for L<Moose>.

=back

=head1 BUGS

Please report any bugs or feature requests to bug-syntax-feature-simple@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Syntax-Feature-Simple

=head1 AUTHOR

Robert 'phaylon' Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert 'phaylon' Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

