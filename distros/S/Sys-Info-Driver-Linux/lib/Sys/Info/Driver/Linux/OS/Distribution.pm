package Sys::Info::Driver::Linux::OS::Distribution;
$Sys::Info::Driver::Linux::OS::Distribution::VERSION = '0.7905';
use strict;
use warnings;

use constant STD_RELEASE     => 'lsb-release';
use constant STD_RELEASE_DIR => 'lsb-release.d';
use constant DEBIAN_RELEASE  => 'os-release';
use constant STD_ETC_DIR     => '/etc';

use base qw( Sys::Info::Base );
use Carp qw( croak );
use Sys::Info::Driver::Linux;
use Sys::Info::Driver::Linux::Constants qw( :all );
use Sys::Info::Driver::Linux::OS::Distribution::Conf;
use File::Spec;

# XXX: <REMOVE>
my $RELX = sub {
    my $master = shift;
    my $t = sub {
        my($k, $v) = @_;
    return map { $_ => $v} ref $k ? @{$k} : ($k);
    };
    map  { $t->($CONF{$_}->{$master}, $_ ) }
    grep {      $CONF{$_}->{$master}       }
    keys %CONF
};

my %ORIGINAL_RELEASE = $RELX->('release');
my %DERIVED_RELEASE  = $RELX->('release_derived');
#</REMOVE>

sub new {
    my $class = shift;
    my %option;
    if ( @_ ) {
        die "Parameters must be in name => value format" if @_ % 2;
        %option = @_;
    }

    my $self  = {
        DISTRIB_ID          => q{},
        DISTRIB_NAME        => q{}, # workround field for new distros
        DISTRIB_RELEASE     => q{},
        DISTRIB_CODENAME    => q{},
        DISTRIB_DESCRIPTION => q{},
        release_file        => q{},
        pattern             => q{},
        PROBE               => undef,
        RESULTS             => undef,
        etc_dir             => STD_ETC_DIR,
        %option,
    };

    $self->{etc_dir} =~ s{[/]+$}{}xms;

    bless $self, $class;
    $self->_initial_probe;
    return $self;
}

sub raw_name     { return shift->{RESULTS}{raw_name} }
sub name         { return shift->{RESULTS}{name}     }
sub version      { return shift->{RESULTS}{version}  }
sub edition      { return shift->{RESULTS}{edition}  }
sub kernel       { return shift->{PROBE}{kernel}     }
sub build        { return shift->{PROBE}{build}      }
sub build_date   { return shift->{PROBE}{build_date} }
sub manufacturer {
    my $self = shift;
    my $slot = $CONF{ lc $self->raw_name } || return;
    return if ! exists $slot->{manufacturer};
    return $slot->{manufacturer};
}

sub _probe {
    my $self = shift;
    return $self->{RESULTS} if $self->{RESULTS};
    $self->{RESULTS}           = {};
    $self->{RESULTS}{name}     = $self->_probe_name;
    $self->{RESULTS}{raw_name} = $self->{RESULTS}{name};
    $self->{RESULTS}{version}  = $self->_probe_version;
    # this has to be last, since this also modifies the two above
    $self->{RESULTS}{edition}  = $self->_probe_edition;
    return $self->{RESULTS};
}

sub _probe_name {
    my $self   = shift;
    my $distro = $self->_get_lsb_info;
    return $distro if $distro;
    return $self->_probe_release( \%DERIVED_RELEASE  )
        || $self->_probe_release( \%ORIGINAL_RELEASE );
}

sub _probe_release {
    my($self, $r) = @_;

    foreach my $id ( keys %{ $r } ) {
        my $file = File::Spec->catfile( $self->{etc_dir}, $id );
        if ( -f $file && ! -l $file ) {
            $self->{DISTRIB_ID}   = $r->{ $id };
            $self->{release_file} = $id;
            return $self->{DISTRIB_ID};
        }
    }

    return;
}

sub _probe_version {
    my $self    = shift;
    my $release = $self->_get_lsb_info('DISTRIB_RELEASE');
    my $dist_id = $self->{DISTRIB_ID};

    if ( ! $dist_id && ! $self->name ) {
        # centos will return a string, but if couldn't detect the thing, it is
        # better to return that instead.
        return $release if $release;
        croak 'No version because no distribution';
    }

    my $slot = $CONF{ lc $dist_id };

    $self->{pattern} = exists $slot->{version_match}
                        ? $slot->{version_match}
                        : q{};

    # There might be an override
    local $self->{release_file} = $slot->{release}
        if $slot->{release};

    my $vrelease = $self->_get_file_info;

    # Set to the original if we got any, othwerwise try the version
    $self->{DISTRIB_RELEASE} = $release || $vrelease;

    # Opposite of above as we want a version number
    # if we were able locate one
    return $vrelease || $release;
}

