use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::distsignature
{
    return <<'EOT';
distsignature : distmeta
	$(NOECHO) ./dev/cleanup.pl
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '	  or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s
EOT
}

my %WriteMakefileArgs = (
    NAME                => 'Module::Generic',
    AUTHOR              => 'Jacques Deguest <jack@deguest.jp>',
    VERSION_FROM        => 'lib/Module/Generic.pm',
    ABSTRACT_FROM       => 'lib/Module/Generic.pm',
    PL_FILES            => {},
    PREREQ_PM           => {
        'common::sense'         => 0,
        'overload'              => 0,
        'overloading'           => 0,
        'parent'                => 0,
        'strict'                => 0,
        'utf8'                  => 0,
        'version'               => 0,
        'warnings'              => 0,
        'Class::Load'           => '0.25',
        'Clone'                 => '0.43',
        'Config'                => 0,
        'Data::Dump'            => '1.23',
        'Data::UUID'            => '1.226',
        'DateTime'              => '1.57',
        'DateTime::Format::Strptime' => '1.79',
        'DateTime::TimeZone'    => '2.51',
        'DateTime::TimeZone::Catalog::Extend' => 'v0.3.0',
        'Devel::StackTrace'     => 0,
        'Errno'                 => 0,
        'Encode'                => 0,
        'Exporter'              => '5.70',
        # Used to require 1.13, but removed any requirement
        'Fcntl'                 => 0,
        'File::Basename'        => '2.85',
        # Previously requiring 2.34, but removing any requirement. Let's see.
        'File::Copy'            => 0,
        # Same as File::Copy, this is a core module
        'File::DosGlob'         => 0,
        'File::Glob'            => 0,
        # Only load it, if it exists
        # 'File::MMagic::XS' => '0.09008',
        'File::MMagic'          => '1.30',
        'File::Spec'            => '3.73',
        # Core module
        'I18N::Langinfo'        => '0.17',
        'IO::Dir'               => '1.41',
        'IO::File'              => '1.41',
        'IO::Scalar'            => '2.113',
        'IPC::SysV'             => '2.09',
        'JSON'                  => '4.03',
        'JSON::XS'              => '4.03',
        'List::Util'            => '1.56',
        'Module::Metadata'      => '1.000037',
        'POSIX'                 => '1.53_01',
        'Regexp::Common'        => '2017060201',
        'Scalar::Util'          => '1.50',
        'Storable::Improved'    => 'v0.1.3',
        'Sub::Util'             => '1.54',
        'Tie::Hash'             => '1.05',
        'URI::Escape'           => '5.09',
        'URI::file'             => '5.09',
        'Wanted'                => 'v0.1.0',
    },
    TEST_REQUIRES =>
    {
        'Bytes::Random::Secure' => '0.29',
        'Cwd'           => '3.72',
        'Encode'        => '3.08',
        'File::Find'    => 0,
        'File::Which'   => '1.23',
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
        'Test::Time'    => 0,
        'Test2::IPC'    => '1.302190',
        'Test2::V0'     => '0.000145',
        'utf8'          => 0,
        'open'          => 0,
    },
    LICENSE             => 'perl_5',
    # 2018-06-23
    MIN_PERL_VERSION    => 'v5.28.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 't/test_empty.csv t/test_out.csv' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Module-Generic.git',
                web         => 'https://gitlab.com/jackdeguest/Module-Generic',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Module-Generic/issues',
            },
        },
    }) : ()),
);

# NOTE: Apache2 test units preparation
# The rest below is for tests under Apache/modperl2
eval
{
    require Apache::TestMM;
};

my @scripts = ();

# The user can pass the environment variable 'NO_MOD_PERL' to explicitly state there is no modperl, and 'MG_DEBUG' as a debug level for the Apache/modperl unit tests

