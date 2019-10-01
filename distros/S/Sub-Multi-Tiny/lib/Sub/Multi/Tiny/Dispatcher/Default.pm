package Sub::Multi::Tiny::Dispatcher::Default;

use 5.006;
use strict;
use warnings;

#use Data::Dumper;   # DEBUG

use Guard;
use Sub::Multi::Tiny::Util qw(_hlog _line_mark_string _make_positional_copier
                                _complete_dispatcher);

our $VERSION = '0.000012'; # TRIAL

# Documentation {{{1

=head1 NAME

Sub::Multi::Tiny::Dispatcher::Default - Default dispatcher-maker for Sub::Multi::Tiny

=head1 SYNOPSIS

    require Sub::Multi::Tiny::Dispatcher::Default;
    my $dispatcher_coderef =
        Sub::Multi::Tiny::Dispatcher::Default::MakeDispatcher({impls=>[]...});

See L<Sub::Multi::Tiny> for more.  This module does not export any symbols
(or even have the capability to do so!).

This dispatcher currently only dispatches by arity.

=head1 FUNCTIONS

=cut

# }}}1

=head2 MakeDispatcher

Make the default dispatcher for the given multi.  See L</SYNOPSIS>.

TODO expand.  For now, only dispatches based on arity.

=cut

sub MakeDispatcher {
    my $hr = shift; # Has possible_params and impls arrayrefs
    my $code = '';
    _hlog { require Data::Dumper;
            "Making default dispatcher for: ", Data::Dumper->Dump([$hr], ['multisub']) };

    # Sort the candidates
    my (%candidates_by_arity, %copiers_by_arity);   # TODO make this cleaner
    foreach my $impl (@{$hr->{impls}}) {
        my $arity = @{$impl->{args}};
        die "Two candidates of the same arity ($arity) - try D:TypeParams?"
            if exists $candidates_by_arity{$arity};
        $candidates_by_arity{$arity} = $impl->{code};
        $copiers_by_arity{$arity} =
            _make_positional_copier($hr->{defined_in}, $impl);

        # Die cleanly if we got something we can't handle
        foreach my $arg (@{$impl->{args}}) {
            die "Type constraint on $impl->{candidate_name}, arg $arg->{name}"
                . '- try D:TypeParams?' if $arg->{type};
            die "'where' clause on $impl->{candidate_name}, arg $arg->{name}"
                . '- try D:TypeParams?' if $arg->{where};
        } #foreach $arg

    } #foreach $impl

    # Make the dispatcher
    $code .= _line_mark_string <<EOT;
            # Find the candidate
            my \$arity = scalar \@_;
            \$candidate = \$data[0]->{\$arity};
            die "No candidate found for $hr->{defined_in}\() with arity " .
                (scalar \@_) unless \$candidate;
            \$copier = \$data[1]->{\$arity};
EOT

    return _complete_dispatcher($hr, $code,
            # @data used by $code
            \%candidates_by_arity,
            \%copiers_by_arity
    );

} #MakeDispatcher

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
