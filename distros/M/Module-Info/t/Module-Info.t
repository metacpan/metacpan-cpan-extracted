#!/usr/bin/perl -w

use lib qw(t/lib);
use Test::More tests => 59;
use Config;

my $has_version_pm = eval 'use version; 1';
my $version_pm_VERSION = $has_version_pm ? 'version'->VERSION : 0;
my $Mod_Info_VERSION = '0.37';
# 0.280 vith version.pm, 0.28 without, except for development versions
my $Mod_Info_Pack_VERSION = !$has_version_pm             ? '0.37' :   # 0.3101
         $has_version_pm && $version_pm_VERSION > '0.72' ? '0.37' :   # 0.3101
                                                           '0.37';  # 0.310001

my @old5lib = defined $ENV{PERL5LIB} ? ($ENV{PERL5LIB}) : ();
$ENV{PERL5LIB} = join $Config{path_sep}, 'blib/lib', @old5lib;

use_ok('Module::Info');
my @expected_subs = qw(
                       new_from_file
                       new_from_module
                       new_from_loaded
                       all_installed
                       _find_all_installed
                       name               
                       version            
                       inc_dir            
                       file               
                       is_core            
                       has_pod
                       packages_inside    
                       package_versions
                       modules_required
                       modules_used       
                       _file2mod          
                       subroutines        
                       superclasses
                       die_on_compilation_error
                       _call_B
                       _get_extra_arguments
                       subroutines_called
                       dynamic_method_calls
                       safe
                       AUTOLOAD
                       use_version
                      );

my @unsafe_subs   = qw(
                       _eval
                       _call_perl
                       _is_win95
                       _is_macos_classic
                      );

my @safe_subs     = qw(
                       _eval
                       _call_perl
                       _create_compartment
                      );

can_ok('Module::Info', @expected_subs);

my $mod_info = Module::Info->new_from_file('lib/Module/Info.pm');
isa_ok($mod_info, 'Module::Info', 'new_from_file');

