use strict;
use warnings;
use Module::Build;
use lib 'inc';
use File::Find qw[find];
$|++;
my $automated_testing = $ENV{'AUTOMATED_TESTING'}
    || $ENV{'PERL_MM_USE_DEFAULT'};
my @tests;
my $is_developer = ((-d '.git') ? 1 : 0) or ($ENV{'RELEASE_TESTING'} ? 1 : 0);
find \&find_cb, qw[t/0100_filters t/0200_tags],
    ($is_developer ? 't/9000_author' : ());
my $mb = Module::Build->new(
              module_name    => 'Solution',
              license        => 'artistic_2',
              dist_author    => 'Sanko Robinson <sanko@cpan.org>',
              dist_abstract  => 'A Simple, Stateless Template System',
              requires       => {perl => 5.006001, 'File::Spec' => 0},
              build_requires => {'File::Find'    => 0,
                                 'File::Spec'    => 0,
                                 'Module::Build' => 0.4,
                                 perl            => 5.006001,
                                 'Test::More'    => '0.94',
                                 ($is_developer ?
                                      ('CPAN::Meta::Converter' => 0,
                                       'CPAN::Meta::Validator' => 0,
                                       JSON                    => 0,
                                       'Perl::Tidy'            => 0
                                      )
                                  : ()
                                 ),
              },
              configure_requires => {'Module::Build' => 0.4},
              add_to_cleanup     => [qw[Solution-*]],
              no_index           => {directory       => [qw[examples inc t]]},
              test_files         => \@tests,
              test_file_exts     => ['.t'],
              use_tap_harness    => 1,
              tap_harness_args   => {
                                   jobs  => 9,
                                   rules => {par => ['*']}
              },
              meta_merge => {
                  keywords => [qw[Liquid Template Engine Solution stateless]],
                  resources => {
                      bugtracker => 'http://github.com/sanko/solution/issues',
                      repository => 'git://github.com/sanko/solution.git',
                      ChangeLog => 'http://github.com/sanko/solution/commits/'
                  }
              }
);
$mb->notes(automated_testing => $automated_testing ? 1 : 0);
$mb->notes(is_developer      => $is_developer      ? 1 : 0);
$mb->notes(test_suite        => \@tests);
$mb->notes(gmtime            => scalar gmtime);
$mb->create_build_script;
exit 0;

sub find_cb {
    return if -d $_ or -l $_;
    return unless -T $_;
    return unless $_ =~ m[.+\.t$];
    return push @tests, $File::Find::name;
}
