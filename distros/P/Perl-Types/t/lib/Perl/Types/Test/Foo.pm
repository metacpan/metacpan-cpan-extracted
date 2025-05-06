# [[[ HEADER ]]]
package Perl::Types::Test::Foo;
use strict;
use warnings;
our $VERSION = 0.006_000;
use Perl::Types;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Class);
use Perl::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants
## no critic qw(ProhibitAutomaticExportation)  # SYSTEM SPECIAL 14: allow global exports from Config.pm & elsewhere

# [[[ EXPORTS ]]]
use Exporter qw(import);
our @EXPORT    = qw(tnurg tluarg);
our @EXPORT_OK = qw(ylprag ecrog quux quince qorge);

# DEV NOTE: below this line copied from Perl::Class::Template
# [[[ CONSTANTS ]]]
use constant PI  => my number $TYPED_PI  = 3.141_59;
use constant PIE => my string $TYPED_PIE = 'pecan';

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    plugh => my integer $TYPED_plugh         = 23,
    xyzzy => my string $TYPED_xyzzy          = 'twenty-three',
    thud  => my arrayref::integer $TYPED_thud = [ 2, 4, 6, 8 ],
    yyz => my hashref::number $TYPED_yyz = { a => 3.1, b => 6.2, c => 9.3 }
};

# [[[ SUBROUTINES & OO METHODS ]]]

sub quux {
    { my void::method $RETURN_TYPE };
    ( my object $self) = @ARG;
    $self->{plugh} = $self->{plugh} + 2;
    $self->{plugh} = $self->{plugh} - 3;
    $self->{plugh} = $self->{plugh} * 4;  # ensure integer outcome
    $self->{plugh} = $self->{plugh} / 2;  # ensure integer outcome
    $self->{plugh} = $self->{plugh} % 5;
    $self->{plugh} = -($self->{plugh});
    $self->{plugh}++;
    $self->{plugh}--;
    return;
}

sub quince {
    { my integer::method $RETURN_TYPE };
    my string $quince_def
        = '...Cydonia vulgaris ... Cydonia, a city in Crete ... [1913 Webster]';
    print $quince_def;
    return (length $quince_def);
}

sub qorge {
    { my hashref::string::method $RETURN_TYPE };
    ( my object $self, my integer $qorge_input ) = @ARG;
    return {
        a => $self->{xyzzy} x $qorge_input,
        b => 'howdy',
        c => q{-23.42}
    };
}

sub qaft {
    { my Perl::Types::Test::Foo_arrayref::method $RETURN_TYPE };
    ( my object $self, my integer $foo, my number $bar, my string $bat, my hashref::string $baz ) = @ARG;
    my Perl::Types::Test::Foo_arrayref $retval = [];
    $retval->[0] = Perl::Types::Test::Foo->new();
    $retval->[0]->{xyzzy} = 'larry';
    $retval->[1] = Perl::Types::Test::Foo->new();
    $retval->[1]->{xyzzy} = 'curly';
    $retval->[2] = Perl::Types::Test::Foo->new();
    $retval->[2]->{xyzzy} = 'moe';
    return $retval;
}

sub tnurg {
    { my void $RETURN_TYPE };
    print 'PIE() = ' . PIE() . "\n";
    return;
}

sub tluarg {
    { my number $RETURN_TYPE };
    ( my integer $tluarg_input ) = @ARG;
    $tluarg_input++;
    $tluarg_input--;
    $tluarg_input = $tluarg_input**2;
    return $tluarg_input**PI();
}

sub ylprag {
    { my arrayref::number $RETURN_TYPE };
    ( my integer $ylprag_input, my arrayref::number $ylprag_array ) = @ARG;
    my integer $ylprag_input_size = scalar @{$ylprag_array};
    my integer $unylprag_size_typed = scalar @{my arrayref::integer $TYPED_unylprag = [4, 6, 8, 10]};
#    my integer $unylprag_size_untyped = scalar @{[4, 6, 8, 10]};  missing type_inner, not supported in CPPOPS_CPPTYPES
    my arrayref::number $ylprag_output = [
        $ylprag_input * $ylprag_array->[0],
        $ylprag_input * $ylprag_array->[1],
        $ylprag_input * $ylprag_array->[2]
    ];
    return $ylprag_output;
}

sub ecrog {
    { my hashref::string $RETURN_TYPE };
    ( my integer $al, my number $be, my string $ga, my hashref::string $de)
        = @ARG;
    return {
        alpha => integer_to_string($al),
        beta  => number_to_string($be),
        gamma => $ga,
        delta => %{$de}
    };
}

1;    # end of class
