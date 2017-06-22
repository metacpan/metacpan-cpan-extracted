use strict;
use warnings;
no warnings 'once';

use Test::More 0.88;
use Module::Reader qw(:all);
use lib 't/lib';
use InlineModule;

BEGIN {
  *_HAS_PERLIO = "$]" >= 5.008_000 ? sub(){1} : sub(){0};
}

my $mod_content = do {
  open my $fh, (_HAS_PERLIO ? '<:' : '<'), 't/test-data/lib/MyTestModule.pm';
  local $/;
  <$fh>;
};

{
  local @INC = (
    InlineModule::inc_hook('MyTestModule' => $mod_content),
    @INC,
  );
  is module_content('MyTestModule'), $mod_content,
    'correctly load module from sub @INC hook';
  require MyTestModule;
  SKIP: {
    skip 'found option doesn\'t work with @INC hooks in perl < 5.8', 2
      if "$]" < 5.008;
    local @INC = @INC;
    my $content = '1;';
    unshift @INC, InlineModule::inc_hook( MyTestModule => $content );
    is module_content('MyTestModule'), '1;',
      'loads overridden module from sub @INC hook';
    is module_content('MyTestModule', { found => \%INC } ), $mod_content,
      'found => \%INC loads mod as it was required';
  }
  {
    local $TODO = "unable to accurately calculate fake filename on perl 5.6"
      if "$]" < 5.008;
    is +Module::Reader->new->module('MyTestModule')->found_file, $MyTestModule::FILENAME,
      'calculated file matches loaded filename';
  }
}

sub ParentHook::INC {
  die "hook\n";
}
@ChildHook::ISA = qw(ParentHook);

{
  my $base_hook = InlineModule::inc_hook( MyTestModule => $mod_content );
  for my $fake_hook (
    ['hook returning an array ref' => sub { return [] }],
    ['hook returning a hash ref' => sub { return {} }],
  ) {
    my $name = $fake_hook->[0];
    my @inc = ($fake_hook->[1], $base_hook);
    is module_content('MyTestModule', { inc => \@inc }), $mod_content,
      "$name is ignored";
  }
}

sub main::stringy_sub { return }
sub FQ::stringy_sub { return }

{
  my $uniq = 0;
  for my $hook (
    ['hash ref'                 => {}],
    ['scalar ref'               => \(my $s)],
    ['regex'                    => qr/\./],
    ['class without INC'        => bless {}, 'NonHook'],
    ['class with INC hook'      => bless {}, 'ParentHook'],
    ['child class of INC hook'  => bless {}, 'ChildHook'],
    ['array ref without code'   => []],
    ['array ref with string'    => ["welp"]],
    ['array ref with stringy main sub' => ["stringy_sub"]],
    ['array ref with stringy fully qualified sub' => ["FQ::stringy_sub"]],
    ['array ref with hash ref'  => [{}]],
    ['array ref with code'      => [sub { return }]],
  ) {
    my $class = 'MyTestModule'.++$uniq;
    my $name = $hook->[0];
    my @inc = ($hook->[1], sub { return unless $_[1] eq "$class.pm"; inc_module($mod_content) });
    eval {
      local @INC = @inc;
      no warnings 'uninitialized';
      require "$class.pm";
    };
    (my $req_e = $@) =~ s/ at .*//s;
    undef $req_e if $req_e eq "hook\n";
    eval {
      module_content($class, { inc => \@inc });
    };
    (my $e = $@) =~ s/ at .*//s;
    undef $e if $e eq "hook\n";
    is $e, $req_e,
      $name . ($req_e ? ' fails' :' works') . ' the same as require';
  }
}

done_testing;
