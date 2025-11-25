#!perl
# PODNAME: Perl::Critic::Policy::BuiltinFunctions::ProhibitForeach
# ABSTRACT: Prohibit foreach keyword


use strict;
use warnings;

package Perl::Critic::Policy::BuiltinFunctions::ProhibitForeach;
$Perl::Critic::Policy::BuiltinFunctions::ProhibitForeach::VERSION = '0.01';
use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use constant DESC => '"foreach" used';
use constant EXPL => 'This codebase uses "for" rather than "foreach"';

sub applies_to           { return 'PPI::Token::Word' }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return () }
sub supported_parameters { return () }

sub violates {
    my ($self, $elem) = @_;
    return () unless $elem eq 'foreach';
    return $self->violation(DESC, EXPL, $elem);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitForeach - Prohibit foreach keyword

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This policy prohibits the use of the C<foreach> keyword in favour of the C<for> keyword.

Apply this policy in your code base for the sake of consistency. There can only be one!

 foreach my $foo (1..10) { # not ok
 for my $foo (1..10) {     # ok

You may also experience additional benefits including screen space savings, reduced storage, saved bandwidth,
reduced carbon emissions, less greenhouse gases, increased muscle mass, improved blood pressure, etc. you
may even get a promotion and gain greater charisma.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 SEE ALSO

L<Perl::Critic>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
