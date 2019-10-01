package Sub::Multi::Tiny::Dispatcher::TypeParams;

use 5.006;
use strict;
use warnings;

use parent 'Exporter';
use vars::i '@EXPORT' => qw(MakeDispatcher);

use Guard;
use Import::Into;
use Sub::Multi::Tiny::Util qw(_hlog _line_mark_string _make_positional_copier
                                _complete_dispatcher);
use Type::Params qw(multisig);
use Type::Tiny ();

our $VERSION = '0.000012'; # TRIAL

# Documentation {{{1

=head1 NAME

Sub::Multi::Tiny::Dispatcher::TypeParams - Dispatcher-maker using Type::Params for Sub::Multi::Tiny

=head1 SYNOPSIS

    # In a multisub
    require Sub::Multi::Tiny qw($param D:TypeParams);

    # Internals of Sub::Multi::Tiny
    use Type::Params;
    my $dispatcher_coderef =
        Sub::Multi::Tiny::Dispatcher::TypeParams::MakeDispatcher({impls=>[]...});

This module dispatches to any function that can be distinguished by the
C<multisig> function in L<Type::Params>.  See
L<Type::Params/MULTIPLE SIGNATURES>.

See L<Sub::Multi::Tiny> for more about the usage of this module.
This module does not export any symbols.

=head1 USAGE NOTES

=head2 Candidate order

The candidates must be listed with more
specific first, since they are tried top to bottom.  For example, constraint
L<Types::Standard/Str> matches any scalar (as of Types::Standard v1.004004), so
it should be listed after more specific constraints such as
L<Types::Standard/Int>.

=head2 Named parameters

C<Type::Parameters::multisig()> does not directly support named parameters.
Instead, use a slurpy hash (C<Dict>) parameter to collect named parameters.
An example is given in L<Type::Params/Mixed Positional and Named Parameters>.

=head1 FUNCTIONS

=cut

# }}}1

=head2 MakeDispatcher

Make the default dispatcher for the given multi.  See L</SYNOPSIS>.

=cut

# uniquify constraint names
my $_constraint_idx = 0;

# Our own "any" type
my $_any_type = Type::Tiny->new(name => 'Any_SMTD_TypeParams');
    # Default constraint accepts anything

sub MakeDispatcher {
    my $hr = shift; # Has possible_params and impls arrayrefs
    my $code = '';
    _hlog { require Data::Dumper;
            "Making Type::Params dispatcher for: ",
                Data::Dumper->Dump([$hr], ['multisub']) };

    # Make an array of typechecks for multisig()
    my (@sigs, @impls, @copiers);
    foreach my $impl (@{$hr->{impls}}) {
        my @sig;
        foreach my $param (@{$impl->{args}}) {

            # Sanity checks.  TODO FIXME remove the need for these!
            die "I don't yet know how to handle named arguments"
                if $param->{named};
            die "I don't yet know how to handle optional arguments"
                if !$param->{reqd};

            # Make the constraint
            my $constraint;
            if($param->{type} && $param->{where}) {
                $constraint = $param->{type} & $param->{where};
                    # Subtype - see http://blogs.perl.org/users/toby_inkster/2014/08/typetiny-tricks-1-quick-intersections.html
            } elsif($param->{type}) {
                $constraint = $param->{type};
            } elsif($param->{where}) {
                $constraint = Type::Tiny->new(
                    name => 'Constraint' . $_constraint_idx++ . '_' .
                        substr($param->{name}, 1),
                    constraint => $param->{where},
                );
            } else {    # No constraint
                $constraint = $_any_type;
            }

            # Add it to the signature
            push @sig, $constraint;
        } #foreach param

        push @sigs, [@sig];
        push @impls, $impl->{code};

        # Use a straight positional copier.  This is sufficient even for
        # named parameters because Type::Params::multisig()
        # fakes named parameters with a slurpy hash.
        push @copiers, _make_positional_copier($hr->{defined_in}, $impl);
    } #foreach impl

    my $checker = multisig(@sigs);

    # Make the dispatcher
    $code .= _line_mark_string <<'EOT';
            # Find the candidate
            @_ = $data[0]->(@_);      # $checker.  Dies on error.
                # NOTE: this change can't be `local`ized because `goto`
                # undoes the `local` - see #8
            $candidate = $data[1]->[${^TYPE_PARAMS_MULTISIG}];   # impls
            $copier = $data[2]->[${^TYPE_PARAMS_MULTISIG}];      # copiers
EOT

    return _complete_dispatcher($hr, $code, $checker, \@impls, \@copiers);
} #MakeDispatcher

=head2 import

When used, also imports L<Type::Tiny> into the caller's namespace (since
C<Type::Tiny> types are how this dispatcher functions!).
The caller may also wish to import L<Types::Standard>, but we don't do so
here in the interest of generality.

=cut

sub import {
    my $target = caller;
    __PACKAGE__->export_to_level(1, @_);
    Type::Tiny->import::into($target);
}

1;
__END__

# Rest of documentation {{{1

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# }}}1
# vi: set fdm=marker: #
