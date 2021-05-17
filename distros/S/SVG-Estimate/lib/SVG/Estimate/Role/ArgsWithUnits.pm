package SVG::Estimate::Role::ArgsWithUnits;
$SVG::Estimate::Role::ArgsWithUnits::VERSION = '1.0116';
use strict;
use Moo::Role;
use Ouch;

=head1 NAME

SVG::Estimate::Role::ArgsWithUnits - Validate a list of arguments that could contain units

=head1 VERSION

version 1.0116

=head1 METHODS

=head2 BUILDARGS ( )

Validate the set of args from the class's C<args_with_units> method to make sure they don't have units

=cut

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my @args = @_;
    my $args = @args % 2 ? $args[0] : { @args };
    foreach my $param ($class->args_with_units) {
        if ($args->{$param} =~ /\d\D+$/) {
            ouch 'units detected', "$param is not allowed to have units", $args->{$param};
        }
    }
    ##Validate before the arguments are used
    return $class->$orig($args);
};


1;
