package TAP::Spec::Plan;
BEGIN {
  $TAP::Spec::Plan::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::Plan::VERSION = '0.10';
}
# ABSTRACT: A TAP test plan
use Mouse;
use namespace::autoclean;

use TAP::Spec::Plan::Simple ();
use TAP::Spec::Plan::Todo ();
use TAP::Spec::Plan::SkipAll ();

# Nothing here yet.

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

TAP::Spec::Plan - A TAP test plan

=head1 VERSION

version 0.10

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
