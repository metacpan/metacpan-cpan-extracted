
package Sub::Inject;
$Sub::Inject::VERSION = '0.3.0';
# ABSTRACT: Inject subroutines into a lexical scope

use 5.018;

require XSLoader;
XSLoader::load(__PACKAGE__);

sub sub_inject {
    @_ = %{ $_[0] } if @_ == 1 && ref $_[0] eq 'HASH';
    goto &_sub_inject;
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Sub::Inject;   # requires perl 5.18+
#pod
#pod     {
#pod         BEGIN { Sub::Inject::sub_inject( 'one', sub { say "One!" } ); }
#pod         one();
#pod     }
#pod
#pod     one();    # throws "Undefined subroutine &main::one called"
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module allows to dynamically inject lexical subs
#pod during compilation. It is implemented using
#pod lexical subroutines introduced in perl 5.18.
#pod
#pod This is a low level library. It is meant for cases where
#pod subroutine names and bodies are to be treated as data
#pod or not known in advance. Otherwise, lexical subs syntax
#pod is recommended. For instance,
#pod
#pod     use experimental qw(lexical_subs);
#pod     state sub foo { say "One!" }
#pod
#pod is the static equivalent of
#pod
#pod     BEGIN {
#pod         Sub::Inject::sub_inject( 'one', sub { say "One!" } );
#pod     }
#pod
#pod =head1 HOW IT WORKS
#pod
#pod Used like
#pod
#pod     BEGIN { Sub::Inject::sub_inject('foo', sub { ... }) }
#pod
#pod it works as
#pod
#pod     \state &foo = sub { ... };
#pod
#pod That means:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod The scope behavior is the same as the lexical sub statement
#pod
#pod =item *
#pod
#pod Being a "state" lexical guarantees the persistence
#pod of the association between the name and the subroutine
#pod
#pod =item *
#pod
#pod The reference aliasing operation means no copy is done
#pod
#pod =back
#pod
#pod =head1 FUNCTIONS
#pod
#pod =head2 sub_inject
#pod
#pod     sub_inject($name, $code);
#pod     sub_inject($name1, $code1, $name2, $code2);
#pod     sub_inject(\%subs);
#pod
#pod Injects C<$code> as a lexical subroutine named C<$name>
#pod into the currently compiling scope. The same applies
#pod to multiple name / code pairs given as input.
#pod
#pod Throws an error if called at runtime.
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod This code is a fork of "Lexical.xs" file from
#pod L<Exporter-Lexical distribution|https://metacpan.org/release/Exporter-Lexical>
#pod by L<Jesse Luehrs|https://metacpan.org/author/DOY>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<perlsub/"Lexical Subroutines">
#pod
#pod L<feature/"The 'lexical_subs' feature">
#pod
#pod L<Exporter::Lexical> and L<lexically>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Sub::Inject - Inject subroutines into a lexical scope

=head1 VERSION

version 0.3.0

=head1 SYNOPSIS

    use Sub::Inject;   # requires perl 5.18+

    {
        BEGIN { Sub::Inject::sub_inject( 'one', sub { say "One!" } ); }
        one();
    }

    one();    # throws "Undefined subroutine &main::one called"

=head1 DESCRIPTION

This module allows to dynamically inject lexical subs
during compilation. It is implemented using
lexical subroutines introduced in perl 5.18.

This is a low level library. It is meant for cases where
subroutine names and bodies are to be treated as data
or not known in advance. Otherwise, lexical subs syntax
is recommended. For instance,

    use experimental qw(lexical_subs);
    state sub foo { say "One!" }

is the static equivalent of

    BEGIN {
        Sub::Inject::sub_inject( 'one', sub { say "One!" } );
    }

=head1 HOW IT WORKS

Used like

    BEGIN { Sub::Inject::sub_inject('foo', sub { ... }) }

it works as

    \state &foo = sub { ... };

That means:

=over 4

=item *

The scope behavior is the same as the lexical sub statement

=item *

Being a "state" lexical guarantees the persistence
of the association between the name and the subroutine

=item *

The reference aliasing operation means no copy is done

=back

=head1 FUNCTIONS

=head2 sub_inject

    sub_inject($name, $code);
    sub_inject($name1, $code1, $name2, $code2);
    sub_inject(\%subs);

Injects C<$code> as a lexical subroutine named C<$name>
into the currently compiling scope. The same applies
to multiple name / code pairs given as input.

Throws an error if called at runtime.

=head1 ACKNOWLEDGEMENTS

This code is a fork of "Lexical.xs" file from
L<Exporter-Lexical distribution|https://metacpan.org/release/Exporter-Lexical>
by L<Jesse Luehrs|https://metacpan.org/author/DOY>.

=head1 SEE ALSO

L<perlsub/"Lexical Subroutines">

L<feature/"The 'lexical_subs' feature">

L<Exporter::Lexical> and L<lexically>

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
