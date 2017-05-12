package Module::Checkstyle::Problem;

use strict;
use warnings;

use overload q{""} => \&as_string;

sub new {
    my ($class, $severity, $message, $line, $file) = @_;
    
    $class = ref $class || $class;
    if (defined $line && ref $line) {
        if (UNIVERSAL::isa($line, 'PPI::Element')) {
            $line = $line->location();
        }
                # Assume this is comming from a PPI::Element->location();
        if (ref $line eq 'ARRAY') {
            $line = $line->[0];
        }
    }

    my $self = bless [ $severity, $message, $line, $file ], $class;
    return $self;
}

sub as_string {
    my $self = shift;

    my $str = q{};
    if (defined $self->[0]) {
        $str .= uc("[$self->[0]] ");
    }

    if (defined $self->[1]) {
        $str .= $self->[1];
    }
    
    if (defined $self->[2]) {
        $str .= " at line $self->[2]";
    }
    if (defined $self->[3]) {
        $str .= " in $self->[3]";
    }

    return $str;
}

sub get_severity {
    return $_[0]->[0];
}

sub get_message {
    return $_[0]->[1];
}

sub get_line {
    return $_[0]->[2];
}

sub get_file {
    return $_[0]->[3];
}

1;
__END__
=head1 NAME

Module::Checkstyle::Problem - Represents a checkstyle violation

=head1 SYNOPSIS

    use Module::Checkstyle::Problem;

    my $problem = Module::Checkstyle::Problem->new('warn',
                                                   q(bad variable name '$java'),
                                                   40,
                                                   'my_script.pl');

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new ($severity, $message, $line, $file)

Constructs a new C<Module::Checkstyle::Problem> object. C<$severity> should be
any of B<error> or B<warn> but others may be specified. C<$message> should be
a description of the violated check. C<$line> may either be a scalar or a
reference to an array where it will use the first element as line. C<$file> should
be the path to the file that violates the check.

=item get_severity

Returns the severity of the problem.

=item get_message

Returns the description of the problem.

=item get_line

Returns the line where the problem was found.

=item get_file

Returns the file that caused the problem.

=item as_string

Returns a stringified message combining severity, message, line and file if
they are present.

=back

=head1 SEE ALSO

L<Module::Checkstyle>

=cut
