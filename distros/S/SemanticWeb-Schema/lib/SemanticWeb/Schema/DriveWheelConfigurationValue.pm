use utf8;

package SemanticWeb::Schema::DriveWheelConfigurationValue;

# ABSTRACT: A value indicating which roadwheels will receive torque.

use Moo;

extends qw/ SemanticWeb::Schema::QualitativeValue /;


use MooX::JSON_LD 'DriveWheelConfigurationValue';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DriveWheelConfigurationValue - A value indicating which roadwheels will receive torque.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A value indicating which roadwheels will receive torque.

=head1 SEE ALSO

L<SemanticWeb::Schema::QualitativeValue>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
