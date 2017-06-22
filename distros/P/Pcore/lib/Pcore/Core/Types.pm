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
