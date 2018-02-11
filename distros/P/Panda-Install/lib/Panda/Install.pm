package Panda::Install;
use strict;
use warnings;
use Config;
use Cwd 'abs_path';
use Exporter 'import';
use Panda::Install::Payload;

our $VERSION = '1.2.12';

our @EXPORT_OK = qw/write_makefile makemaker_args/;
our @EXPORT;

if ($0 =~ /Makefile.PL$/) {
    @EXPORT = qw/write_makefile makemaker_args/;
    _require_makemaker();
}

my $xs_mask  = '*.xs';
my $xsi_mask = '*.xsi';
my $c_mask   = '*.c *.cc *.cpp *.cxx';
my $h_mask   = '*.h *.hh *.hpp *.hxx';
my $map_mask = '*.map';
my $win32    = $^O eq 'MSWin32';

sub write_makefile {
    _require_makemaker();
    WriteMakefile(makemaker_args(@_));
}

sub makemaker_args {
    my %params = @_;
    _sync();
        
    $params{MIN_PERL_VERSION} ||= '5.10.0';
    
    my $postamble = $params{postamble};
    $postamble = {my => $postamble} if $postamble and !ref($postamble);
    $postamble ||= {};
    $postamble->{my} = '' unless defined $postamble->{my};
    $params{postamble} = $postamble;
    
    _string_merge($params{CCFLAGS}, '-o $@');

    die "You must define a NAME param" unless $params{NAME};
    unless ($params{ALL_FROM} || $params{VERSION_FROM} || $params{ABSTRACT_FROM}) {
        my $name = $params{NAME};
        $name =~ s#::#/#g;
        $params{ALL_FROM} = "lib/$name.pm";
    }
    
    if (my $package_file = delete $params{ALL_FROM}) {
        $params{VERSION_FROM}  = $package_file;
        $params{ABSTRACT_FROM} = $package_file;
    }

    $params{CONFIGURE_REQUIRES} ||= {};
    $params{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'} ||= '6.76';
    $params{CONFIGURE_REQUIRES}{'Panda::Install'}      ||= $VERSION;
    
    $params{BUILD_REQUIRES} ||= {};
    $params{BUILD_REQUIRES}{'ExtUtils::MakeMaker'} ||= '6.76';
    $params{BUILD_REQUIRES}{'ExtUtils::ParseXS'}   ||= '3.24';
    
    $params{TEST_REQUIRES} ||= {};
    $params{TEST_REQUIRES}{'Test::Simple'} ||= '0.96';
    $params{TEST_REQUIRES}{'Test::More'}   ||= 0;
    $params{TEST_REQUIRES}{'Test::Deep'}   ||= 0;
    
    $params{PREREQ_PM} ||= {};
    $params{PREREQ_PM}{'Panda::Install'} ||= $VERSION; # needed at runtime because it has payload_dir and xsloader
    
    $params{clean} ||= {};
    $params{clean}{FILES} ||= '';
    
    delete $params{BIN_SHARE} if $params{BIN_SHARE} and !%{$params{BIN_SHARE}};
    
    {
        my $val = $params{SRC};
        $val = [$val] if $val and ref($val) ne 'ARRAY';
        $params{SRC} = $val;
    }
    {
        my $val = $params{XS};
        $val = [$val] if $val and ref($val) ne 'ARRAY' and ref($val) ne 'HASH';
        $params{XS} = $val;
    }
    
    $params{TYPEMAPS} = [$params{TYPEMAPS}] if $params{TYPEMAPS} and ref($params{TYPEMAPS}) ne 'ARRAY';
    
    my $module_info = Panda::Install::Payload::module_info($params{NAME}) || {};
    $params{MODULE_INFO} = {BIN_DEPENDENT => $module_info->{BIN_DEPENDENT}};
    
    process_XS(\%params);
    process_PM(\%params);
    process_C(\%params);
    process_OBJECT(\%params);
    process_H(\%params);
    process_XSI(\%params);
    process_CLIB(\%params);
    process_PAYLOAD(\%params);
    process_BIN_DEPS(\%params);
    process_BIN_SHARE(\%params);
    attach_BIN_DEPENDENT(\%params);
    warn_BIN_DEPENDENT(\%params);

    if (my $use_cpp = delete $params{CPLUS}) {
        $params{CC} ||= 'c++';
        $params{LD} ||= '$(CC)';
        _string_merge($params{XSOPT}, '-C++');
        
        my $cppv = int($use_cpp);
        _string_merge($params{CCFLAGS}, "-std=c++$cppv") if $cppv > 1;
    }
    
    # inject Panda::Install::ParseXS into xsubpp
    $postamble->{xsubpprun} = 'XSUBPPRUN = $(PERLRUN) -MPanda::Install::ParseXS $(XSUBPP)';
    $params{LDFROM} ||= '$(OBJECT)';
    
    delete $params{$_} for qw/SRC/;
    $params{OBJECT} = '$(O_FILES)' unless defined $params{OBJECT};
    
    if (my $shared_libs = $params{MODULE_INFO}{SHARED_LIBS} and $^O ne 'darwin') { # MacOSX doesn't allow for linking with bundles :(
        my %seen;
        @$shared_libs = grep {!$seen{$_}++} reverse @$shared_libs;
        $params{LDFROM} .= ' '.join(' ', @$shared_libs) if @$shared_libs;
    }
    
    delete $params{MODULE_INFO};

    $params{CCFLAGS} = "$Config{ccflags} $params{CCFLAGS}";

    if (!$params{C} || !@{$params{C}} and !$params{OBJECT} || !@{$params{OBJECT}} and !$params{XS} || !scalar(keys %{$params{XS}})) {
        delete $params{$_} for qw/C H OBJECT XS CCFLAGS LDFROM/;
    }
     
    return %params;
}

sub process_PM {
    my $params = shift;
    return if $params->{PM}; # user-defined value overrides defaults
    
    my $instroot = _instroot($params);
    my @name_parts = split '::', $params->{NAME};
    $params->{PMLIBDIRS} ||= ['lib', $name_parts[-1]];
    my $pm = $params->{PM} = {};
    
    foreach my $dir (@{$params->{PMLIBDIRS}}) {
        next unless -d $dir;
        foreach my $file (_scan_files('*.pm *.pl', $dir)) {
            my $rel = $file;
            $rel =~ s/^$dir//;
            my $instpath = "$instroot/$rel";
            $instpath =~ s#[/\\]{2,}#/#g;
            $pm->{$file} = $instpath;
        }
    }
}

sub process_XS {
    my $params = shift;
    my ($xs_files, @xs_list);
    if ($params->{XS}) {
        if (ref($params->{XS}) eq 'HASH') {
            $xs_files = $params->{XS};
        } else {
            push @xs_list, @{_string_split_array($_)} for @{$params->{XS}};
        }
    } else {
        @xs_list = _scan_files($xs_mask);
    }
    push @xs_list, _scan_files($xs_mask, $_) for @{$params->{SRC}};
    $params->{XS} = $xs_files ||= {};
    foreach my $xsfile (@xs_list) {
        next if $xs_files->{$xsfile};
        my $cfile = $xsfile;
        $cfile =~ s/\.xs$/.c/ or next;
        $xs_files->{$xsfile} = $cfile;
    }
}

sub process_C {
    my $params = shift;
    my $c_files = $params->{C} ? _string_split_array(delete $params->{C}) : [_scan_files($c_mask)];
    push @$c_files, grep { !_includes($c_files, $_) } values %{$params->{XS}};
    push @$c_files, grep { !_includes($c_files, $_) } _scan_files($c_mask, $_) for @{$params->{SRC}};
    $params->{C} = $c_files;
}

sub process_OBJECT {
    my $params = shift;
    my $o_files = _string_split_array(delete $params->{OBJECT});
    foreach my $c_file (@{$params->{C}}) {
        my $o_file = $c_file;
        $o_file =~ s/\.[^.]+$//;
        push @$o_files, $o_file.'$(OBJ_EXT)';
    }
    $params->{OBJECT} = $o_files;
    $params->{clean}{FILES} .= ' $(O_FILES)';
}

sub process_H {
    my $params = shift;
    my $h_files = $params->{H} ? _string_split_array(delete $params->{H}) : [_scan_files($h_mask)];
    push @$h_files, _scan_files($h_mask, $_) for @{$params->{SRC}};
    $params->{H} = $h_files;
}

sub process_XSI { # make XS files rebuild if an XSI file changes
    my $params = shift;
    my @xsi_files = glob($xsi_mask);
    push @xsi_files, _scan_files($xsi_mask, $_) for @{$params->{SRC}};
    $params->{postamble}{xsi} = '$(XS_FILES):: '.join(' ', @xsi_files).'; $(TOUCH) $(XS_FILES)'."\n" if @xsi_files;
}

sub process_CLIB {
    my $params = shift;
    my $clibs = '';
    my $clib = delete $params->{CLIB} or return;
    $clib = [$clib] unless ref($clib) eq 'ARRAY';
    return unless @$clib;
    
    foreach my $info (@$clib) {
        my $build_cmd = $info->{BUILD_CMD};
        my $clean_cmd = $info->{CLEAN_CMD};
        
        unless ($build_cmd) {
            my $make = '$(MAKE)';
            $make = 'gmake' if $info->{GMAKE} and $^O eq 'freebsd';
            $info->{TARGET} ||= '';
            $info->{FLAGS} ||= '';
            $build_cmd = "$make $info->{FLAGS} $info->{TARGET}";
            $clean_cmd = "$make clean";
        }
        
        my $path = $info->{DIR}.'/'.$info->{FILE};
        $clibs .= "$path ";
        
        $params->{postamble}{clib_build} .= "$path : ; cd $info->{DIR} && $build_cmd\n";
        $params->{postamble}{clib_clean} .= "clean :: ; cd $info->{DIR} && $clean_cmd\n" if $clean_cmd;
        push @{$params->{OBJECT}}, $path;
    }
    $params->{postamble}{clib_ldep} = "linkext:: $clibs";
}

sub process_PAYLOAD {
    my $params = shift;
    my $payload = delete $params->{PAYLOAD} or return;
    _process_map($payload, '*');
    _install($params, $payload, 'payload');
}

sub process_BIN_DEPS {
    my $params = shift;
    my $bin_deps = delete $params->{BIN_DEPS} or return;
    $bin_deps = [$bin_deps] unless ref($bin_deps) eq 'ARRAY';
    my $typemaps = $params->{TYPEMAPS} ||= [];
    $params->{TYPEMAPS} = [];
    _apply_BIN_DEPS($params, $_, {}) for @$bin_deps;
    push @{$params->{TYPEMAPS}}, @{$typemaps};
}

sub _apply_BIN_DEPS {
    my ($params, $module, $seen) = @_;
    my $stop_sharing;
    $stop_sharing = 1 if $module =~ s/^-//;
    
    return if $seen->{$module}++;
    
    my $installed_version = Panda::Install::Payload::module_version($module);
    $params->{CONFIGURE_REQUIRES}{$module}  ||= $installed_version;
    $params->{PREREQ_PM}{$module}           ||= $installed_version;
    $params->{MODULE_INFO}{BIN_DEPS}{$module} = $installed_version;
    
    # add so/dll to linker list
    my $shared_list = $params->{MODULE_INFO}{SHARED_LIBS} ||= [];
    my $module_path = $module;
    $module_path =~ s#::#/#g;
    die "SHOULDN'T EVER HAPPEN" unless $module =~ /([^:]+)$/;
    my $module_last_name = $1;
    foreach my $dir (@INC) {
        my $lib_path = "$dir/auto/$module_path/$module_last_name.$Config{dlext}";
        next unless -f $lib_path;
        push @$shared_list, abs_path($lib_path);
        last;
    }    
    
    my $info = Panda::Install::Payload::module_info($module);
    
    if ($info->{INCLUDE}) {
        my $incdir = Panda::Install::Payload::include_dir($module);
        _string_merge($params->{INC}, "-I$incdir");
    }
    
    _string_merge($params->{INC},     $info->{INC});
    _string_merge($params->{CCFLAGS}, $info->{CCFLAGS});
    _string_merge($params->{DEFINE},  $info->{DEFINE});
    _string_merge($params->{XSOPT},   $info->{XSOPT});
    
    if (my $add_libs = $info->{LIBS}) {{
        last unless @$add_libs;
        my $libs = $params->{LIBS} or last;
        $libs = [$libs] unless ref($libs) eq 'ARRAY';
        if ($libs and @$libs) {
            my @result;
            foreach my $l1 (@$libs) {
                foreach my $l2 (@$add_libs) {
                    push @result, "$l1 $l2";
                }
            }
            $params->{LIBS} = \@result;
        }
        else {
            $params->{LIBS} = $add_libs;
        }
    }}
    
    if (my $passthrough = $info->{PASSTHROUGH}) {
        _apply_BIN_DEPS($params, $_, $seen) for @$passthrough;
    }
    
    if (my $typemaps = $info->{TYPEMAPS}) {
        my $tm_dir = Panda::Install::Payload::typemap_dir($module);
        foreach my $typemap (@$typemaps) {
            my $tmfile = "$tm_dir/$typemap";
            $tmfile =~ s#[/\\]{2,}#/#g;
            push @{$params->{TYPEMAPS} ||= []}, $tmfile;
        }
    }
    
    $params->{CPLUS} = $info->{CPLUS} if $info->{CPLUS} and (!$params->{CPLUS} or $params->{CPLUS} < $info->{CPLUS});
    
    if (my $bin_share = $params->{BIN_SHARE} and !$stop_sharing) {
        push @{$bin_share->{PASSTHROUGH} ||= []}, $module;
    }
}

sub process_BIN_SHARE {
    my $params = shift;
    my $bin_share = delete $params->{BIN_SHARE} or return;
    
    my $typemaps = delete($bin_share->{TYPEMAPS}) || {};
    _process_map($typemaps, $map_mask);
    _install($params, $typemaps, 'tm');
    $bin_share->{TYPEMAPS} = [values %$typemaps] if scalar keys %$typemaps;
    
    my $include = delete($bin_share->{INCLUDE}) || {};
    _process_map($include, $h_mask);
    _install($params, $include, 'i');
    $bin_share->{INCLUDE} = 1 if scalar(keys %$include);
    
    $bin_share->{LIBS} = [$bin_share->{LIBS}] if $bin_share->{LIBS} and ref($bin_share->{LIBS}) ne 'ARRAY';
    $bin_share->{PASSTHROUGH} = [$bin_share->{PASSTHROUGH}] if $bin_share->{PASSTHROUGH} and ref($bin_share->{PASSTHROUGH}) ne 'ARRAY';
    
    if (my $list = $params->{MODULE_INFO}{BIN_DEPENDENT}) {
        $bin_share->{BIN_DEPENDENT} = $list if @$list;
    }
    
    if (my $vinfo = $params->{MODULE_INFO}{BIN_DEPS}) {
        $bin_share->{BIN_DEPS} = $vinfo if %$vinfo;
    }
    
    return unless %$bin_share;
    
    # generate info file
    mkdir 'blib';
    my $infopath = 'blib/info';
    _module_info_write($infopath, $bin_share);
    
    my $pm = $params->{PM} ||= {};
    $pm->{$infopath} = '$(INST_ARCHLIB)/$(FULLEXT).x/info';
}

sub attach_BIN_DEPENDENT {
    my $params = shift;
    my @deps = keys %{$params->{MODULE_INFO}{BIN_DEPS} || {}};
    return unless @deps;
    
    $params->{postamble}{sync_bin_deps} =
        "sync_bin_deps:\n".
        "\t\$(PERL) -MPanda::Install -e 'Panda::Install::cmd_sync_bin_deps()' $params->{NAME} @deps\n".
        "install :: sync_bin_deps";
}

sub warn_BIN_DEPENDENT {
    my $params = shift;
    return unless $params->{VERSION_FROM};
    my $module = $params->{NAME};
    my $list = $params->{MODULE_INFO}{BIN_DEPENDENT} or return;
    return unless @$list;
    my $installed_version = Panda::Install::Payload::module_version($module) or return;
    my $mm = bless {}, 'MM';
    my $new_version = $mm->parse_version($params->{VERSION_FROM}) or return;
    return if $installed_version eq $new_version;
    warn << "EOF";
******************************************************************************
Panda::Install: There are XS modules that binary depend on current XS module $module.
They were built with currently installed $module version $installed_version.
If you install $module version $new_version, you will have to reinstall all XS modules that binary depend on it:
cpanm -f @$list
******************************************************************************
EOF
}

sub cmd_sync_bin_deps {
    my $myself = shift @ARGV;
    my @modules = @ARGV;
    foreach my $module (@modules) {
        my $info = Panda::Install::Payload::module_info($module) or next;
        my $dependent = $info->{BIN_DEPENDENT} || [];
        my %tmp = map {$_ => 1} grep {$_ ne $module} @$dependent;
        $tmp{$myself} = 1;
        $info->{BIN_DEPENDENT} = [sort keys %tmp];
        delete $info->{BIN_DEPENDENT} unless @{$info->{BIN_DEPENDENT}};
        my $file = Panda::Install::Payload::module_info_file($module);
        _module_info_write($file, $info);
    }
}

sub _install {
    my ($params, $map, $path) = @_;
    return unless %$map;
    my $xs = $params->{XS};
    my $instroot = _instroot($params);
    my $pm = $params->{PM} ||= {};
    while (my ($source, $dest) = each %$map) {
        my $instpath = "$instroot/\$(FULLEXT).x/$path/$dest";
        $instpath =~ s#[/\\]{2,}#/#g;
        $pm->{$source} = $instpath;
    }
}

sub _instroot {
    my $params = shift;
    my $xs = $params->{XS};
    my $instroot = ($xs and %$xs) ? '$(INST_ARCHLIB)' : '$(INST_LIB)';
    return $instroot;
}

sub _sync {
    no strict 'refs';
    my $from = 'MYSOURCE';
    my $to = 'MY';
    foreach my $method (keys %{"${from}::"}) {
        next unless defined &{"${from}::$method"};
        *{"${to}::$method"} = \&{"${from}::$method"};
    }
}

sub _scan_files {
    my ($mask, $dir) = @_;
    return grep {_is_file_ok($_)} glob($mask) unless $dir;
    
    my @list = grep {_is_file_ok($_)} glob(join(' ', map {"$dir/$_"} split(' ', $mask)));
    
    opendir(my $dh, $dir) or die "Could not open dir '$dir' for scanning: $!";
    while (my $entry = readdir $dh) {
        next if $entry =~ /^\./;
        my $path = "$dir/$entry";
        next unless -d $path;
        push @list, _scan_files($mask, $path);
    }
    closedir $dh;
    
    return @list;
}

sub _is_file_ok {
    my $file = shift;
    return unless -f $file;
    return if $file =~ /\#/;
    return if $file =~ /~$/;             # emacs temp files
    return if $file =~ /,v$/;            # RCS files
    return if $file =~ m{\.swp$};        # vim swap files
    return 1;
}

sub _process_map {
    my ($map, $mask) = @_;
    foreach my $source (keys %$map) {
        my $dest = $map->{$source} || $source;
        if (-f $source) {
            $dest .= $source if $dest =~ m#[/\\]$#;
            $dest =~ s#[/\\]{2,}#/#g;
            $dest =~ s#^[/\\]+##;
            $map->{$source} = $dest;
            next;
        }
        next unless -d $source;
        
        delete $map->{$source};
        my @files = _scan_files($mask, $source);
        foreach my $file (@files) {
            my $dest_file = $file;
            $dest_file =~ s/^$source//;
            $dest_file = "$dest/$dest_file";
            $dest_file =~ s#[/\\]{2,}#/#g;
            $dest_file =~ s#^[/\\]+##;
            $map->{$file} = $dest_file;
        }
    }
}

sub _includes {
    my ($arr, $val) = @_;
    for (@$arr) { return 1 if $_ eq $val }
    return;
}

sub _string_split_array {
    my $list = shift;
    my @result;
    if ($list) {
        $list = [$list] unless ref($list) eq 'ARRAY';
        push @result, map { glob } split(' ') for @$list;
    }
    return \@result;
}

sub _string_merge {
    return unless $_[1];
    $_[0] ||= '';
    $_[0] .= $_[0] ? " $_[1]" : $_[1];
}

{
    package
        MYSOURCE;
        
    sub postamble {
        my $self = shift;
        my %args = @_;

        $args{'.xs.cc'} = '
.xs.cc:
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $(XSUBPP_EXTRA_ARGS) $*.xs > $*.xsc
	$(MV) $*.xsc $*.cc
';

        return join("\n", values %args);
    }
}

{
    package
        MY;
    use Config;

    if ($win32) {
        my $gcc_compliant = $Config{cc} =~ /\b(gcc|clang)\b/i ? 1 : 0;
        
        *dynamic_lib = sub {
            my ($self, %attribs) = @_;
            my $code = $self->SUPER::dynamic_lib(%attribs);
            
            unless ($gcc_compliant) {
                warn(
                    "Panda::Install: to maintain UNIX-like shared library behaviour on windows (export all symbols by default), we need gcc-compliant linker. ".
                    "Panda::Install-dependant modules should only be installed on perls with MinGW shell (like strawberry perl), or at least having gcc compiler. ".
                    "I will continue, but this module's binary dependencies may not work."
                );
                return $code;
            }
            return $code unless $code;
    
            # remove .def-related from code, remove double DLL build, remove dll.exp from params, add export all symbols param.
            my $DLLTOOL = $Config{dlltool} || 'dlltool';
            my (@out, $last_ld);
            map { $last_ld = $_ if /\$\(LD\)\s/ } split /\n/, $code;
            foreach my $line (split /\n/, $code) {
                next if $line =~ /$DLLTOOL/; # drop dlltool calls (we dont need .def file)
                if ($line =~ /\$\(LD\)\s/) {
                    next if $line ne $last_ld;
                    $line =~ s/\$\(LD\)\s/\$(LD) -Wl,--export-all-symbols /;
                    $line =~ s/\bdll\.exp\b//;
                }
                $line =~ s/\$\(EXPORT_LIST\)//g; # remove <PACKAGE>.def from target dependency
                push @out, $line;
            }
            
            $code = join("\n", @out);
            return $code;
        };
        
        *dlsyms = sub {
            my ($self, %attribs) = @_;
            return '' if $gcc_compliant; # our dynamic_lib target doesn't need any .def files with gcc
            return $self->SUPER::dlsyms(%attribs);
        };
    }
}


#    dlsyms  
    
    # generate DLL file containing all symbols, like default behaviour on UNIX.


sub _require_makemaker {
    unless ($INC{'ExtUtils/MakeMaker.pm'}) {
        require ExtUtils::MakeMaker;
        ExtUtils::MakeMaker->import();
    }
}

sub _module_info_write {
    my ($file, $info) = @_;
    require Data::Dumper;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    my $content = Data::Dumper::Dumper($info);
    my $restore_mode;
    if (-e $file) { # make sure we have permissions to write, because perl installs files with 444 perms
        my $mode = (stat $file)[2];
        unless ($mode & 0200) { # if not, temporary enable write permissions
            $restore_mode = $mode;
            $mode |= 0200;
            chmod $mode, $file;
        }
    }
    open my $fh, '>', $file or do {
        warn "Cannot open $file for writing: $!, \033[1;31mbinary deps info won't be synced!\033[0m\n";
        sleep 2;
        return;
    };
    print $fh $content;
    close $fh;
    
    chmod $restore_mode, $file if $restore_mode; # restore old perms if we changed it
}

1;
