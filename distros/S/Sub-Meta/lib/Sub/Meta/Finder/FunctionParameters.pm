package Sub::Meta::Finder::FunctionParameters;
use strict;
use warnings;

use Function::Parameters;

sub find_materials {
    my $sub = shift;

    my $info = Function::Parameters::info($sub);
    return unless $info;

    my $keyword = $info->keyword;
    my $nshift  = $info->nshift;

    my @args;
    for ($info->positional_required) {
        push @args => {
            type       => $_->type,
            name       => $_->name,
            positional => 1,
            required   => 1,
        }
    }

    for ($info->positional_optional) {
        push @args => {
            type       => $_->type,
            name       => $_->name,
            positional => 1,
            required   => 0,
        }
    }

    for ($info->named_required) {
        push @args => {
            type       => $_->type,
            name       => $_->name,
            named      => 1,
            required   => 1,
        }
    }

    for ($info->named_optional) {
        push @args => {
            type       => $_->type,
            name       => $_->name,
            named      => 1,
            required   => 0,
        }
    }

    my $invocant = $info->invocant ? +{
        name => $info->invocant->name,
        $info->invocant->type ? ( type => $info->invocant->type ) : (),
    } : undef;

    my $slurpy = $info->slurpy ? +{
        name => $info->slurpy->name,
        $info->slurpy->type ? ( type => $info->slurpy->type ) : (),
    } : undef;

    return +{
        sub       => $sub,
        is_method => $keyword eq 'method' ? !!1 : !!0,
        parameters => {
            args   => \@args,
            nshift => $nshift,
            $invocant ? ( invocant  => $invocant ) : (),
            $slurpy ? ( slurpy => $slurpy ) : (),
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Finder::FunctionParameters - finder of Function::Parameters

=head1 SYNOPSIS
    
    use Sub::Meta::Creator;
    use Sub::Meta::Finder::FunctionParameters;

    my $creator = Sub::Meta::Creator->new(
        finders => [ \&Sub::Meta::Finder::FunctionParameters::find_materials ],
    );

    use Function::Parameters;
    use Types::Standard -types;

    method hello(Str $msg) { }
    my $meta = $creator->create(\&hello);
    # =>
    # Sub::Meta
    #   args [
    #       [0] Sub::Meta::Param->new(name => '$msg', type => Str)
    #   ],
    #   invocant   Sub::Meta::Param->(name => '$self', invocant => 1),
    #   nshift     1,
    #   slurpy     !!0

=head1 FUNCTIONS

=head2 find_materials($sub)

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
