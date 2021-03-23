package Sub::WrapInType::Attribute;
use v5.14.0;
use strict;
use warnings;

our $VERSION = "0.01";

use Attribute::Handlers;
use B::Hooks::EndOfScope;
use Sub::WrapInType ();
use Sub::Util ();
use attributes;
use namespace::autoclean;

my $DEFAULT_CHECK = !!($ENV{SUB_WRAPINTYPE_ATTRIBUTE_CHECK} // 1);
my %CHECK;
my @INSTALL_ARGS;

sub import {
    my $class = shift;
    my %args = @_;

    my $pkg = $args{pkg} ? $args{pkg} : scalar caller;
    $CHECK{$pkg} = !!$args{check} if exists $args{check};
    {
        # allow importing package to use attribute
        no strict qw(refs);
        my $MODIFY_CODE_ATTRIBUTES = \&Attribute::Handlers::UNIVERSAL::MODIFY_CODE_ATTRIBUTES;
        *{"${pkg}::MODIFY_CODE_ATTRIBUTES"} = $MODIFY_CODE_ATTRIBUTES;
        *{"${pkg}::_ATTR_CODE_WrapSub"} = $class->can('WrapSub');
        *{"${pkg}::_ATTR_CODE_WrapMethod"} = $class->can('WrapMethod');
    }

    on_scope_end {
        while (my $args = shift @INSTALL_ARGS) {
            $class->_install(@$args);
        }
    };
    return;
}

sub WrapSub :ATTR(CODE,BEGIN) {
    my ($pkg, @args) = @_;

    my $opts = {
        check => $CHECK{$pkg} // $DEFAULT_CHECK,
        skip_invocant => 0,
    };
    push @INSTALL_ARGS => [$opts, $pkg, @args];
    return;
}

sub WrapMethod :ATTR(CODE,BEGIN) {
    my ($pkg, @args) = @_;

    my $opts = {
        check => $CHECK{$pkg} // $DEFAULT_CHECK,
        skip_invocant => 1,
    };
    push @INSTALL_ARGS => [$opts, $pkg, @args];
    return;
}

sub _install {
    my $class = shift;
    my ($options, $pkg, $symbol, $code, $attr, $data) = @_;

    my $typed_code = Sub::WrapInType->new(
        params  => $data->[0],
        isa     => $data->[1],
        code    => $code,
        options => $options,
    );

    if (my @attr = attributes::get($code)) {
        no warnings qw(misc);
        attributes->import($pkg, $typed_code, @attr);
    }

    my $prototype = Sub::Util::prototype($code);
    Sub::Util::set_prototype($prototype, $typed_code);
    Sub::Util::set_subname(Sub::Util::subname($code), $typed_code);

    {
        no strict qw(refs);
        no warnings qw(redefine);
        *$symbol = $typed_code;
    }
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::WrapInType::Attribute - attribute for Sub::WrapInType

=head1 SYNOPSIS

    use Sub::WrapInType::Attribute;
    use Types::Standard -types;

    sub hello :WrapSub([Str] => Str) {
        my $message = shift;
        return "HELLO $message";
    }

    hello('world!!'); # => HELLO world!!
    my $code = \&hello; # => Sub::WrapInType object

=head1 DESCRIPTION

This module provides attribute for Sub::WrapInType, which makes it easier to check during the compilation phase.

=head1 ATTRIBUTES

=head2 :WrapSub(\@parameter_types, $return_type)

The C<:WrapSub> code attribute performs C<Sub::WrapInType#wrap_sub> on the subroutine that specified this attribute.

=head2 :WrapMethod(\@parameter_types, $return_type)

The C<:WrapMethod> code attribute performs C<Sub::WrapInType#wrap_method> on the subroutine that specified this attribute.

=head1 SEE ALSO

L<Sub::WrapInType>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

