use MooseX::Declare;

class Test::Class::Sugar::CodeGenerator {
    use Sub::Name;
    use Carp qw/croak/;
    use B::Hooks::EndOfScope;
    our $VERSION = '0.0200';

    has name    => (is => 'rw', isa => 'Str');
    has plan    => (is => 'rw');
    has context => (is => 'rw');

    has options => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub {{}},
    );

    has classname => (
        is => 'rw',
        isa => 'Str',
        lazy_build => 1,
    );

    method _classname_prefix {
        my $prefix = $self->options->{prefix} || "Test";
        $prefix =~ s/(?:::)?$/::/;
        $prefix;
    }

    method _build_classname {
        if ($self->options->{class_under_test}) {
            $self->_classname_prefix . $self->options->{class_under_test};
        }
        else {
            $self->context->get_curstash_name
              || croak "Must specify a testclass name or a class to exercise";
        }
    }

    method test_preamble {
        $self->context->scope_injector_call() . q{my $test = shift;};
    }

    method inject_test {
        my $ctx = $self->context;
        $ctx->skipspace;
        $ctx->inject_if_block($self->test_preamble);
    }

    method shadow_test {
        my $ctx = $self->context;
        my $name = $self->name;
        my $plan = $self->plan;

        my $classname = $self->classname;

        my $longname = ($name !~ /::/)
          ? join('::', $classname, $name)
          : $name;

        $ctx->shadow(
            sub (&) {
                my $code = shift;
                no strict 'refs';
                *{$longname} = subname $longname => $code;
                $classname->add_testinfo(
                    $name,
                    $ctx->declarator,
                    $plan
                );
            }
        );
    }

    method helpers {
        $self->options->{helpers} = [qw{Test::Most}] unless defined $self->options->{helpers};
        @{$self->options->{helpers}};
    }

    method use_helpers_string {
        join '', map {"use $_;"} $self->helpers;
    }

    method subject_method_string {
        my $subject = $self->options->{class_under_test};
        return '' unless $subject;

        "require ${subject} unless \%${subject}::; sub subject { \"${subject}\" };"
    }

    method baseclasses {
        $self->options->{base} || 'Test::Class';
    }

    method use_base_string {
        "use base qw/" . $self->baseclasses . '/;';
    }

    method testclass_preamble {
        my $classname = $self->classname;

        $self->context->scope_injector_call
        . "package " . $self->classname . "; use strict; use warnings;"
        . "use Test::Class::Sugar qw/-inner/;"
        . $self->use_base_string
        . $self->use_helpers_string
        . $self->subject_method_string
    }

    method inject_testclass {
        $self->context->skipspace;
        my $inject = $self->context->inject_if_block($self->testclass_preamble);
        croak "Expecting an opening brace" unless defined $inject;
        $inject;
    }

    method shadow_testclass {
        $self->context->shadow(sub (&) { shift->() });
    }

    method install_testclass {
        croak "You provide either a class name or an exercises clause"
            unless defined $self->has_classname;

        $self->inject_testclass;
        $self->shadow_testclass;
    }

    method install_test {
        $self->inject_test;
        $self->shadow_test;
    }
}

__END__

=head1 NAME

Test::Class::Sugar::CodeGenerator - CodeGenerator for building B<Test::Class>es

=head1 DESCRIPTION

This class is intentionally mostly undocumented. However, if you were to take
it on yourself to write a version of L<Test::Class::Sugar> which builds, say,
L<Test::Able> classes, you should be able to do the job using this class as
your starting point.

If you get stuck, drop me some email and I'll try and help you out.

=head1 AUTHOR

Piers Cawley C<< <pdcawley@bofh.org.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Piers Cawley C<< <pdcawley@bofh.org.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
