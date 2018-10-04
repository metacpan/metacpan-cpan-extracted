package Test::CPANfile;

use strict;
use warnings;
use Exporter 5.57 'import';
use Module::CPANfile;
use Perl::PrereqScanner::NotQuiteLite::App;
use Test::More;

our $VERSION = '0.02';
our @EXPORT = qw/cpanfile_has_all_used_modules/;

my %Phases = (
  runtime   => [qw/runtime/],
  build     => [qw/runtime build/],
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

  my $index = $args{index};
  my %uri_cache;
  for my $phase (sort $prereqs->phases) {
    for my $type (sort $prereqs->types_in($phase)) {
      my $req = $prereqs->requirements_for($phase, $type);
      my $declared_req = $declared->merged_requirements($Phases{$phase}, $Types{$type});

      my %uri_map;
      if ($index) {
        for my $module ($declared_req->required_modules) {
          next if $module eq 'perl';
          my $uri = $uri_cache{$module} ||= do {
            my $res = $index->search_packages({ package => $module });
            $res ? $res->{uri} : undef;
          };
          $uri_map{$uri} = $module if $uri;
        }
      }

      for my $module (sort $req->required_modules) {
        my $required_version = $req->requirements_for_module($module);
        my $declared_version = $declared_req->requirements_for_module($module);
        if ($required_version and $required_version =~ /^[0-9._]+$/) {
          ok((defined $declared_version and $req->accepts_module($module, $required_version)),
            sprintf "$module %s ($phase $type) is declared and satisfies minimum version (%s)",
              $required_version || 0, $declared_version || 0
          );
        } elsif (defined $declared_version) {
          pass "$module ($phase $type) is declared";
        } else {
          my $uri;
          if ($index) {
            $uri = $uri_cache{$module} ||= do {
              my $res = $index->search_packages({ package => $module });
              $res ? $res->{uri} : undef;
            };
          }
          ok($uri && $uri_map{$uri}, "$module ($phase $type) is declared (as $uri_map{$uri})");
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

    # By default, this module tests if cpanfile has all the used modules.
    use Test::CPANfile;
    use Test::More;
    
    cpanfile_has_all_used_modules();
    done_testing;

    # You can use an optional CPAN package index to see if
    # a sibling of a used-but-not-listed-in-cpanfile module
    # is listed.
    use Test::CPANfile;
    use Test::More;
    use CPAN::Common::Index::Mirror;
    
    my $index = CPAN::Common::Index::Mirror->new;
    
    cpanfile_has_all_used_modules(
        parser => [qw/:installed/],
        index  => $index,
    );
    done_testing;

=head1 DESCRIPTION

This module tests if cpanfile lists every C<use>d modules or not.

It's ok if you list a module that is C<eval>ed in the code, or a module that does not appear in the code, as C<requires>, but it complains if a C<use>d module is listed as C<recommends> or C<suggests>.

=head1 FUNCTION

=head2 cpanfile_has_all_used_modules()

You can pass an optional hash, which is passed to L<Perl::PrereqScanner::NotQuiteLite::App>'s constructor to change its behavior.

=head3 CPAN::Common::Index support

If you pass an optional L<CPAN::Common::Index> instance (as the second example above), it is used to find a distribution that contains a C<used> module. The test for the module passes if one of the modules that the distribution contains is listed in the cpanfile, even when the C<used> module itself is not listed.

=head1 SEE ALSO

L<Perl::PrereqScanner::NotQuiteLite>, L<CPAN::Common::Index>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