sub _probe_edition {
    my $self = shift;
    my $p    = $self->{PROBE};

    if ( my $dn = $self->name ) {
        my $n = $self->{DISTRIB_NAME} || do {
            my $slot = $CONF{ $dn };
            exists $slot->{name} ? $slot->{name} : ucfirst $dn;
        };
        $dn  = $self->trim( $n );
        $dn .= ' Linux' if $dn !~ m{Linux}xmsi;
        $self->{RESULTS}{name} = $dn;
    }
    else {
        $self->{RESULTS}{name}    = $p->{distro};
        $self->{RESULTS}{version} = $p->{kernel};
    }

    my $name     = $self->name;
    my $raw_name = $self->raw_name;
    my $version  = $self->version;
    my $slot     = $CONF{$raw_name} || return;
    my $edition  = exists $slot->{edition} ? $slot->{edition}{ $version } : undef;

    if ( ! $edition ) {
        if ( $version && $version !~ m{[0-9]}xms ) {
            if ( $name =~ m{debian}xmsi ) {
                my @buf = split m{/}xms, $version;
                if ( my $test = $CONF{debian}->{vfix}{ lc $buf[0] } ) {
                    # Debian version comes as the edition name
                    $edition = $version;
                    $self->{RESULTS}{version} = $test;
                }
            }
        }
        else {
            if (   $slot->{use_codename_for_edition}
                && $self->{DISTRIB_CODENAME}
            ) {
                my $cn = $self->{DISTRIB_CODENAME};
                $edition = $cn if $cn !~ m{[0-9]}xms;
            }
        }
    }

    return $edition;
}

sub _initial_probe {
    my $self    = shift;
    my $version = q{};

    if (  -e proc->{version} && -f _) {
        $version =  $self->trim(
                        $self->slurp(
                            proc->{version},
                            'I can not open linux version file %s for reading: '
                        )
                    );
    }

    my($str, $build_date) = split /\#/xms, $version;
    my($kernel, $distro)  = (q{},q{});

    #$build_date = "1 Fri Jul 23 20:48:29 CDT 2004';";
    #$build_date = "1 SMP Mon Aug 16 09:25:06 EDT 2004";
    $build_date = q{} if not $build_date; # running since blah thingie

    if ( $str =~ RE_LINUX_VERSION || $str =~ RE_LINUX_VERSION2 ) {
        $kernel = $1;
        if ( $distro = $self->trim( $2 ) ) {
            if ( $distro =~ m{ \s\((.+?)\)\) \z }xms ) {
                $distro = $1;
            }
        }
    }

    $distro = 'Linux' if ! $distro || $distro =~ m{\(gcc}xms;

    # kernel build date
    $build_date = $self->date2time($build_date) if $build_date;
    my $build   = $build_date ? localtime $build_date : q{};

    $self->{PROBE} = {
        version    => $version,
        kernel     => $kernel,
        build      => $build,
        build_date => $build_date,
        distro     => $distro,
    };

    $self->_probe;
    return;
}

sub _get_lsb_info {
    my $self  = shift;
    my $field = shift || 'DISTRIB_ID';
    my $tmp   = $self->{release_file};

    my($rfile) = grep { -r $_->[1] }
                map  {
                    [ $_ => File::Spec->catfile( $self->{etc_dir}, $_ ) ]
                }
                STD_RELEASE,
                DEBIAN_RELEASE
                ;

    if ( $rfile ) {
        $self->{release_file} = $rfile->[0];
        $self->{pattern}      = $field . '=(.+)';
        my $info = $self->_get_file_info;
        return $self->{$field} = $info if $info;
    }
    else {
        # CentOS6+? RHEL? Any new distro?
        my $dir = File::Spec->catdir( $self->{etc_dir}, STD_RELEASE_DIR );
        if ( -d $dir ) {
            my $rv = join q{: },
                     map  { m{$dir/(.*)}xms ? $1 : () }
                     grep { $_ !~ m{ \A [.] }xms }
                     glob "$dir/*";
            $self->{LSB_VERSION} = $rv if $rv;
        }
        my($release) = do {
            if ( my @files = glob $self->{etc_dir} . "/*release" ) {
                my($real) = sort grep { ! -l } @files;
                my %uniq  = map { $self->trim( $self->slurp( $_ ) ) => 1 }
                            @files;
                if ( $real ) {
                    my $etc = $self->{etc_dir};
                    ($self->{release_file} = $real) =~ s{$etc/}{}xms;
                    $self->{pattern}       = '(.+)';
                }
                keys %uniq;
            }
        };

        return if ! $release; # huh?

        my($rname) = split m{\-}xms, $self->{release_file};
        my($distrib_id, @rest)  = split m{release}xms, $release, 2;
        my($version, $codename) = split m{ \s+   }xms, $self->trim( join ' ', @rest ), 2;
        $codename   =~ s{[()]}{}xmsg if $codename;
        $distrib_id = $self->trim( $distrib_id );
        $self->{DISTRIB_DESCRIPTION} = $release;
        $self->{DISTRIB_ID}          = $rname || $distrib_id;
        $self->{DISTRIB_NAME}        = $distrib_id;
        $self->{DISTRIB_RELEASE}     = $version;
        $self->{DISTRIB_CODENAME}    = $codename || q{};

        # fix stupidity
        if (   $self->{DISTRIB_ID}
            && $self->{DISTRIB_ID} eq 'redhat'
            && $self->{DISTRIB_NAME}
            && index($self->{DISTRIB_NAME}, 'CentOS') != -1
        ) {
            $self->{DISTRIB_ID} = 'centos';
        }

        return $self->{ $field } if $self->{ $field };
    }

    $self->{release_file} = $tmp;
    $self->{pattern}      = q{};
    return;
}

