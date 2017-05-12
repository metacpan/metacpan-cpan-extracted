use 5.008;
use strict;
use warnings;
use utf8;

package Path::IsDev::HeuristicSet::Basic;

our $VERSION = '1.001003';

# ABSTRACT: Basic IsDev set of Heuristics

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Role::Tiny::With qw( with );
with 'Path::IsDev::Role::HeuristicSet::Simple';

















sub negative_heuristics {
  return qw( IsDev::IgnoreFile HomeDir PerlINC );
}































sub heuristics {
  return qw(
    Tool::Dzil Tool::MakeMaker Tool::ModuleBuild
    META Changelog TestDir DevDirMarker MYMETA Makefile
    VCS::Git
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::HeuristicSet::Basic - Basic IsDev set of Heuristics

=head1 VERSION

version 1.001003

=head1 METHODS

=head2 C<negative_heuristics>

Excluding heuristics in this set are

=over 4

=item 1. L<< C<IsDev::IgnoreFile>|Path::IsDev::NegativeHeuristic::IsDev::IgnoreFile >>

=item 2. L<< C<HomeDir>|Path::IsDev::NegativeHeuristic::HomeDir >>

=item 3. L<< C<PerlINC>|Path::IsDev::NegativeHeuristic::PerlINC >>

=back

=head2 C<heuristics>

Heuristics included in this set:

=over 4

=item 1. L<< C<Tool::Dzil>|Path::IsDev::Heuristic::Tool::Dzil >>

=item 2. L<< C<Tool::MakeMaker>|Path::IsDev::Heuristic::Tool::MakeMaker >>

=item 3. L<< C<Tool::ModuleBuild>|Path::IsDev::Heuristic::Tool::ModuleBuild >>

=item 4. L<< C<META>|Path::IsDev::Heuristic::META >>

=item 5. L<< C<Changelog>|Path::IsDev::Heuristic::Changelog >>

=item 6. L<< C<TestDir>|Path::IsDev::Heuristic::TestDir >>

=item 7. L<< C<DevDirMarker>|Path::IsDev::Heuristic::DevDirMarker >>

=item 8. L<< C<MYMETA>|Path::IsDev::Heuristic::MYMETA >>

=item 9. L<< C<Makefile>|Path::IsDev::Heuristic::Makefile >>

=item 10. L<< C<VCS::Git>|Path::IsDev::Heuristic::VCS::Git >>

=back

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::HeuristicSet::Basic",
    "interface":"single_class",
    "does":"Path::IsDev::Role::HeuristicSet::Simple"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
