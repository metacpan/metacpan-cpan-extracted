package OpenTracing::Types;



=head1 NAME

OpenTracing::Types - Type constraints for checking Interfaces

=cut



our $VERSION = 'v0.204.0';



=head1 SYNOPSIS

    use OpenTracing::Types qw/Span/;
    #
    # imports the 'Span' Type
    
    use Types::Standard qw/Maybe/;
    use Types::Common::Numeric qw/PositiveOrZeroNum/;
    
    use Function::Parameters;
    use Function::Return;
    
    # create a subroutine with some fancy type checks
    #
    sub time_gap (Span $span1, Span $span2) :Return Maybe[PositiveOrZeroNum] {
        return unless $span1->finish_time and $span2->start_time;
        return $span2->start_time - $span1->finish_time
    }

=head1 DESCRIPTION

This library of L<Type::Tiny> type constraints provide Duck Type checks for all
common elements that conform L<OpenTracing::Interface>

See L<Type::Library/"Export"> about the various ways to import types an related
methods.

=cut

use Type::Library -base;
use Type::Utils qw/duck_type/;

# Dear developer, for the sake of testing, please DO NOT just copy paste the
# methods from the `OpenTracing::Types` file. If I wanted to just
# check that the `duck_type` utility from `Type::Tiny` would work, I would have
# not needed this test.
#
# This test is to ensure that what is written in the POD files is indeed what
# the Types library is doing.
#
# The OpenTracing::Interface::*.pod files are leading, not the code.
#
use constant {
    REQUIRED_METHODS_FOR_CONTEXT_REFERENCE => [ qw(
        new_child_of
        new_follows_from
        get_referenced_context
        type_is_child_of
        type_is_follows_from
    ) ],
    REQUIRED_METHODS_FOR_SCOPE => [ qw(
        close
        get_span
    ) ],
    REQUIRED_METHODS_FOR_SCOPE_MANAGER => [ qw(
        activate_span
        get_active_scope
    ) ],
    REQUIRED_METHODS_FOR_SPAN => [ qw(
        get_context
        overwrite_operation_name
        finish
        add_tag
        add_tags
        get_tags
        log_data
        add_baggage_item
        add_baggage_items
        get_baggage_item
        get_baggage_items
    ) ],
    REQUIRED_METHODS_FOR_SPAN_CONTEXT => [ qw(
        get_baggage_item
        get_baggage_items
        with_baggage_item
        with_baggage_items
    ) ],
    REQUIRED_METHODS_FOR_TRACER => [ qw(
        get_scope_manager
        get_active_span
        start_active_span
        start_span
        inject_context
        extract_context
    ) ],
};

# XXX DO NOT COPY PASTE FROM CODE, READ THE POD

duck_type ContextReference => REQUIRED_METHODS_FOR_CONTEXT_REFERENCE;
duck_type Scope            => REQUIRED_METHODS_FOR_SCOPE;
duck_type ScopeManager     => REQUIRED_METHODS_FOR_SCOPE_MANAGER;
duck_type Span             => REQUIRED_METHODS_FOR_SPAN;
duck_type SpanContext      => REQUIRED_METHODS_FOR_SPAN_CONTEXT;
duck_type Tracer           => REQUIRED_METHODS_FOR_TRACER;



=head1 TYPES

The following Duck Types are being defined with the mentioned required methods:

=cut



=head2 C<< ContextReference >>

=over

=item C<< new_child_of >>

=item C<< new_follows_from >>

=item C<< get_referenced_context >>

=item C<< type_is_child_of >>

=item C<< type_is_follows_from >>

=back

See also L<OpenTracing::Interface::ContextReference/"INSTANCE METHODS">
and L<OpenTracing::Interface::ContextReference/"CONSTRUCTOR METHODS">.



=head2 C<< Scope >>

=over

=item C<< close >>

=item C<< get_span >>

=back

See also L<OpenTracing::Interface::Scope/"INSTANCE METHODS">.



=head2 C<< ScopeManager >>

=over

=item C<< activate_span >>

=item C<< get_active_scope >>

=back

See also L<OpenTracing::Interface::ScopeManager/"INSTANCE METHODS">.


=head2 C<< Span >>

=over

=item C<< get_context >>

=item C<< overwrite_operation_name >>

=item C<< finish >>

=item C<< set_tag >>

=item C<< log_data >>

=item C<< add_baggage_item >>

=item C<< get_baggage_item >>

=back

See also L<OpenTracing::Interface::Span/"INSTANCE METHODS">.



=head2 C<< SpanContext >>

=over

=item C<< get_baggage_item >>

=item C<< with_baggage_item >>

=back

See also L<OpenTracing::Interface::SpanContext/"INSTANCE METHODS">.



=head2 C<< Tracer >>

=over

=item C<< get_scope_manager >>

=item C<< get_active_span >>

=item C<< start_active_span >>

=item C<< start_span >>

=item C<< inject_context >>

=item C<< extract_context >>

=back

See also L<OpenTracing::Interface::Tracer/"INSTANCE METHODS">.



=cut



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>

=head1 COPYRIGHT AND LICENSE

'OpenTracing Types' is Copyright (C) 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This library is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
