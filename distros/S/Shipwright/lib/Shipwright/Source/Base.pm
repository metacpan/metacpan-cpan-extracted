package Shipwright::Source::Base;

use warnings;
use strict;
use File::Spec::Functions qw/catfile catdir/;
use File::Slurp;
use Module::CoreList;
use Shipwright::Source;
use Shipwright::Util;
use Cwd qw/getcwd/;
use File::Copy::Recursive qw/rcopy/;
use UNIVERSAL::require;

use base qw/Shipwright::Base/;
__PACKAGE__->mk_accessors(
    qw/source directory scripts_directory download_directory follow
      min_perl_version map_path skip map skip_recommends skip_all_recommends
      skip_installed include_dual_lifed
      keep_build_requires name log url_path version_path branches_path version
      skip_all_test_requires skip_all_build_requires installed 
      /
);

=head1 NAME

Shipwright::Source::Base - Base class of source

=head1 SYNOPSIS

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;
    $self->log( Log::Log4perl->get_logger( ref $self ) );
    return $self;
}

=head2 run

=cut

sub run {
    my $self = shift;
    my %args = @_;
    for ( $self->_cmd ) {
        if ( ref $_ eq 'CODE' ) {
            $_->();
        }
        else {
            run_cmd($_);
        }
    }
    $self->_copy( %{ $args{copy} } ) if $args{copy};
}

# you should subclass this method.
sub _cmd { }

