package Monitoring::TT;

use strict;
use warnings;
use utf8;
use Pod::Usage;
use Getopt::Long;
use Template;
use Monitoring::TT::Identifier;
use Monitoring::TT::Log qw/error warn info debug trace log/;
use Monitoring::TT::Object;
use Monitoring::TT::Render;
use Monitoring::TT::Utils;

our $VERSION = '1.0.2';

#####################################################################

=head1 NAME

Monitoring::TT - Generic Monitoring Config based on Template Toolkit Templates

=head1 DESCRIPTION

Generic Monitoring Config based on Template Toolkit Templates

=cut

#####################################################################

=head1 CONSTRUCTOR

=head2 new

  new(%options)

=cut

sub new {
    my($class, %options) = @_;
    my $self = {
        tt_opts => {
            TRIM     => 1,
            RELATIVE => 1,
            STAT_TTL => 60,
            STRICT   => 1,
        }
    };
    bless $self, $class;

    $self->{'tt_opts'}->{'STRICT'} = 1 if $ENV{'TEST_AUTHOR'};
    $self->{'tt_opts'}->{'STRICT'} = 1 if -f '.author';
    for my $s (@{Monitoring::TT::Identifier::functions('Monitoring::TT::Render')}) {
        $self->{'tt_opts'}->{'PRE_DEFINE'}->{$s} = \&{'Monitoring::TT::Render::'.$s};
    }
    $Monitoring::TT::Render::tt = $self;

    return $self;
}

#####################################################################

=head1 METHODS

=head2 run

run config generator and write it to the output folder

=cut

sub run {
    my( $self ) = @_;
    return unless $self->_get_options();
    info('generating config from '.join(', ', @{$self->{'in'}}));
    info('into '.$self->{'out'});
    for my $in (@{$self->{'in'}}) {
        if(! -d $in.'/.') {
            error($in.': '.$!);
            exit 1;
        }
    }
    $self->_run_hook('pre', join(',', @{$self->{'in'}}));

    # die if output directory already exists
    if(-e $self->{'out'} and !$self->{'opt'}->{'force'}) {
        my @files = glob($self->{'out'}.'/*');
        if(scalar @files > 0) {
            error($self->{'out'}.' does already exist and is not empty. (use --force to overwrite contents)');
            exit 1;
        }
    }
    $self->_mkdir_r($self->{'out'});

    info('using template filter: '.$self->{'opt'}->{'templatefilter'}) if $self->{'opt'}->{'templatefilter'};
    info('using contact filter: '.$self->{'opt'}->{'contactfilter'})   if $self->{'opt'}->{'contactfilter'};
    info('using host filter: '.$self->{'opt'}->{'hostfilter'})         if $self->{'opt'}->{'hostfilter'};

    # reset counter
    $self->{'possible_types'} = {};
    $self->{'possible_tags'}  = {};
    $self->{'possible_apps'}  = {};

    $self->_copy_static_files();
    $self->_build_dynamic_config();
    $self->_check_typos() unless $self->{'opt'}->{'templatefilter'};
    $self->_post_process();
    $self->_print_stats() if $Monitoring::TT::Log::Verbose >= 2;
    $self->_run_hook('post', join(',', @{$self->{'in'}}));
    info('done');
    return 0;
}

#####################################################################

=head2 tt

return template toolkit object

=cut

sub tt {
    my($self) = @_;

    return $self->{'_tt'} if $self->{'_tt'};

    # make some globals available in TT stash
    $self->{'tt_opts'}->{'PRE_DEFINE'}->{'src'} = $self->{'in'};

    $self->{'_tt'} = Template->new($self->{'tt_opts'});
    $Template::Stash::PRIVATE = undef;

    return $self->{'_tt'};
}

