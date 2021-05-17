package SVG::Estimate::Role::EndToPoint;
$SVG::Estimate::Role::EndToPoint::VERSION = '1.0116';
use strict;
use Moo::Role;

=head1 NAME

SVG::Estimate::Role::EndToPoint - Change arguments from "end" to "point", mainly for Path command objects

=head1 VERSION

version 1.0116

=cut

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args = @args % 2 ? $args[0] : { @args };
    $args->{point} = $args->{end};
    return $class->$orig($args);
};


1;