sub _follow {
    my $self         = shift;
    my $path         = shift;
    my $cwd          = getcwd;
    my $require_path = catfile( $path, '__require.yml' );
    my $map          = {};
    my $url          = {};


    unless ( $self->min_perl_version ) {
        no warnings 'once';
        require Config;
        require version;
        my $version = version->new( $Config::Config{version} );
        $self->min_perl_version( $version->numify );
    }

    if ( -e $self->map_path ) {
        $map = load_yaml_file( $self->map_path );
    }

    if ( -e $self->url_path ) {
        $url = load_yaml_file( $self->url_path );
    }

    my @types = qw/requires configure_requires/;

    my $reverse_map = { reverse %$map };
    my $skip_recommends = $self->skip_recommends->{ $self->name }
      || ( $reverse_map->{ $self->name }
        && $self->skip_recommends->{ $reverse_map->{ $self->name } } )
      || $self->skip_all_recommends;
    push @types, 'recommends' unless $skip_recommends;
    push @types, 'test_requires' unless $self->skip_all_test_requires;
    push @types, 'build_requires' unless $self->skip_all_build_requires;

    if ( !-e $require_path ) {

        # if not found, we'll create one according to Build.PL or Makefile.PL
        my $require = {};
        chdir catdir($path);

        my $run_failed;
        if ( $path =~ /\bcpan-Bundle-(.*)/ ) {
            $self->log->info("$path is a CPAN Bundle distribution");

            my $file = $1;
            $file =~ s!-!/!;
            $file .= '.pm';

            # so it's a bundle module
            open my $fh, '<', 'MANIFEST' or confess_or_die "no manifest found: $!";
            while (<$fh>) {
                chomp;
                if (/$file/) {
                    $file = $_;
                    last;
                }
            }
            open $fh, '<', $file or confess_or_die "can't open $file: $!";
            my $flip;
            while (<$fh>) {
                chomp;
                next if /^\s*$/;

                if (/^=head1\s+CONTENTS/) {
                    $flip = 1;
                    next;
                }
                elsif (/^=(?!head1\s+CONTENTS)/) {
                    $flip = 0;
                }

                next unless $flip;
                my $info;
                if (/(.*?)-/) {

                    # things following '-' are comments which we don't want here
                    $info = $1;
                }
                else {
                    $info = $_;
                }
                my ( $module, $version ) = split /\s+/, $info;
                $require->{requires}{$module} = $version || 0;
            }

        }
        elsif ( -e 'Build.PL' ) {
            $self->log->info("$path is a Module::Build based distribution");

            run_cmd(
                [
                    $^X,               '-Mversion',
                    '-MModule::Build', '-MShipwright::Util::CleanINC',
                    'Build.PL'
                ],
                1, # don't die if this fails
            );
            run_cmd( [ $^X, 'Build.PL' ] ) if $? || !-e 'Build';
            if ( -e catfile( '_build', 'prereqs' ) ) {
                my $source = read_file( catfile( '_build', 'prereqs' ) )
                    or confess_or_die "can't read _build/prereqs: $!";
                my $eval = '$require = ' . $source;
                eval "$eval;1" or confess_or_die "eval error: $@";    ## no critic
            }
            else {
                # could be something else, e.g. Module::Build::Tiny
                $run_failed = 1;
            }

            run_cmd(
                [ $^X, 'Build', 'realclean', '--allow_mb_mismatch', 1 ] );
        }
        elsif ( -e 'Makefile.PL' ) {
            my $makefile = read_file('Makefile.PL')
              or confess_or_die "can't read Makefile.PL: $!";
            if ( $makefile =~ /inc::Module::Install/ ) {
                $self->log->info(
                    "$path is a Module::Install based distribution");

                # in case people call another file, which contains
                # keywords like requires, features, etc 
                # see Task::Plack for a real example
                while ( $makefile =~ /(do\s+(['"])(.*?)\2\s*;\s*$)/m ) {
                    my $line    = $1;
                    my $content = read_file($3);
                    $content  =~ s/^__END__$ .*//xsmg;
                    $makefile =~ s/$line/$content;/;
                }

  # PREREQ_PM in Makefile is not good enough for inc::Module::Install, which
  # will omit features(..). we'll put deps in features(...) into recommends part

                $makefile =~ s/^\s*requires(?!\w)/shipwright_requires/mg;
                $makefile =~ s/^\s*build_requires(?!\w)/shipwright_build_requires/mg;
                $makefile =~ s/^\s*configure_requires(?!\w)/shipwright_configure_requires/mg;
                $makefile =~
                  s/^\s*test_requires(?!\w)/shipwright_test_requires/mg;
                $makefile =~ s/^\s*recommends(?!\w)/shipwright_recommends/mg;
                $makefile =~ s/^\s*features(?!\w)/shipwright_features/mg;
                $makefile =~ s/^\s*feature(?!\w)/shipwright_feature/mg;
                $makefile =~
                    s/^\s*requires_from(?!\w)/shipwright_requires_from/mg;
                $makefile =~
                    s/^\s*test_requires_from(?!\w)/shipwright_test_requires_from/mg;
                my $shipwright_makefile = <<'EOF';
use Data::Dumper;
my $shipwright_req = {};

sub _shipwright_requires {
    my $type = shift;
    my %req  = @_;
    for my $name ( keys %req ) {
        $shipwright_req->{$type}{$name} = $req{$name};
    }
}

sub shipwright_requires {
    _shipwright_requires( 'requires', @_ == 1 ? ( @_, 0 ) : @_ );
    goto &requires;
}

sub shipwright_build_requires {
    _shipwright_requires( 'build_requires', @_ == 1 ? ( @_, 0 ) : @_ );
    goto &build_requires;
}

sub shipwright_configure_requires {
    _shipwright_requires( 'configure_requires', @_ == 1 ? ( @_, 0 ) : @_ );
    goto &configure_requires;
}

sub shipwright_test_requires {
    _shipwright_requires( 'test_requires', @_ == 1 ? ( @_, 0 ) : @_ );
    goto &test_requires;
}

sub _shipwright_requires_from {
    my $type = shift;
    my $file = shift;

    open my $fh, '<', $file or return;
    my $content = do { local $/; <$fh> };
# the following lines in this sub are mostly stolen from Module::Install::Metadata
    my @requires = $content =~ m/^use\s+([^\W\d]\w*(?:::\w+)*)\s+([\d\.]+)/mg;

    while ( @requires ) {
        my $module  = shift @requires;
        my $version = shift @requires;
        _shipwright_requires( $type, $module, $version || 0 );
    }
}

sub shipwright_test_requires_from {
    _shipwright_requires_from( 'test_requires', @_ );
    goto &test_requires_from;
}

sub shipwright_requires_from {
    _shipwright_requires_from( 'requires', @_ );
    goto &requires_from;
}

sub shipwright_recommends {
    _shipwright_requires( 'recommends', @_ == 1 ? ( @_, 0 ) : @_ );
    goto &recommends;
}

sub shipwright_feature {
    my ( $name, @mods ) = @_;
    my $type = $name && $name ne '-core' ? 'recommends' : 'requires';
    for ( my $i = 0 ; $i < @mods ; $i++ ) {
        if ( $mods[$i] eq '-default' ) {
            $i++;    # skip the -default value
        }
        elsif ( $mods[ $i + 1 ] =~ /^[\d\.]*$/ ) {

            # index $i+1 is a version
            $shipwright_req->{$type}{ $mods[$i] } = $mods[ $i + 1 ] || 0;
            $i++;
        }
        else {
            $shipwright_req->{$type}{ $mods[$i] } = 0;
        }
    }
    goto &feature;
}

sub shipwright_features {
    my @args = @_;
    while ( my ( $name, $mods ) = splice( @_, 0, 2 ) ) {
        my $type = $name && $name ne '-core' ? 'recommends' : 'requires';
        for ( my $i = 0; $i < @$mods; $i++ ) {
            if ( $mods->[$i] eq '-default' ) {
                $i++;
                next;
            }

            if ( ref $mods->[$i] eq 'ARRAY' ) {
# this happends when
# features(
#     'Date loading' => [
#         -default => 0,
#        recommends( 'DateTime' )
#     ],
# );
               for ( my $j = 0; $j < @{$mods->[$i]}; $j++ ) {
                    if ( ref $mods->[$i][$j] eq 'ARRAY' ) {
                        $shipwright_req->{$type}{$mods->[$i][$j][0]} 
                            = $mods->[$i][$j][1] || 0;
                    }
                    elsif ( $mods->[$i][$j+1] =~ /^[\d\.]*$/ ) {
                        $shipwright_req->{$type}{$mods->[$i][$j]} 
                            = $mods->[$i][$j+1] || 0;
                        $j++;
                    }
                    else {
                        $shipwright_req->{$type}{$mods->[$i][$j]} = 0;
                    }
                }
                
                next;
            }

            if ( $mods->[$i+1] =~ /^[\d\.]*$/ ) {
                # index $i+1 is a version
                $shipwright_req->{$type}{$mods->[$i]} = $mods->[$i+1] || 0;
                $i++;
            }
            else {
                $shipwright_req->{$type}{$mods->[$i]} = 0;
            }
        }
    }
    
    goto &features;
}

END {
open my $tmp_fh, '>', 'shipwright_prereqs';
print $tmp_fh Data::Dumper->Dump( [$shipwright_req], [qw/require/] );
}

EOF

                $shipwright_makefile .= $makefile;
                write_file( 'shipwright_makefile.pl', $shipwright_makefile );

                run_cmd(
                    [
                        $^X,
                        '-Mversion',
                        '-MShipwright::Util::CleanINC',
                        'shipwright_makefile.pl'
                    ],
                    1, # don't die if this fails
                );
                run_cmd( [ $^X, 'shipwright_makefile.pl' ] )
                  if $? || !-e 'Makefile';
                my $prereqs = read_file( catfile('shipwright_prereqs') )
                  or confess_or_die "can't read prereqs: $!";
                eval "$prereqs;1;" or confess_or_die "eval error: $@"; ## no critic

                if ( -e 'META.yml' ) {

                    # if there's META.yml, let's find more about it
                    my $meta = load_yaml_file('META.yml')
                      or confess_or_die "can't read META.yml: $!";

                # Module::Install will make test_requires into build_requires
                    for ( keys %{ $require->{test_requires} } ) {
                        delete $meta->{build_requires}{$_}
                          if exists $meta->{build_requires}{$_};
                    }

                    $require ||= {};
                    $require->{requires} = {
                        %{ $meta->{requires} || {} },
                        %{ $require->{requires} || {} },
                    };
                    $require->{recommends} = {
                        %{ $meta->{recommends} || {} },
                        %{ $require->{recommends} || {} },
                    };
                    $require->{build_requires} = {
                        %{ $meta->{build_requires}     || {} },
                        %{ $meta->{configure_requires} || {} },
                        %{ $require->{build_requires} || {} },
                    };
                    $require->{test_requires} = {
                        %{ $meta->{test_rquires} || {} },
                        %{ $require->{test_requires} || {} },
                    };

                }

                unlink 'shipwright_makefile.pl', 'shipwright_prereqs';
            }
            else {

                # we extract the deps from Makefile
                run_cmd(
                    [
                        $^X,
                        '-MShipwright::Util::CleanINC',
                        'Makefile.PL'
                    ],
                    1, # don't die if this fails
                );
                run_cmd( [ $^X, 'Makefile.PL' ] )
                  if $? || !-e 'Makefile';

                my @makefile = read_file('Makefile');
                my ($source) = grep { /PREREQ_PM/ } @makefile;
                if ( $source && $source =~ /({.*})/ ) {
                    my $eval .= '$require = ' . $1;
                    $eval =~ s/([\w:]+)=>/'$1'=>/g;
                    eval "$eval;1" or confess_or_die "eval error: $@";    ## no critic

                    for ( keys %$require ) {
                        $require->{requires}{$_} = delete $require->{$_};
                    }
                }

                my %requires_map = (
                    PREREQ_PM          => 'requires',
                    BUILD_REQUIRES     => 'build_requires',
                    TEST_REQUIRES      => 'test_requires',
                    CONFIGURE_REQUIRES => 'configure_requires',
                );

                for my $item ( keys %requires_map ) {
                    my ($source) = grep { /$item/ } @makefile;
                    if ( $source && $source =~ /({.*})/ ) {
                        my $tmp_requires;
                        my $eval .= '$tmp_requires = ' . $1;
                        $eval =~ s/([\w:]+)=>/'$1'=>/g;
                        eval "$eval;1" or confess_or_die "eval error: $@";    ## no critic

                        $require->{$requires_map{$item}} ||= {};
                        for ( keys %$tmp_requires ) {
                            $require->{$requires_map{$item}}{$_} = delete $tmp_requires->{$_};
                        }
                    }
                }

            }
            run_cmd(
                [ $ENV{SHIPWRIGHT_MAKE}, 'clean' ] );
            unlink 'Makefile.old';
        }

        if ( $run_failed ) {
            # read "require" from META.yml instead
            my $meta = load_yaml_file('META.yml') or confess_or_die "can't read META.yml: $!";
            for my $type ( keys %$meta ) {
                next unless $type =~ /requires|recommends/;
                $require->{$type} = $meta->{$type};
            }
        }

        for my $type ( @types ) {
            next unless $require->{$type};
            for my $module ( keys %{ $require->{$type} } ) {
                $require->{$type}{$module}{version} =
                  delete $require->{$type}{$module};
            }
        }

        dump_yaml_file( $require_path, $require )
          or confess_or_die "can't dump __require.yml: $!";
    }

    if ( my $require = load_yaml_file($require_path) ) {

       # if not have 'requires' key, all the keys in $require are supposed to be
       # requires type
        if ( !$require->{requires} ) {
            for my $module ( keys %$require ) {
                $require->{requires}{$module}{version} =
                  delete $require->{$module};
            }
        }

        for my $type ( @types ) {
            for my $module ( keys %{ $require->{$type} } ) {

#$module shouldn't be undefined, but it _indeed_ happens in reality sometimes
                next unless $module;
                # we don't want to require perl
                if ( $module eq 'perl' ) {
                    delete $require->{$type}{$module};
                    next;
                }

                my $version =
                  ref $require->{$type}{$module}
                  ? $require->{$type}{$module}{version}
                  : $require->{$type}{$module};
                $version ||= 0;
                $version =~ s!^\D+!!; # some may contain '>' or '>=' 
                if ( !$self->include_dual_lifed 
                    && Module::CoreList->first_release( $module, $version )
                    && Module::CoreList->first_release( $module, $version ) <= $self->min_perl_version
                    && ( !Module::CoreList->removed_from($module) || Module::CoreList->removed_from($module) > $self->min_perl_version) )
                {
                    $self->log->info("skipping $module because it's in core");
                    delete $require->{$type}{$module};
                    next;
                }

                if ( $self->skip_installed ) {
                    if ( $module->require ) {
                        $self->log->info("found installed $module");
                        no strict 'refs'; ## no critic
                        require version;
                        my $installed_version = ${ $module . '::VERSION' };
                        if ( $installed_version
                            && version->parse($installed_version) >=
                            version->parse($version) )
                        {
                            $self->log->info(
                                "skipping $module because it's installed" );
                            delete $require->{$type}{$module};
                            next;
                        }
                    }
                }

                my $name = $module;

                if ( $self->_is_skipped($module)
                    && !$self->_is_installed($module) )
                {

                    # skipped contains all modules imported before,
                    # so we need to check if they are imported ones
                    delete $require->{$type}{$module};
                    next;
                }
                else {

                    opendir my $dir, $self->directory;
                    my @sources = readdir $dir;
                    close $dir;

                    #reload map
                    if ( -e $self->map_path ) {
                        $map = load_yaml_file( $self->map_path );
                    }

                    if ( $map->{$module} && $map->{$module} =~ /^cpan-/ ) {
                        $name = $map->{$module};
                    }
                    else {

                        # assuming it's a CPAN module
                        $name =~ s/::/-/g;
                        $name = 'cpan-' . $name unless $name =~ /^cpan-/;
                    }

                    unless ( grep { $name eq $_ } @sources ) {
                        my $s;
                        my $cwd = getcwd;
                        chdir $self->directory;
                        if (   $require->{$type}{$module}{source}
                            && $require->{$type}{$module}{source} ne 'CPAN' )
                        {
                            $s = Shipwright::Source->new(
                                %$self,
                                source  => $require->{$type}{$module}{source},
                                name    => $name,
                                version => undef,
                                _path   => undef,
                            );
                        }
                        else {
                            $s = Shipwright::Source->new(
                                %$self,
                                source  => "cpan:$module",
                                version => undef,
                                name => '',   # cpan name is automaticaly fixed.
                                _path   => undef,
                            );
                        }
                        unless ($s->run()) { 
                            # if run returns false, we should skip trying to install it.
                            # this lets us skip explicit dependencies that are actually part of the perl core
                            delete $require->{$type}{$module};
                            chdir $cwd;
                            next;

                        }
                        chdir $cwd;
                    }

                    # reload map
                    if ( -e $self->map_path ) {
                        $map = load_yaml_file( $self->map_path );
                    }

                }

                # convert required module name to dist name like cpan-Jifty-DBI
                if ( $map->{$module} && $map->{$module} =~ /^cpan-/ ) {
                    $require->{$type}{ $map->{$module} } =
                      delete $require->{$type}{$module};
                }
                else {
                    $require->{$type}{$name} =
                      delete $require->{$type}{$module};
                }
            }
        }
        # don't keep recommends info if we skip them, so we won't encounter
        # them when update later
        $require->{recommends} = {} if $skip_recommends;
        $require->{test_requires} = {} if $self->skip_all_test_requires;
        $require->{build_requires} = {} if $self->skip_all_build_requires;

        dump_yaml_file( $require_path, $require );
    }
    else {
        confess_or_die "invalid __require.yml in $path";
    }

    # go back to the cwd before we run _follow
    chdir $cwd;
}

sub _update_map {
    my $self   = shift;
    my $module = shift;
    my $dist   = shift;

    my $map = {};
    if ( -e $self->map_path ) {
        $map = load_yaml_file( $self->map_path );
    }
    return if $map->{$module};

    $map->{$module} = $dist;
    dump_yaml_file( $self->map_path, $map );
}

sub _update_url {
    my $self = shift;
    my $name = shift;
    my $url  = shift;

    my $map = {};
    if ( -e $self->url_path && !-z $self->url_path ) {
        $map = load_yaml_file( $self->url_path );
    }
    $map->{$name} = $url;
    dump_yaml_file( $self->url_path, $map );
}

sub _update_version {
    my $self    = shift;
    my $name    = shift;
    my $version = shift;

    my $map = {};
    if ( -e $self->version_path && !-z $self->version_path ) {
        $map = load_yaml_file( $self->version_path );
    }
    $map->{$name} = $version;
    dump_yaml_file( $self->version_path, $map );
}

sub _update_branches {
    my $self     = shift;
    my $name     = shift;
    my $branches = shift;

    my $map = {};
    if ( -e $self->version_path && !-z $self->branches_path ) {
        $map = load_yaml_file( $self->branches_path );
    }
    $map->{$name} = $branches;
    dump_yaml_file( $self->branches_path, $map );
}

sub _is_skipped {
    my $self   = shift;
    my $module = shift;
    my $skip;

    if ( $self->skip ) {
        if ( $self->skip->{$module} ) {
            $skip = 1;
        }
        elsif ( grep { /-/ } keys %{ $self->skip } ) {

       # so we have a dist skip, we need to resolve the $module to the dist name
            my $source = Shipwright::Source->new( source => "cpan:$module" );
            $source->_run;
            my $name = $source->name;
            my ($name_without_prefix) = $name =~ /^cpan-(.*)/;
            $skip = 1
              if $self->skip->{$name} || $self->skip->{$name_without_prefix};
        }

        my @spaces = grep { /::$/ } keys %{$self->skip};
        for my $space ( @spaces ) {
            # we want to skip both Foo and Foo::*
            if ( "${module}::" =~ /^$space/ ) {
                $skip = 1;
                last;
            }
        }

        if ($skip) {
            $self->log->info("skipping $module");
            return 1;
        }
    }

    return;
}

sub _is_installed {
    my $self   = shift;
    my $module = shift;
    my $installed;

    my $name = $module;
    if ( $module !~ /-/ ) {
        my $source = Shipwright::Source->new( source => "cpan:$module" );
        $source->_run;
        $name = $source->name;
    }

    return $self->installed->{$name};
}

sub _copy {
    my $self = shift;
    my %file = @_;
    for ( keys %file ) {
        if ( $file{$_} ) {
            my $cmd = sub {
                rcopy(
                    $file{$_},
                    catfile(
                        $self->directory,
                        $self->name || $self->just_name( $self->path ), $_
                    )
                );
            };
            run_cmd($cmd);
        }
    }
}

=head2 just_name

trim the version stuff from dist name

=cut

sub just_name {
    my $self = shift;
    my $name = shift;

    $name =~ s/(?:tar\.bz2|zip)$/tar.gz/;    # CPAN::DistnameInfo likes .tar.gz

    $name .= '.tar.gz' unless $name =~ /(tar\.gz|tgz)$/;

    require CPAN::DistnameInfo;
    my $info = CPAN::DistnameInfo->new($name);
    my $dist = $info->dist;
    return $dist;
}

=head2 just_version

return version

=cut

sub just_version {
    my $self = shift;
    my $name = shift;
    $name .= '.tar.gz' unless $name =~ /\.(tar\.gz|tgz|tar\.bz2|zip)$/;

    require CPAN::DistnameInfo;
    my $info    = CPAN::DistnameInfo->new($name);
    my $version = $info->version;
    $version =~ s/^v// if $version;
    return $version;
}

=head2 is_compressed

return true if the source is compressed file, i.e. tar.gz(tgz) and tar.bz2

=cut

sub is_compressed {
    my $self = shift;
    return 1 if $self->source =~ m{\.(tar.(gz|bz2)|tgz|zip)$};
    return;
}

sub _lwp_get {
    my $self   = shift;
    my $source = shift;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy();
    $ua->timeout( $ENV{SHIPWRIGHT_LWP_TIMEOUT} )
      if $ENV{SHIPWRIGHT_LWP_TIMEOUT};

    if ( -e $self->source ) {
        my $size = -s $self->source;
        my $res  = $ua->head($source);
        if (   $res->is_success
            && $res->header('content-length') == $size )
        {
            return 1;
        }
    }

    my $response = $ua->get($source);

    if ( $response->is_success ) {
        open my $fh, '>', $self->source
          or confess_or_die "can't open file " . $self->source . ": $!";
        print $fh $response->content;
    }
    else {
        confess_or_die "failed to get $source: " . $response->status_line;
    }
}

1;

__END__

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