#####################################################################
# INTERNAL SUBS
#####################################################################
sub _get_options {
    my($self) = @_;
    Getopt::Long::Configure('no_ignore_case');
    Getopt::Long::Configure('bundling');
    $self->{'opt'} = {
        files   => [],
        verbose => 1,
        force   => 0,
        dryrun  => 0,
    };
    GetOptions (
       'h|help'                 => \$self->{'opt'}->{'help'},
       'v|verbose'              => sub { $self->{'opt'}->{'verbose'}++ },
       'q|quiet'                => \$self->{'opt'}->{'quiet'},
       'V|version'              => \$self->{'opt'}->{'version'},
       'f|force'                => \$self->{'opt'}->{'force'},
       'cf|contactfilter=s'     => \$self->{'opt'}->{'contactfilter'},
       'hf|hostfilter=s'        => \$self->{'opt'}->{'hostfilter'},
       'tf|templatefilter=s'    => \$self->{'opt'}->{'templatefilter'},
       'n|dry-run'              => \$self->{'opt'}->{'dryrun'},
       '<>'                     => sub { push @{$self->{'opt'}->{'files'}}, $_[0] },
    ) or $self->_usage();
    if($self->{'opt'}->{'version'}) { print 'Version ', $VERSION,"\n"; exit 0; }
    pod2usage({ -verbose => 2, -exit => 3 } ) if $self->{'opt'}->{'help'};
    $self->_usage('please specify at least one input and output folder!') if scalar @{$self->{'opt'}->{'files'}} <= 1;
    for my $f (@{$self->{'opt'}->{'files'}}) { $f =~ s/\/*$//gmx; }
    $self->{'out'}              = pop @{$self->{'opt'}->{'files'}};
    $self->{'in'}               = $self->{'opt'}->{'files'};
    $self->{'opt'}->{'verbose'} = 0 if $self->{'opt'}->{'quiet'};
    $self->{'opt'}->{'dryrun'}  = 1 if $self->{'opt'}->{'contactfilter'};
    $self->{'opt'}->{'dryrun'}  = 1 if $self->{'opt'}->{'hostfilter'};
    $self->{'opt'}->{'dryrun'}  = 1 if $self->{'opt'}->{'templatefilter'};
    $Monitoring::TT::Log::Verbose = $self->{'opt'}->{'verbose'};
    info('Dry Run, Hooks won\'t be executed') if $self->{'opt'}->{'dryrun'};
    return 1;
}

#####################################################################
sub _usage {
    my($self, $msg) = @_;
    print $msg, "\n\n" if $msg;
    print "usage: $0 [options] <input> [<input>...] <output>\ndetailed help available with --help\n";
    exit 3;
}

#####################################################################
sub _copy_static_files {
    my($self) = @_;
    for my $in (@{$self->{'in'}}) {
        if(-d $in.'/static/.') {
            my $cmd = 'cp -LR '.$in.'/static/* '.$self->{'out'}.'/';
            debug($cmd);
            `$cmd`;
        }
    }
    return;
}

#####################################################################
sub _build_dynamic_config {
    my($self) = @_;
    # main work block, dynamic object configuration
    $self->_build_dynamic_object_config();

    # other files
    for my $in (@{$self->{'in'}}) {
        for my $file (sort glob($in.'/*.cfg')) {
            next if defined $self->{'opt'}->{'templatefilter'} and $file !~ m/$self->{'opt'}->{'templatefilter'}/mx;
            info('processing non object: '.$file);
            my $outfile = $file;
            $outfile    =~ s/.*\///mx;
            next if $outfile =~ m/^hosts.*\.cfg/gmx;
            next if $outfile =~ m/^contacts.*\.cfg/gmx;
            $outfile    = $self->{'out'}.'/'.$outfile;
            debug('writing: '.$outfile);
            open(my $fh, '>', $outfile) or die('cannot write '.$outfile.': '.$!);
            print $fh $self->_process_template($self->_read_replaced_template($file), {});
            print $fh "\n";
            close($fh);
        }
    }

    return;
}

#####################################################################
# do the main work, this block is essential for maximum performance
sub _build_dynamic_object_config {
    my($self) = @_;

    # detect input type
    my $input_types = $self->_get_input_types($self->{'in'});

    # no dynamic config at all?
    return unless scalar keys %{$input_types} > 0;

    # build templates
    my $templates = {
        contacts => $self->_build_template('conf.d', 'contacts'),
        hosts    => $self->_build_template('conf.d', 'hosts', [ 'conf.d/apps', 'conf.d/apps.cfg' ]),
    };

    mkdir($self->{'out'}.'/conf.d');

    $self->{'data'} = { hosts => [], contacts => [] };
    for my $type (keys %{$input_types}) {
        my $typefilter = $self->{'opt'}->{substr($type,0,-1).'filter'};
        my $obj_list = [];
        trace('fetching data for '.$type) if $Monitoring::TT::Log::Verbose >= 4;
        for my $cls (@{$input_types->{$type}}) {
            for my $in (@{$self->{'in'}}) {
                my $data = $cls->read($in, $type);
                for my $d (@{$data}) {
                    $d->{'montt'} = $self;
                    my $o = Monitoring::TT::Object->new($type, $d);
                    die('got no object') unless defined $o;
                    next if defined $typefilter and join(',', values %{$o}) !~ m/$typefilter/mx;
                    trace($o) if $Monitoring::TT::Log::Verbose >= 5;
                    push @{$obj_list}, $o;
                }
            }
        }
        # sort objects by name
        @{$obj_list} = sort {$a->{'name'} cmp $b->{'name'}} @{$obj_list};
        $self->{'data'}->{$type} = $obj_list;

        my $outfile = $self->{'out'}.'/conf.d/'.$type.'.cfg';
        info('writing: '.$outfile);
        open(my $fh, '>', $outfile) or die('cannot write '.$outfile.': '.$!);
        print $fh $self->_process_template($templates->{$type}, { type => $type, data => $obj_list });
        print $fh "\n";
        close($fh);
    }

    for my $in (@{$self->{'in'}}) {
        for my $file (reverse sort @{$self->_get_files($in.'/conf.d', '\.cfg')}) {
            next if defined $self->{'opt'}->{'templatefilter'} and $file !~ m/$self->{'opt'}->{'templatefilter'}/mx;
            next if $file =~ m/^$in\/conf\.d\/apps/mx;
            next if $file =~ m/^$in\/conf\.d\/contacts/mx;
            next if $file =~ m/^$in\/conf\.d\/hosts/mx;
            info('processing object file: '.$file);
            my $outfile = $file;
            $outfile    =~ s/.*\///mx;
            $outfile    = $self->{'out'}.'/conf.d/'.$outfile;
            debug('writing: '.$outfile);
            open(my $fh, '>', $outfile) or die('cannot write '.$outfile.': '.$!);
            print $fh $self->_process_template($self->_read_replaced_template($file), $self->{'data'});
            print $fh "\n";
            close($fh);
        }
    }

    return;
}

#####################################################################
sub _print_stats {
    my($self) = @_;
    my $out  = $self->{'out'};
    info('written:');
    for my $type (qw/host hostgroup hostdependency hostextinfo hostescalation
                     service servicegroup servicedependency serviceextinfo serviceescalation
                     contact contactgroup command timeperiod
                     /) {
        my $num = $self->_grep_count($out, '^\s*define\s*'.$type.'\( \|{\)');
        next if $num == 0;
        info(sprintf('# %-15s %6s', $type, $num));
    }
    return;
}

#####################################################################
sub _grep_count {
    my($self, $dir, $pattern) = @_;
    my $txt   = `grep -r -c '$pattern' $dir 2>&1`;
    my $total = 0;
    for my $line (split/\n/mx, $txt) {
        if($line =~ m/:(\d+)$/mx) {
            $total += $1;
        }
    }
    return $total;
}

#####################################################################
sub _build_template {
    my($self, $dir, $type, $appdirs) = @_;
    my $shorttype = substr($type, 0, -1);
    my $template  = "[% FOREACH d = data %][% ".$shorttype." = d %]\n";
    my $found = 0;
    for my $in (@{$self->{'in'}}) {
        for my $path (glob($in.'/'.$dir.'/'.$type.'/ '.
                           $in.'/'.$dir.'/'.$type.'*.cfg')
        ) {
            trace('looking for '.$type.' templates in '.$path) if $Monitoring::TT::Log::Verbose >= 4;
            if(-e $path) {
                my $templates = $self->_get_files($path, '\.cfg');
                for my $t (reverse sort @{$templates}) {
                    next if defined $self->{'opt'}->{'templatefilter'} and $t !~ m|$self->{'opt'}->{'templatefilter'}|mx;
                    my $tags = $self->_get_tags_for_path($t, $path);
                    my $required_type = shift @{$tags};
                    info('adding '.$type.' template: '.$t.($required_type ? ' for type '.$required_type : '').(scalar @{$tags} > 0 ? ' with tags: '.join(' & ', @{$tags}) : ''));
                    if($required_type) {
                        $self->{$type.'possible_types'}->{$required_type} = 1;
                        $template .= "[% IF d.type == '$required_type' %]";
                    }
                    for my $tag (@{$tags}) {
                        $self->{$type.'possible_tags'}->{$tag} = 1;
                        $template .= "[% IF d.has_tag('$tag') %]";
                    }
                    $template .= $self->_read_replaced_template($t);
                    for my $tag (@{$tags}) {
                        $template .= "[% END %]";
                    }
                    $template .= "[% END %]" if $required_type;
                    $found++;
                    $template .= "\n";
                }
            }
        }
    }

    # add apps for hosts
    if(defined $appdirs and scalar @{$appdirs} > 0) {
        for my $in (@{$self->{'in'}}) {
            for my $path (@{$appdirs}) {
                $path = $in.'/'.$path;
                trace('looking for '.$type.' apps in '.$path) if $Monitoring::TT::Log::Verbose >= 4;
                if(-e $path) {
                    my $templates = $self->_get_files($path, '\.cfg');
                    for my $t (reverse sort @{$templates}) {
                        next if defined $self->{'opt'}->{'templatefilter'} and $t !~ m|$self->{'opt'}->{'templatefilter'}|mx;
                        my $apps = $self->_get_tags_for_path($t, $path);
                        info('adding apps template: '.$t.(scalar @{$apps} > 0 ? ' for apps: '.join(' & ', @{$apps}) : ''));
                        for my $app (@{$apps}) {
                            $self->{'possible_apps'}->{$app} = 1;
                            $template .= "[% IF d.has_app('$app') %]";
                        }
                        $template .= $self->_read_replaced_template($t);
                        for my $app (@{$apps}) {
                            $template .= "[% END %]";
                        }
                        $found++;
                        $template .= "\n";
                    }
                }
            }
        }
    }

    if($found == 0) {
        debug('no templates for type '.$type.' found');
        return '';
    }
    $template .= "[% END %]\n";
    if($Monitoring::TT::Log::Verbose >= 4) {
        trace('created template:');
        trace($template);
    }
    return $template;
}

#####################################################################
sub _get_files {
    my($self, $dir, $pattern) = @_;
    if(!-d $dir and $dir =~ m/$pattern/mx) {
        return([$dir]);
    }
    my @files;
    return \@files unless -d $dir;
    opendir(my $d, $dir) or die("cannot read directory $dir: $!");
    while(my $file = readdir($d)) {
        next if substr($file,0,1) eq '.';
        if(-d $dir.'/'.$file.'/.') {
            push @files, @{$self->_get_files($dir.'/'.$file, $pattern)};
        } else {
            next if $file !~ m/$pattern/mx;
            push @files, $dir."/".$file;
        }
    }
    return \@files;
}

#####################################################################
sub _process_template {
    my($self, $template, $data) = @_;

    if(!defined $self->{'_config_template'}) {
        $self->{'_config_template'} = "";
        for my $in (@{$self->{'in'}}) {
            debug('looking for a '.$in.'/config.cfg');
            if(-e $in.'/config.cfg') {
                debug('added config template '.$in.'/config.cfg');
                $self->{'_config_template'} .= $self->_read_replaced_template($in.'/config.cfg')."\n";
            }
        }
    }
    $template = $self->{'_config_template'}.$template;

    if($Monitoring::TT::Log::Verbose >= 4) {
        trace('template:');
        trace('==========================');
        trace($template);
        trace('==========================');
    }

    my $output;
    $self->tt->process(\$template, $data, \$output) or $self->_template_process_die($template, $data);

    # clean up result
    $output =~ s/^\s*$//sgmxo;
    $output =~ s/^\n//gmxo;

    return $output;
}

#####################################################################
sub _post_process {
    my($self) = @_;
    my $out = $self->{'out'};
    for my $in (@{$self->{'in'}}) {
        for my $processor (sort glob($in.'/post_process*')) {
            info('postprocessing with '.$processor);
            if(!-x $processor) {
                error("post processor ".$processor." must be executable");
                next;
            }
            my $res = `$processor $out`;
            my $rc = $?;
            if($rc != 0) {
                warn($res);
            }
        }
    }
    return;
}

#####################################################################
sub _get_input_classes {
    my($self, $folders) = @_;
    my $types = [];

    for my $dir (@{$folders}) {
        next unless -d $dir.'/lib/.';
        unshift @INC, "$dir/lib";
        trace('added '.$dir.'/lib to @INC') if $Monitoring::TT::Log::Verbose >= 4;
    }

    if($Monitoring::TT::Log::Verbose >= 4) {
        trace('@INC:');
        trace(\@INC);
    }

    my $uniq_types = {};
    my $uniq_libs  = {};
    for my $inc (@INC) {
        next if defined $uniq_libs->{$inc};
        $uniq_libs->{$inc} = 1;
        my @files = glob($inc.'/Monitoring/TT/Input/*.pm');
        for my $file (glob($inc.'/Monitoring/TT/Input/*.pm')) {
            trace('found input class: '.$file) if $Monitoring::TT::Log::Verbose >= 4;
            $file =~ s|^$inc/Monitoring/TT/Input/||mx;
            $file =~ s|\.pm$||mx;
            push @{$types}, $file unless defined $uniq_types->{$types}->{$file};
            $uniq_types->{$types}->{$file} = 1;
        }
    }
    return $types;
}

#####################################################################
sub _get_input_types {
    my($self, $folders) = @_;
    my $input_types = {};
    my $input_classes = $self->_get_input_classes($folders);
    for my $t (@{$input_classes}) {
        debug('requesting input files from: '.$t);
        my $objclass = 'Monitoring::TT::Input::'.$t;
        ## no critic
        eval "require $objclass;";
        ## use critic
        error($@) if $@;
        my $obj      = \&{$objclass."::new"};
        my $it       = &$obj($objclass, montt => $self);
        my $types    = $it->get_types($folders);
        trace('input \''.$t.'\' supports: '.join(', ', @{$types})) if $Monitoring::TT::Log::Verbose >= 4;
        for my $type (@{$types}) {
            $input_types->{$type} = [] unless defined $input_types->{$type};
            push @{$input_types->{$type}}, $it;
        }
    }
    return $input_types;
}

#####################################################################
sub _run_hook {
    my($self, $name, $args) = @_;
    return if $self->{'opt'}->{'dryrun'};
    for my $in (@{$self->{'in'}}) {
        my $hook = $in.'/hooks/'.$name;
        trace("hook: looking for ".$hook) if $Monitoring::TT::Log::Verbose >= 4;
        if(-x $hook) {
            my $cmd = $hook;
            $cmd = $cmd." ".$args if defined $args;
            debug($cmd);
            open(my $ph, '-|', $cmd);
            while(my $line = <$ph>) {
                log($line);
            }
            close($ph);
            my $rc  = $?>>8;
            debug('hook returned: '.$rc);
            if($rc) {
                debug(' -> exiting');
                exit $rc;
            }
        }
    }
    return;
}

#####################################################################
sub _read_replaced_template {
    my($self, $template) = @_;
    $template =~ s|//|/|gmxo;
    my $text = '[%# SRC '.$template.':1 #%]';
    open(my $fh, '<', $template) or die("cannot read: ".$template.': '.$!);
    while(my $line = <$fh>) {
        # remove utf8 file bom
        if($. == 1) {
            my $bom = pack("CCC", 0xef, 0xbb, 0xbf);
            if(substr($line,0,3) eq $bom) {
                $line = substr($line, 3);
            }
        }
        $text .= $line;
        if($line =~ m/^define\s+(\w+)/mxo) {
            if($1 eq 'service' or $1 eq 'host' or $1 eq 'contact') {
                $text .= '  _SRC '.$template.':'.$.."\n";
            } else {
                $text .= '# SRC '.$template.':'.$.."\n";
            }
        }
    }
    close($fh);
    return $text;
}

#####################################################################
sub _get_tags_for_path {
    my($self, $path, $basepath) = @_;
    my $tmppath = lc $path;
    $tmppath    =~ s|^$basepath||mx;
    $tmppath    =~ s|\.cfg$||mx;
    $tmppath    =~ s|^/||mx;
    my @tags = split(/\//mx, $tmppath);
    return \@tags;
}

#####################################################################
sub _template_process_die {
    my($self, $template, $data) = @_;
    my $tterror = "".$self->tt->error();
    my $already_printed = 0;

    # try to find file / line
    if($tterror =~ m/input\s+text\s+line\s+(\d+)/mx) {
        my $linenr = $1;
        my @lines = split/\n/mx, $template;
        my($realfile, $realline) = $self->_get_file_and_line_for_error(\@lines, $linenr);
        if($realfile) {
            my $newloc = $realfile.' line '.$realline;
            $tterror =~ s|input\s+text\s+line\s+\d+|$newloc|gmx;
        }
    }

    # var.undef error - undefined variable: host.tag('contact_groups')
    if($tterror =~ m/var\.undef\ error\ -\ undefined\ variable:\s+(.*)$/mx) {
        my $err    = $1;
        my $linenr = 0;
        error($tterror);
        $already_printed = 1;
        my @lines = split/\n/mx, $template;
        for my $line (@lines) {
            $linenr++;
            if($line =~ m/\Q$err\E/mx) {
                my($realfile, $realline) = $self->_get_file_and_line_for_error(\@lines, $linenr);
                if($realfile) {
                    error('occurs in: '.$realfile.':'.$realline);
                }
            }
        }
    }

    error($tterror) unless $already_printed;
    debug('in template:');
    debug($template);
    trace($data) if $Monitoring::TT::Log::Verbose >= 4;
    exit 1;
}

#####################################################################
sub _get_file_and_line_for_error {
    my($self, $lines, $linenr) = @_;
    for(my $x = $linenr; $x >= 0; $x--) {
        if(defined $lines->[$x] and $lines->[$x] =~ m/SRC\s+(.*):(\d+)/mx) {
            my $diff   = $x - $2 + 1;
            return($1, ($linenr - $diff))
        }
    }
    return(undef, undef);
}

#####################################################################
sub _mkdir_r {
    my($self, $dir) = @_;
    my $path = '';
    for my $part (split/(\/)/mx, $dir) {
        $path .= $part;
        next if $path eq '';
        mkdir($path) unless -d $path;
    }
    return;
}

#####################################################################
sub _check_typos {
    my($self) = @_;
    for my $type (qw/hosts contacts/) {
        for my $o (@{$self->{'data'}->{$type}}) {
            if($o->{'type'} and $o->{'type'} ne 'contact') {
                warn('unused type \''.$o->{'type'}.'\' defined in '.$o->{'file'}.':'.$o->{'line'}) unless defined $self->{$type.'possible_types'}->{$o->{'type'}};
            }
            if($o->{'tags'}) {
                for my $t (keys %{$o->{'tags'}}) {
                    next if substr($t,0,1) eq '_';
                    warn('unused tag \''.$t.'\' defined in '.$o->{'file'}.':'.$o->{'line'}) unless defined $self->{$type.'possible_tags'}->{$t};
                }
            }
            if($o->{'apps'}) {
                for my $a (keys %{$o->{'apps'}}) {
                    warn('unused app \''.$a.'\' defined in '.$o->{'file'}.':'.$o->{'line'}) unless defined $self->{$type.'possible_apps'}->{$a};
                }
            }
        }
    }
    return;
}

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;
