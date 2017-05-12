use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::NegativeHeuristic::PerlINC;

our $VERSION = '1.001003';

# ABSTRACT: White-list paths in Config.pm as being non-development roots.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

## no critic (RequireArgUnpacking, ProhibitSubroutinePrototypes)
sub _uniq (@) {
  my %seen = ();
  return grep { not $seen{$_}++ } @_;
}
















use Role::Tiny::With qw( with );
use Config;

with 'Path::IsDev::Role::NegativeHeuristic', 'Path::IsDev::Role::Matcher::FullPath::Is::Any';









sub paths {
  my @sources;
  push @sources, $Config{archlibexp}, $Config{privlibexp}, $Config{sitelibexp}, $Config{vendorlibexp};
  return _uniq grep { defined and length } @sources;
}







sub excludes {
  my ( $self, $result_object ) = @_;

  return unless $self->fullpath_is_any( $result_object, $self->paths );
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::NegativeHeuristic::PerlINC - White-list paths in Config.pm as being non-development roots.

=head1 VERSION

version 1.001003

=head1 METHODS

=head2 C<paths>

Returns a unique list comprised of all the C<*exp> library paths from L<< C<Config.pm>|Config >>

    uniq grep { defined and length } $Config{archlibexp}, $Config{privlibexp}, $Config{sitelibexp}, $Config{vendorlibexp};

=head2 C<excludes>

Excludes a path if its full path is any of C<paths>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::NegativeHeuristic::PerlINC",
    "interface":"single_class",
    "does": [
        "Path::IsDev::Role::NegativeHeuristic",
        "Path::IsDev::Role::Matcher::FullPath::Is::Any"
    ]
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
