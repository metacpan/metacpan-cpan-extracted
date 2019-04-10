use utf8;

package SemanticWeb::Schema::MotorizedBicycle;

# ABSTRACT: A motorized bicycle is a bicycle with an attached motor used to power the vehicle

use Moo;

extends qw/ SemanticWeb::Schema::Vehicle /;


use MooX::JSON_LD 'MotorizedBicycle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MotorizedBicycle - A motorized bicycle is a bicycle with an attached motor used to power the vehicle

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A motorized bicycle is a bicycle with an attached motor used to power the
vehicle, or to assist with pedaling.

=head1 SEE ALSO

L<SemanticWeb::Schema::Vehicle>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
