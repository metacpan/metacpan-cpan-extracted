package Sub::Meta::Finder::SubWrapInType;
use strict;
use warnings;

use Scalar::Util ();

sub find_materials {
    my $sub = shift;

    return unless Scalar::Util::blessed($sub) && $sub->isa('Sub::WrapInType');

    return {
        sub       => $sub,
        args      => $sub->params,
        returns   => $sub->returns,
        is_method => $sub->is_method,
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Finder::SubWrapInType - finder of Sub::WrapInType

=head1 SYNOPSIS

    use Sub::Meta::Creator;
    use Sub::Meta::Finder::SubWrapInType;

    my $creator = Sub::Meta::Creator->new(
        finders => [ \&Sub::Meta::Finder::SubWrapInType::find_materials ],
    );

    use Sub::WrapInType;
    use Types::Standard -types;

    my $foo = wrap_method [Int, Int] => Int, sub { };
    my $meta = $creator->create($foo);
    # =>
    # Sub::Meta
    #   args [
    #       [0] Sub::Meta::Param->new(type => Int),
    #       [1] Sub::Meta::Param->new(type => Int),
    #   ],
    #   returns {
    #       list   => Int,
    #       scalar => Int,
    #   }
    #   invocant   Sub::Meta::Param->(invocant => 1),
    #   nshift     1,
    #   slurpy     !!0


=head1 FUNCTIONS

=head2 find_materials

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
