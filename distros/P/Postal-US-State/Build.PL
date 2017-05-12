
use strict;
use warnings;
use Module::Build;
my $build_class = Module::Build->subclass(code => q{
  sub ACTION_build {
    my $self = shift;

    my $abbr = 'abbr_state.txt';
    my $pm = 'lib/Postal/US/State.pm';
    if(-e $abbr and not $self->up_to_date($abbr, $pm)) {
      require File::Fu;
      $self->log_info("Rebuilding from $abbr data.\n");
      my $fh = File::Fu->file($abbr)->open;
      my @data;
      while(my $line = <$fh>) {
        chomp($line);
        $line =~ s/\s+([A-Z]{2})$// or next;
        my $code = $1;
        $line = lc($line);

        $line =~ s/\b(.)/\U$1\E/g;
        $line =~ s/\bOf\b/of/g;

        push(@data, [$code, $line]);
      }

      $pm = File::Fu->file($pm);
      my $code = $pm->read;
      my ($s, $e) = ('### STATES REGEN {{{', '### STATES REGEN }}}');
      my $string = join("\n", map({"  $_->[0] => '$_->[1]',"} @data));
      $code =~ s/$s.*$e/$s\n$string\n$e/s or die "replace fail";
      $pm->write($code);
    }

    $self->SUPER::ACTION_build(@_);
  }
});

my $builder = $build_class->new(
  module_name         => 'Postal::US::State',
  license             => 'perl',
  requires => {
  },
  build_requires => {
    'Module::Build' => 0.34,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Postal-US-State-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Postal-US-State',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Postal-US-State/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
