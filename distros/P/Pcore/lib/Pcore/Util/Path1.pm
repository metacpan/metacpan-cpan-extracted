package Pcore::Util::Path1;

use Pcore -class, -const, -res;
use Clone qw[];
use Cwd qw[];    ## no critic qw[Modules::ProhibitEvilModules]

use overload
  q[""]    => sub { $_[0]->{to_string} },
  fallback => 1;

with qw[
  Pcore::Util::Result::Status
  Pcore::Util::Path1::Dir
  Pcore::Util::Path1::Poll
];

has to_string => ();
has is_abs    => ();
has volume    => ();

has IS_PATH => ( 1, init_arg => undef );

around new => sub ( $orig, $self, $path ) {
    $path = "$path";

    $self = bless { to_string => $path }, __PACKAGE__;

    if ($MSWIN) {
        if ( $path =~ /\A([a-z]):/smi ) {
            $self->{volume} = lc $1;
            $self->{is_abs} = 1;
        }
    }
    else {
        if ( substr( $path, 0, 1 ) eq '/' ) {
            $self->{is_abs} = 1;
        }
    }

    return $self;
};

sub clone ($self) {
    return Clone::clone($self);
}

sub to_abs ( $self, $base = undef ) {

    # path is already absolute
    return defined wantarray ? $self->clone : () if $self->{is_abs};

    if ( !defined $base ) {
        $base = Cwd::getcwd();
    }
    else {
        $base = $self->new($base)->to_abs->{to_string};
    }

    if ( defined wantarray ) {
        return $self->new("$base/$self->{to_string}");
    }
    else {
        $self->{to_string} = "$base/$self->{to_string}";
    }

    return;
}

# sub TO_DUMP {
#     my $self = shift;

#     my $res;
#     my $tags;

#     $res = qq[path: "$self->{to_string}"];

#     # $res .= qq[\nMIME type: "] . $self->mime_type . q["] if $self->mime_type;

#     return $res, $tags;
# }

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 29                   | RegularExpressions::ProhibitEnumeratedClasses - Use named character classes ([a-z] vs. [[:lower:]])            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path1

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