my $MY_DEBUG = $ENV{MG_DEBUG} // 0;
if( !$@ && !$ENV{NO_MOD_PERL} )
{
    print( STDERR "Generating Makefile including modperl\n" ) if( $MY_DEBUG );
    Apache::TestMM->import( qw(test clean) ); #enable 'make test'
    $WriteMakefileArgs{PREREQ_PM}->{ 'Apache::Test' } = 0;

    @scripts = qw( t/TEST );
    # accept the configs from command line
    Apache::TestMM::filter_args();
    my $ref = {@Apache::TestMM::Argv};
    $ref->{_HAS_APACHE_TEST} = 1;

    my $config = Apache::TestConfig->thaw->httpd_config;
    my( $has_ssl, $has_perl_ssl, $has_error ) = ( 0, '', 0 );
    $ref->{_HAS_SSL} = 0;
    # require Data::Pretty;
    if( $MY_DEBUG > 2 )
    {
        require Data::Pretty;
        print( STDERR "Apache::TestConfig->thaw->httpd_config yields: ", Data::Pretty::dump( $config ), "\n" );
    }
    if( ref( $config ) eq 'Apache::TestConfig' )
    {
        $has_ssl = $config->{modules}->{ $config->{vars}->{ssl_module} } ? 1 : 0;
        my $apache_bin = $config->{vars}->{httpd};
        if( !$apache_bin )
        {
            local $@;
            eval
            {
                require File::Which;
            };
            if( !$@ )
            {
                for( qw( apache2 httpd ) )
                {
                    if( $apache_bin = File::Which::which( $_ ) )
                    {
                        print( STDERR "Found Apache binary at $apache_bin" ) if( $MY_DEBUG );
                        last;
                    }
                }
            }
        }

        my $cmd = '';
        if( $apache_bin )
        {
            print( STDERR "Checking Apache2 configuration with binary $apache_bin\n" ) if( $MY_DEBUG );
            $cmd .= ". $config->{vars}->{conf_dir}/envvars; " if( $config->{vars}->{conf_dir} && -e( "$config->{vars}->{conf_dir}/envvars" ) );
            $cmd .= $apache_bin;
            open( my $io, "${cmd} -M 2>&1|" );
            while( <$io> )
            {
                print( STDERR $_ ) if( $MY_DEBUG );
                $has_ssl++, last if( /ssl/i );
                if( /Syntax[[:blank:]]+error[[:blank:]]+(?:on|at)[[:blank:]]+line[[:blank:]]+(\d+)/i )
                {
                    $has_error = $1;
                }
            }
            close( $io );
            print( STDERR "# Done\n" ) if( $MY_DEBUG );
        }
        warn( "[warning] You have syntax error in your Apache configuration file at line $has_error. You might want to do an apache2ctl configtest or (${cmd} -t)\n" ) if( $has_error );

        print( STDERR "Checking for SSL modules IO::Socket::SSL or Net::SSL\n" ) if( $MY_DEBUG );
        # IO::Socket::SSL or Net::SSL
        local $@;
        eval( 'require IO::Socket::SSL' );
        if( $@ )
        {
            my $io_ssl_err = $@;
            eval( 'require Net::SSL' );
            unless( $@ )
            {
                $has_perl_ssl = 'Net::SSL';
            }
        }
        else
        {
            $has_perl_ssl = 'IO::Socket::SSL';
        }

        if( $has_ssl && $has_perl_ssl )
        {
            print( STDERR "Found Apache module mod_ssl enabled and $has_perl_ssl module installed. Ok\n" ) if( $MY_DEBUG );
            $ref->{_HAS_SSL} = 1;
        }
        elsif( $has_ssl && !$has_perl_ssl )
        {
            print( STDERR "Found Apache module mod_ssl enabled, but missing perl modules (either IO::Socket::SSL or Net::SSL)\n" ) if( $MY_DEBUG );
        }
        elsif( !$has_ssl && $has_perl_ssl )
        {
            print( STDERR "Apache module mod_ssl is not enabled, but found $has_perl_ssl\n" ) if( $MY_DEBUG );
        }
        else
        {
            print( STDERR "Apache module mod_ssl is not enabled and could not find either IO::Socket::SSL nor Net::SSL, deactivating the use of SSL for our tests.\n" ) if( $MY_DEBUG );
        }
    }

    print( STDERR "apxs specified? ", ( $ref->{apxs} ? "yes at $ref->{apxs}" : 'no' ), "\n" ) if( $MY_DEBUG );
    if( !$ref->{apxs} )
    {
        my $apxs;
        local $@;
        eval
        {
            require Apache2::BuildConfig;
            require File::Spec;
            require File::Which;
        };
        # perl -MApache2::BuildConfig -MData::Pretty -lE 'my $c=Apache2::BuildConfig->new; say Data::Pretty::dump($c)'
        if( !$@ )
        {
            my $build = Apache2::BuildConfig->new;
            $apxs = File::Spec->catfile( $build->{APXS_BINDIR}, 'apxs' ) if( $build->{APXS_BINDIR} );
            undef( $apxs ) unless( -e( $apxs ) );
            print( STDERR "Found apxs at $apxs\n" ) if( $MY_DEBUG );
        }

        if( !$apxs )
        {
            local $@;
            eval
            {
                require File::Which;
            };
            if( !$@ && ( $apxs = File::Which::which( 'apxs' ) ) )
            {
                $ref->{apxs} = $apxs;
                print( STDERR "Found apxs at $apxs" ) if( $MY_DEBUG );
            }
        }

        if( $apxs )
        {
            print( STDERR "apxs found and set to $apxs\n" ) if( $MY_DEBUG );
            $ref->{apxs} = $apxs;
        }
        else
        {
            die( "You have not provided the arguement -apxs and the apxs binary could not be found. Maybe you need to install apache2-dev?\n" );
        }
    }

    if( !$ref->{httpd_conf} )
    {
        DEFAULT_APACHE_CONF_CHECK:
        {
            local $@;
            eval
            {
                require File::Spec;
                require IO::File;
            };
            print( STDERR "Error trying to load File::Spec and IO::File: $@\n" ) if( $@ && $MY_DEBUG );
            last DEFAULT_APACHE_CONF_CHECK if( $@ );
            my $base;
            # http://httpd.apache.org/docs/2.0/platform/windows.xml
            my @possible_bases = ();
            if( $^O eq 'linux' || $^O eq 'darwin' )
            {
                push( @possible_bases, File::Spec->catfile( File::Spec->rootdir, qw( usr local apache2 ) ) );
                push( @possible_bases, File::Spec->catfile( File::Spec->rootdir, qw( etc apache2 ) ) );
            }
            elsif( $^O eq 'win32' )
            {
                # C:\Program Files\Apache Group\Apache2
                push( @possible_bases, File::Spec->catfile( File::Spec->rootdir, 'Program Files', 'Apache Group', 'Apache2' ) );
            }

            foreach my $path ( @possible_bases )
            {
                if( -e( $path ) && -d( $path ) && -x( $path ) )
                {
                    $base = $path;
                    last;
                }
            }
            print( STDERR "Existing Apache base installation path found: '$base'\n" ) if( $MY_DEBUG );
            last DEFAULT_APACHE_CONF_CHECK if( !length( $base ) );

            my $f = File::Spec->catfile( $base, 'apache2.conf' );
            my $old = File::Spec->catfile( $base, 'httpd.conf' );
            my $env = File::Spec->catfile( $base, 'envvars' );
            if( -e( $f ) && -r( $f ) )
            {
                print( STDERR "Found an Apache configuration at '$f'\n" ) if( $MY_DEBUG );
                if( -e( $env ) && -r( $env ) && ( $^O eq 'darwin' || $^O eq 'linux' ) )
                {
                    print( STDERR "Found an Apache environment variables setup at '$env'\n" ) if( $MY_DEBUG );
                    my $fh;
                    # Credits: <https://stackoverflow.com/a/3836009/4814971>
                    if( defined( $fh = IO::File->new( "sh -x $env 2>&1 1>/dev/null|" ) ) )
                    {
                        my $vars = {};
                        while( defined( $_ = $fh->getline ) )
                        {
                            chomp;
                            if( /^[[:blank:]\h]*\+[[:blank:]\h]+(?:export[[:blank:]\h]+)?(\w+)\=(.*?)$/ )
                            {
                                next unless( substr( $1, 0, 7 ) eq 'APACHE_' );
                                $vars->{ $1 } = $ref->{ "_$1" } = $2;
                            }
                        }
                        $fh->close;
                        printf( STDERR "%d Apache environment variables found: %s\n", scalar( keys( %$vars ) ), join( ', ', sort( keys( %$vars ) ) ) );
                        my $tmpdir = File::Spec->tmpdir();
                        my $new = File::Spec->catfile( $tmpdir, 'httpd_for_cookies.conf' );
                        if( scalar( keys( %$vars ) ) &&
                            -w( $tmpdir ) && 
                            defined( $fh = IO::File->new( "<$f" ) ) )
                        {
                            my $conf = do{ local $/; $/ = undef; <$fh> };
                            my $regex = join( '|', keys( %$vars ) );
                            $conf =~ s
                            {
                                \$\{?($regex)\}?
                            }
                            {
                                $vars->{ $1 };
                            }xgems;
                            # $conf =~ s,(Include|IncludeOptional)[[:blank:]\h]+(.*?),$1 $base/$2,gs;
                            unless( $conf =~ /^ServerRoot[[:blank:]\h](.*?)/m )
                            {
                                $conf = qq{ServerRoot "$base"} . "\n" . $conf;
                            }
                            my $out;
                            # egrep -Ev '#' /etc/apache2/apache2.conf|egrep -Ev '^[[:blank:]]*$'
                            if( defined( $fh = IO::File->new( ">$new" ) ) )
                            {
                                print( $fh $conf );
                                close( $fh );
                            }
                            if( -s( $new ) > 0 )
                            {
                                $ref->{httpd_conf} = $new;
                                push( @scripts, $new );
                                print( STDERR "All went well; using \"$new\" as the temporary Apache configuration file\n" ) if( $MY_DEBUG );
                            }
                            else
                            {
                                print( STDERR "Resulting temporary Apache configuration file \"$new\" seems empty. Falling back to \"$f\"\n" ) if( $MY_DEBUG );
                                $ref->{httpd_conf} = $f;
                            }
                        }
                        else
                        {
                            print( STDERR "Could not read Apache configuration file \"$f\", or there was no environment variables found, or the temporary directory \"$tmpdir\" is not writable.\n" ) if( $MY_DEBUG );
                            $ref->{httpd_conf} = $f;
                        }
                    }
                    else
                    {
                        print( STDERR "Failed to execute sh -x $env: $!" ) if( $MY_DEBUG );
                        $ref->{httpd_conf} = $f;
                    }
                }
                # No /etc/apache2/envvars file
                else
                {
                    print( STDERR "No usable $env file found.\n" ) if( $MY_DEBUG );
                    $ref->{httpd_conf} = $f;
                }
            }
        };
        @Apache::TestMM::Argv = %$ref;
        print( STDERR "Apache::TestMM::Argv is now: '", join( "', '", @Apache::TestMM::Argv ), "'\n" ) if( $MY_DEBUG );
    }

    # Set the necessary environment variable we stored in Apache::TestConfig::Argv in our Makefile.PL
    # We had to do a round-about way to achieve this, because there is no clean easy way with current Apache::Test version to achieve this
    open( my $fh, '>./t/env.pl' ) || die( "t/env.pl: $!\n" );
    foreach my $k ( sort( keys( %$ref ) ) )
    {
        if( substr( $k, 0, 1 ) eq '_' )
        {
            # print( STDERR "Setting environment variable \"", substr( $k, 1 ), "\"\n" );
            $ENV{ substr( $k, 1 ) } = $ref->{ $k };
            $fh->printf( "\$ENV{ '%s' } = q|%s|;\n", substr( $k, 1 ), $ref->{ $k } ) || die( "t/env.pl: $!\n" );
        }
    }
    $fh->print( "\n1;\n" ) || die( "t/env.pl: $!\n" );
    $fh->close;

    if( $ENV{MG_DEBUG} )
    {
        my $extra = File::Spec->catfile( qw( t conf options.conf.in ) );
        my $fh;
        if( defined( $fh = IO::File->new( ">$extra" ) ) )
        {
            $fh->print( "PerlSetVar MG_DEBUG ", int( $ENV{MG_DEBUG} ), "\n" );
            $fh->close;
        }
    }
    Apache::TestMM::generate_script( 't/TEST' );
}
else
{
    print( STDERR "Generating Makefile without modperl\n" ) if( $MY_DEBUG );
}

WriteMakefile(%WriteMakefileArgs);

sub clean_files
{
    return( [@scripts] );
}
