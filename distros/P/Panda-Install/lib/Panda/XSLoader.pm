package Panda::XSLoader;
use strict;
use warnings;
use DynaLoader;
use Panda::Install::Payload;

sub load {
    no strict 'refs';
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my ($module, $version, $flags) = @_;
    $flags = 0x01 unless defined $flags;
    $module ||= caller(0);
    *{"${module}::dl_load_flags"} = sub { $flags } if $flags;
    $version ||= ${"${module}::VERSION"};
    if (!$version and my $vsub = $module->can('VERSION')) { $version = $module->VERSION }
    
    if (my $info = Panda::Install::Payload::module_info($module)) {{
        my $bin_deps = $info->{BIN_DEPS} or last;
        foreach my $dep_module (keys %$bin_deps) {
            my $path = $dep_module;
            $path =~ s!::!/!g;
            require $path.".pm" or next;
            my $dep_version = ${"${dep_module}::VERSION"};
            if (!$dep_version and my $vsub = $dep_module->can('VERSION')) { $dep_version = $dep_module->VERSION }
            next if $dep_version eq $bin_deps->{$dep_module};
            my $dep_info = Panda::Install::Payload::module_info($dep_module) || {};
            my $bin_dependent = $dep_info->{BIN_DEPENDENT};
            $bin_dependent = [$module] if !$bin_dependent or !@$bin_dependent;
            die << "EOF";
******************************************************************************
Panda::XSLoader: XS module $module binary depends on XS module $dep_module.
$module was compiled with $dep_module version $bin_deps->{$dep_module}, but current version is $dep_version.
Please reinstall all modules that binary depend on $dep_module:
cpanm -f @$bin_dependent
******************************************************************************
EOF
        }
    }}
    
    DynaLoader::bootstrap_inherit($module, $version);
    my $stash = \%{"${module}::"};
    delete $stash->{dl_load_flags};
}
*bootstrap = *load;

1;