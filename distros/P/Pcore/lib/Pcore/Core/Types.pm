package Pcore::Core::Types;

use Pcore;

use Type::Library -base, -declare => qw[ClassNameStr Default FileNameStr PathStr SnakeCaseStr];
use Type::Tiny qw[];               ## no critic qw[Modules::ProhibitEvilModules]
use Types::Standard qw[:types];    ## no critic qw[Modules::ProhibitEvilModules]

*Type::Tiny::TO_DUMP = sub {
    my $self = shift;

    return $self->display_name;
};

*Type::Tiny::TO_JSON = sub {
    my $self = shift;

    return $self->display_name;
};

*Type::Tiny::TO_CBOR = sub {
    my $self = shift;

    return $self->display_name;
};

*Type::Tiny::FREEZE = sub {
    my $self       = shift;
    my $serializer = shift;

    return $self->display_name;
};

*Type::Tiny::THAW = sub {
    my $self       = shift;
    my $serializer = shift;
    my $data       = shift;

    return eval $data || $data;    ## no critic qw[BuiltinFunctions::ProhibitStringyEva]
};

my $meta = __PACKAGE__->meta;

$meta->add_type(
    name       => 'ClassNameStr',
    parent     => Str,
    constraint => sub {
        return /\A[[:upper:]][[:alnum:]:]+\z/sm ? 1 : 0;
    },
    inlined => sub {
        my $constraint = shift;
        my $varname    = shift;

        return sprintf '%s && %s =~ /\A[[:upper:]][[:alnum:]:]+\z/sm', $constraint->parent->inline_check($varname), $varname;
    },
    message => sub {
        return q[Must be a package name string];
    },
);

# TODO params required, must be parametrized with [Type, Default] or [Default]
# $meta->add_type(
#     name       => 'Default',
#     parent     => TODO no parent,
#     constraint => sub {
#         my $default;
#         my $test;
#
#         if ( $_[1]->@* > 1 ) {
#             $default = $_[1]->[1];
#             $test    = $_[1]->[0];
#         }
#         else {
#             $default = $_[1]->[0];
#         }
#
#         my $is_array = ref $_[0]->[0] eq 'ARRAY' ? 1 : 0;
#         my $exists = $is_array ? exists $_[0]->[0]->[ $_[0]->[1] ] : exists $_[0]->[0]->{ $_[0]->[1] };
#
#         if ( !$exists ) {
#             return if $test && !$test->is_valid($default);    # TODO check, that default value passed type constraint in compilation phase
#
#             if ($is_array) {
#                 $_[0]->[0]->[ $_[0]->[1] ] = $default;
#             }
#             else {
#                 $_[0]->[0]->{ $_[0]->[1] } = $default;
#             }
#         }
#         elsif ($test) {
#             if ($is_array) {
#                 return $test->is_valid( $_[0]->[0]->[ $_[0]->[1] ] );
#             }
#             else {
#                 return $test->is_valid( $_[0]->[0]->{ $_[0]->[1] } );
#             }
#         }
#
#         return 1;
#     },
#     inlined => sub { },
#     message => sub {q[Must be a ]},
# );

$meta->add_type(
    name       => 'FileNameStr',
    parent     => Str,
    constraint => sub {
        return m{\A[^/\\?%*:|"><(){}[\]!#\$\@&\^\$,]+\z}sm ? 1 : 0;
    },
    inlined => sub {
        my $constraint = shift;
        my $varname    = shift;

        return sprintf '%s && %s =~ m{\A[^/\\?%%*:|"><(){}[\]!#\$\@&\^\$,]+\z}sm', $constraint->parent->inline_check($varname), $varname;
    },
    message => sub {
        return q[Must be a valid filename];
    },
);

$meta->add_type(
    name       => 'PathStr',
    parent     => Str,
    constraint => sub {
        return /\A[^\\?%*:|"><(){}[\]!#\$\@&\^\$,]+\z/sm ? 1 : 0;
    },
    inlined => sub {
        my $constraint = shift;
        my $varname    = shift;

        return sprintf '%s && %s =~ /\A[^\\?%%*:|"><(){}[\]!#\$\@&\^\$,]+\z/sm', $constraint->parent->inline_check($varname), $varname;
    },
    message => sub {
        return q[Must be a valid path];
    },
);

$meta->add_type(
    name       => 'SnakeCaseStr',
    parent     => Str,
    constraint => sub {
        return /\A[^_][[:lower:][:digit:]_]+\z/sm ? 1 : 0;
    },
    inlined => sub {
        my $constraint = shift;
        my $varname    = shift;

        return sprintf '%s && %s =~ /\A[^_][[:lower:][:digit:]_]+\z/sm', $constraint->parent->inline_check($varname), $varname;
    },
    message => sub {
        return q[Must be a valid snake_case string];
    },
);

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 115, 132             | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Types

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
