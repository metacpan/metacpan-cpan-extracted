package Test::CPANfile;

use strict;
use warnings;
use Exporter 5.57 'import';
use Module::CPANfile;
use Perl::PrereqScanner::NotQuiteLite::App;
use Test::More;

our $VERSION = '0.01';
our @EXPORT = qw/cpanfile_has_all_used_modules/;

my %Phases = (
  runtime   => [qw/runtime/],
  test      => [qw/runtime build test/],
  configure => [qw/configure/],
);
my %Types = (
  requires   => [qw/requires/],
  recommends => [qw/requires recommends/],
  suggests   => [qw/requires recommends suggests/],
);

sub cpanfile_has_all_used_modules {
  my %args = @_;

  my $cpanfile = delete $args{cpanfile} || 'cpanfile';
  plan skip_all => "$cpanfile is not found" if !-f $cpanfile;

  my $declared = _load_cpanfile($cpanfile);

  my $scanner = Perl::PrereqScanner::NotQuiteLite::App->new(
    parsers  => [':installed'],
    exclude_core => 1,
    %args,
    print => 0,
  );

  my $prereqs = $scanner->run;

  for my $phase (sort $prereqs->phases) {
    for my $type (sort $prereqs->types_in($phase)) {
      my $req = $prereqs->requirements_for($phase, $type);
      my $declared_req = $declared->merged_requirements($Phases{$phase}, $Types{$type});
      for my $module (sort $req->required_modules) {
        my $required_version = $req->requirements_for_module($module) || 0;
        if ($required_version and $required_version =~ /^[0-9._]+$/) {
          my $declared_version = $declared_req->requirements_for_module($module) || 0;
          ok((defined $declared_req->requirements_for_module($module) and $req->accepts_module($module, $required_version)), "$module $required_version ($phase $type) is declared and satisfies minimum version ($declared_version)");
        } else {
          ok(defined $declared_req->requirements_for_module($module), "$module ($phase $type) is declared");
        }
      }
    }
  }
}

sub _load_cpanfile {
  my $file = shift;
  my $data = Module::CPANfile->load($file);
  my $prereqs = $data->prereqs;
  for my $feature ($data->features) {
    $prereqs = $prereqs->with_merged_prereqs($feature->prereqs);
  }
  $prereqs;
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::CPANfile - see if cpanfile lists every used modules

=head1 SYNOPSIS

    use Test::CPANfile;
    use Test::More;
    
    cpanfile_has_all_used_modules();
    done_testing;

=head1 DESCRIPTION

This module tests if cpanfile lists every C<use>d modules or not.

It's ok if you list a module that is C<eval>ed in the code, or a module that does not appear in the code, as C<requires>, but it complains if C<use>d module is listed as C<recommends> or C<suggests>.

=head1 FUNCTION

=head2 cpanfile_has_all_used_modules()

You can pass an optional hash, which is passed to L<Perl::PrereqScanner::NotQuiteLite::App>'s constructer to change its behavior.

=head1 SEE ALSO

L<Perl::PrereqScanner::NotQuiteLite>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