sub _get_file_info {
    my $self = shift;
    my $file = File::Spec->catfile( $self->{etc_dir}, $self->{release_file} );
    require IO::File;
    my $FH = IO::File->new;
    $FH->open( $file, '<' ) || croak "Can't open $file: $!";
    my @raw = <$FH>;
    $FH->close || croak "Can't close FH($file): $!";
    my $new_pattern =
          $self->{pattern} =~ m{ \A DISTRIB_ID      \b }xms ? '^ID=(.+)'
        : $self->{pattern} =~ m{ \A DISTRIB_RELEASE \b }xms ? '^PRETTY_NAME=(.+)'
        : undef;
    my $rv;
    foreach my $line ( @raw ){
        chomp $line;
        next if ! $line;

        ## no critic (RequireExtendedFormatting)
        my($info) = $line =~ m/$self->{pattern}/ms;
        if ( $info ) {
            $rv = "\L$info";
            last;
        }
        elsif ( $new_pattern ) {
            ## no critic (RequireExtendedFormatting)
            my($info2) = $line =~ m/$new_pattern/ms;
            if ( $info2 ) {
                $rv = "\L$info2";
                last;
            }
        }
    }

    if ( $rv ) {
        $rv =~ s{ \A ["]    }{}xms;
        $rv =~ s{    ["] \z }{}xms;
    }

    return $rv;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::Driver::Linux::OS::Distribution

=head1 VERSION

version 0.7905

=head1 SYNOPSIS

    use Sys::Info::Driver::Linux::OS::Distribution;
    my $distro = Sys::Info::Driver::Linux::OS::Distribution->new;
    my $name   = $distro->name;
    if( $name ) {
        my $version = $distro->version;
        print "you are running $distro, version $version\n";
    }
    else {
        print "distribution unknown\n";
    }

=head1 DESCRIPTION

This is a simple module that tries to guess on what linux distribution
we are running by looking for release's files in /etc.  It now looks for
'lsb-release' first as that should be the most correct and adds ubuntu support.
Secondly, it will look for the distro specific files.

It currently recognizes slackware, debian, suse, fedora, redhat, turbolinux,
yellowdog, knoppix, mandrake, conectiva, immunix, tinysofa, va-linux, trustix,
adamantix, yoper, arch-linux, libranet, gentoo, ubuntu and redflag.

It has function to get the version for debian, suse, redhat, gentoo, slackware,
redflag and ubuntu(lsb). People running unsupported distro's are greatly
encouraged to submit patches.

=head1 NAME

Sys::Info::Driver::Linux::OS::Distribution - Linux distribution probe

=head1 METHODS

=head2 build

=head2 build_date

=head2 edition

=head2 kernel

=head2 manufacturer

=head2 name

=head2 new

=head2 raw_name

=head2 version

=head1 TODO

Add the capability of recognize the version of the distribution for all
recognized distributions.

=head1 Linux::Distribution AUTHORS

Some parts of this module were originally taken from C<Linux::Distribution>
and it's authors are:

    Alberto Re       E<lt>alberto@accidia.netE<gt>
    Judith Lebzelter E<lt>judith@osdl.orgE<gt>
    Alexandr Ciornii E<lt>alexchorny@gmail.com<gt>

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
