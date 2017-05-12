package Module::Checkstyle::Util;

use strict;
use warnings;

use Carp qw(croak);

use Module::Checkstyle::Problem;

require Exporter;

our @ISA         = qw(Exporter);

our @EXPORT      = qw();
our @EXPORT_OK   = qw(format_expected_err new_problem as_true as_numeric as_regexp is_valid_position is_valid_align);
our %EXPORT_TAGS = ( all     => [@EXPORT_OK],
                     problem => [qw(format_expected_err new_problem)],
                     args    => [qw(as_true as_numeric as_regexp is_valid_position is_valid_align)],
                );

sub format_expected_err {
    my ($expected, $got) = @_;
    
    $expected = ref $expected || $expected;
    $got      = ref $got      || $got;

    $expected = q{} if !defined $expected;
    $got      = q{} if !defined $got;
    
    return qq(Expected '$expected' but got '$got');
}

sub new_problem {
    my $problem;

    if (@_ == 4) {
        $problem = Module::Checkstyle::Problem->new(@_);
    }
    elsif (@_ == 5) {
        my ($config, $directive, $message, $line, $file) = @_;
        my $severity;

        my ($caller) = caller =~ /^Module::Checkstyle::Check::(.*)$/;
        if ($caller) {
            $severity = $config->get_severity($caller, $directive);
        }
        else {
            $severity = $config->get_severity('_', 'global-error-level');
        }

        $problem = Module::Checkstyle::Problem->new($severity, $message, $line, $file);
    }
    else {
        croak "Module::Checkstyle::Util::new_problem() called with wrong number of arguments";
    }
    
    return $problem;
}

sub as_true {
    my $value = shift;
    return 0 if !defined $value || !$value;
    return 1 if $value =~ m/^ y | yes | true | 1 $/xi;
    return 0;
}

sub as_numeric {
    my $value = shift;

    return 0       if !defined $value || !$value;
    return $value  if $value =~ /^\-?\d+$/;
    return 0;
}

sub as_regexp {
    my $value = shift;
    return undef if !defined $value;
    return undef if $value =~ /^\s*$/;

    if ($value !~ /^qr/) {
        $value = 'qr' . $value;
    }
    
    my $re = eval $value;
    return undef if $@;
    return $re;
}

sub is_valid_position {
    my $value = shift || "";
    return $value =~ /^same|alone$/i ? 1 : 0;
}


sub is_valid_align {
    my $value = shift || "";
    return $value =~ /^left|middle|right$/i ? 1 : 0
}

1;
__END__

=head1 NAME

Module::Checkstyle::Util - Convenient functions for checks

=head1 SUBROUTINES

=over 4

=item format_expected_err ($expected, $got)

Return the string "Expected '$expected' but got '$got'" but with C<$expected> and C<$got> reduced to
the reftype if they are references.

=item new_problem ($config, $directive, $message, $line, $file)

Creates a new C<Module::Checkstyle::Problem> object. C<$config> must be a C<Module::Checkstyle::Config> object which will be used 
togther will the caller and C<$directive> to determine severity. C<$line> can be either a C<PPI::Element> object, an array
reference or a scalar. If it is an array reference the 0-elementwill be used as line.

=item new_problem ($severity, $message, $line, $file)

Creates a new C<Module::Checkstyle::Problem> object with the given severity, message, line and file.

=item as_true ($value)

Returns 1 if C<$value> is either "y", "yes", "true" or "1" not regarding case. All other value returns 0.

=item as_numeric ($value)

Returns the numeric value given in C<$value> if it is integer-numeric with an optional minus-sign. All other values returns 0.

=item as_regexp ($value)

Returns a regular expression object that will match what's given in C<$value>. If it creation of the regexp-object was unsuccessfull it will return undefined.

=item is_valid_position ($value)

Returns a true value if the string C<$value> equals a valid position property. These are B<same> and B<alone>.

=item is_valid_align ($value)

Returns a true value if the string C<$value> equals a valid alignment property. These are B<left>, B<middle> and B<right>.

=back

=head1 SEE ALSO

L<Module::Checkstyle>

=cut