ok( !$mod_info->name,                       '    has no name' );
$mod_info->name('Module::Info');
ok( $mod_info->name,                        '    name set' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
ok( !$mod_info->inc_dir,                    '    has no inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );

SKIP: {
    skip "Only works on 5.6.1 and up.", 8 unless $] >= 5.006001;

    @expected_subs = ( ( map "Module::Info::$_", @expected_subs ),
                       ( map "Module::Info::Safe::$_", @safe_subs ),
                       ( map "Module::Info::Unsafe::$_", @unsafe_subs ) );

    my @packages = $mod_info->packages_inside;
    is( @packages, 3,                   'Found three packages inside' );
    is_deeply( [sort @packages],
               [sort qw(Module::Info Module::Info::Safe Module::Info::Unsafe)],
               '  and its what we want' );

    my %versions = $mod_info->package_versions;
    is( keys %versions, 3,                '1 package with package_versions()');
    is( $versions{Module::Info}, $Mod_Info_Pack_VERSION, 'version is correct');

    my %subs = $mod_info->subroutines;
    is( keys %subs, @expected_subs,    'Found all the subroutines' );
    is_deeply( [sort keys %subs], 
               [sort @expected_subs],  '   names' );

    my @mods = $mod_info->modules_used;
    my @expected = qw(strict File::Spec Config
                      Carp IPC::Open3 warnings Safe);
    push @expected, 'Exporter' if grep /^Exporter$/, @mods;
    # many old versions of these modules loaded the Exporter:
    is( @mods, @expected,    'Found all modules used' );
    is_deeply( [sort @mods], [sort @expected],
                            '    the right ones' );
}


$mod_info = Module::Info->new_from_module('Module::Info');
isa_ok($mod_info, 'Module::Info', 'new_from_module');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
is( $mod_info->inc_dir, File::Spec->rel2abs('blib/lib'),
                                            '    inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('blib/lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );


# Grab the core version of Class::Struct and hope it hasn't been
# deleted.
@core_inc = map { File::Spec->canonpath($_) }
  ($Config{installarchlib}, $Config{installprivlib},
   $Config{archlib}, $Config{privlib});
$mod_info = Module::Info->new_from_module('Class::Struct', @core_inc);
if( $mod_info ) {
    is( $mod_info->name, 'Class::Struct',         '    name()' );

    ok( grep($mod_info->inc_dir eq $_, @core_inc),       '    inc_dir()' );
    is( $mod_info->file, 
        File::Spec->catfile( $mod_info->inc_dir, 'Class', 'Struct.pm' ),
                                                '    file()');
    ok( $mod_info->is_core,                     '    core module' );
} else {
    $mod_info = Module::Info->new_from_module('Class::Struct');

    ok( $mod_info, 'could load Class::Struct' );
    ok( $mod_info, 'could load Class::Struct' );
    ok( $mod_info, 'could load Class::Struct' );
    ok( $mod_info, 'could load Class::Struct' );
}

$mod_info = Module::Info->new_from_loaded('Module::Info');
isa_ok($mod_info, 'Module::Info', 'new_from_module');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
is( $mod_info->inc_dir, File::Spec->rel2abs('blib/lib'),
                                            '    inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('blib/lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );


@modules = Module::Info->all_installed('Module::Info');
ok( @modules,       'all_installed() returned something' );
ok( !(grep { !defined $_ || !$_->isa('Module::Info') } @modules),
                    "  they're all Module::Info objects"
  );

# I have no idea how many I'm going to get, so I'll only play with the 
# first one.  It's the current one.
$mod_info = $modules[0];
isa_ok($mod_info, 'Module::Info', 'all_installed');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
ok( !$mod_info->is_core,                    '    not a core module' );


# Ensure that code refs in @INC are skipped.
my @mods = Module::Info->all_installed('Module::Info', (@INC, sub { die }));
ok( @modules,       'all_installed() returned something' );
ok( !(grep { !defined $_ || !$_->isa('Module::Info') } @modules),
                    "  they're all Module::Info objects"
  );

$mod_info = Module::Info->new_from_loaded('this_module_does_not_exist');
is( $mod_info, undef, 'new_from_loaded' );

SKIP: {
    skip "Only works on 5.6.1 and up.", 17 unless $] >= 5.006001;

    my $module = Module::Info->new_from_file('t/lib/Foo.pm');
    my @packages = $module->packages_inside;
    is( @packages, 2,       'Found two packages inside' );
    ok( eq_set(\@packages, [qw(Foo Bar)]),   "  they're right" );

    my %versions = $module->package_versions;
    is( keys %versions, 2,                '2 packages with package_versions()');
    is( $versions{Foo}, '7.254',          'version is correct');
    is( $versions{Bar}, undef,            'no version present');

    my %subs = $module->subroutines;
    is( keys %subs, 2,                          'Found two subroutine' );
    ok( exists $subs{'Foo::wibble'},            '   its right' );

    my($start, $end) = @{$subs{'Foo::wibble'}}{qw(start end)};
    print "# start $start, end $end\n";
    is( $start, 21,           '   start line' );
    is( $end,   22,           '   end line'   );

    my @mods = $module->modules_used;
    is( @mods, 8,           'modules_used' );
    is_deeply( [sort @mods],
               [sort qw(strict vars Carp Exporter t/lib/Bar.pm t/lib/NotHere.pm
                        t/lib/Foo.pm lib)] );

    $module->name('Foo');
    my @isa = $module->superclasses;
    is( @isa, 3,            'isa' );
    is_deeply( [sort @isa], [sort qw(This That What::Ever)] );

    my @calls = sort { $a->{line} <=> $b->{line} }
                     $module->subroutines_called;

    my $startline = 25;
    my @expected_calls = ({
                           line     => $startline,
                           class    => undef,
                           type     => 'function',
                           name     => 'wibble'
                          },
                          {
                           line     => $startline + 1,
                           class    => undef,
                           type     => 'symbolic function',
                           name     => undef,
                          },
                          {
                           line     => $startline + 2,
                           class    => 'Foo',
                           type     => 'class method',
                           name     => 'wibble',
                          },
                          {
                           line     => $startline + 3,
                           class    => undef,
                           type     => 'object method',
                           name     => 'wibble',
                          },
                          {
                           line     => $startline + 5,
                           class    => undef,
                           type     => 'object method',
                           name     => 'wibble',
                          },
                          {
                           line     => $startline + 7,
                           class    => 'Foo',
                           type     => 'dynamic class method',
                           name     => undef,
                          },
                          {
                           line     => $startline + 8,
                           class    => undef,
                           type     => 'dynamic object method',
                           name     => undef,
                          },
                          {
                           line     => $startline + 9,
                           class    => undef,
                           type     => 'dynamic object method',
                           name     => undef,
                          },
                          {
                           line     => $startline + 10,
                           class    => 'Foo',
                           type     => 'dynamic class method',
                           name     => undef,
                          },
                          {
                           line     => $startline + 14,
                           class    => undef,
                           type     => 'object method',
                           name     => 'wibble'
                          },
                          {
                           line     => $startline + 17,
                           class    => undef,
                           type     => 'function',
                           name     => 'wibble'
                          },
                          {
                           line     => $startline + 30,
                           class    => undef,
                           type     => 'function',
                           name     => 'croak'
                          },
                          {
                           line     => $startline + 33,
                           class    => undef,
                           type     => 'function',
                           name     => 'wibble'
                          },
                         );
    is_deeply(\@calls, \@expected_calls, 'subroutines_called');
    is_deeply([$module->dynamic_method_calls],
              [grep $_->{type} =~ /dynamic/, @expected_calls]);

    $module = Module::Info->new_from_file('t/lib/Bar.pm');
    @mods   = $module->modules_used;
    @mods   = grep { $_ ne 'Win32' } @mods if $^O eq 'MSWin32';
    is( @mods, 3, 'modules_used with complex BEGIN block' );
    is_deeply( [sort @mods],
               [sort qw(Cwd Carp strict)] );
}
