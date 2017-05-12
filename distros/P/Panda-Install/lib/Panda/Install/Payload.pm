package Panda::Install::Payload;
use strict;
use warnings;

my %module_info;

sub data_dir {
    my $module = pop;
    $module =~ s/::/\//g;
    
    # first try search in loaded module's dir
    if (my $path = $INC{"$module.pm"}) {
        $path =~ s/\.pm$//;
        my $pldir = "$path.x";
        return $pldir if -d $pldir;
    }
    
    foreach my $inc (@INC) {
        my $pldir = "$inc/$module.x";
        return $pldir if -d $pldir;
    }
    
    return undef;
}

sub payload_dir {
    my $data_dir = data_dir(@_) or return undef;
    my $dir = "$data_dir/payload";
    return $dir if -d $dir;
    return undef;
}

sub include_dir {
    my $data_dir = data_dir(@_) or return undef;
    my $dir = "$data_dir/i";
    return $dir if -d $dir;
    return undef;
}

sub typemap_dir {
    my $data_dir = data_dir(@_) or return undef;
    my $dir = "$data_dir/tm";
    return $dir if -d $dir;
    return undef;
}

sub module_info_file {
    my $data_dir = data_dir(@_) or return undef;
    return "$data_dir/info";
}

sub module_info {
    my $module = shift;
    my $info = $module_info{$module};
    unless ($info) {
        my $file = module_info_file($module) or return undef;
        return undef unless -f $file;
        $info = require $file or return undef;
        $module_info{$module} = $info;
    }
    return $info;
}

sub module_version {
    my $module = shift;
    my $path = $module;
    $path =~ s!::!/!g;
    eval { require $path.".pm"; } or return 0;
    no strict 'refs';
    my $v = ${$module."::VERSION"};
    if (!$v and my $vsub = $module->can('VERSION')) {
        $v = $module->VERSION;
    }
    return $v || 0;
}

1;