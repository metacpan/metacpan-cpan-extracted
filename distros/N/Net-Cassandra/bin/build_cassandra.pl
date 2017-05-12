#!/home/acme/perl-5.10.0/bin//perl
use strict;
use warnings;
use Cwd;
use File::Find::Rule;
use LWP::Simple;
use Perl6::Say;
use Path::Class;
use PPI;
use PPI::Find;

my $thrift_trunk_dir = dir( cwd, 'thrift-trunk' );
my $thrift_trunk_configure = file( $thrift_trunk_dir, 'configure' );
my $thrift_trunk_makefile  = file( $thrift_trunk_dir, 'Makefile' );
my $thrift_trunk_thrift
    = file( $thrift_trunk_dir, 'compiler', 'cpp', 'thrift' );
my $thrift_installed_dir = dir( cwd, 'thrift' );
my $cassandra_trunk_dir  = dir( cwd, 'apache-cassandra-incubating-0.5.0-src' );
my $cassandra_class
    = dir( $cassandra_trunk_dir, 'build', 'classes', 'org', 'apache',
    'cassandra', 'service', 'CassandraDaemon.class' );
my $gen_perl_dir    = dir( cwd, 'gen-perl' );
my $perl_dir        = dir( cwd, 'lib', 'Net', 'Cassandra', 'Backend' );
my $thrift_perl_dir = dir( cwd, 'thrift-trunk', 'lib', 'perl', 'lib' );

unless ( -d $thrift_trunk_dir ) {
    say 'Fetching Thrift';
    system
        "svn co http://svn.apache.org/repos/asf/incubator/thrift/trunk $thrift_trunk_dir";
    die 'Failed to svn co' unless -d $thrift_trunk_dir;

}

unless ( -f $thrift_trunk_configure ) {
    say 'Bootstrapping Thrift';
    chdir $thrift_trunk_dir;
    system('./bootstrap.sh');
    die 'Failed to configure' unless -f $thrift_trunk_configure;
}

unless ( -f $thrift_trunk_makefile ) {
    say 'Configuring Thrift';
    chdir $thrift_trunk_dir;
    system("./configure --prefix=$thrift_installed_dir");
    die 'Failed to configure' unless -f $thrift_trunk_makefile;
}

unless ( -f $thrift_trunk_thrift ) {
    say 'Making Thrift';
    chdir $thrift_trunk_dir;
    system('make');
    die 'Failed to make' unless -f $thrift_trunk_thrift;
}

unless ( -d $thrift_installed_dir ) {
    say 'Make installing Thrift';
    chdir $thrift_trunk_dir;
    system('make install');
    die 'Failed to make' unless -d $thrift_installed_dir;
}

unless ( -d $cassandra_trunk_dir ) {
    say 'Fetching Cassandra';
    die "Fetch cassandra and put it in $cassandra_trunk_dir";
    system
        "svn checkout http://svn.apache.org/repos/asf/incubator/cassandra/trunk $cassandra_trunk_dir";
    die 'Failed to fetch' unless -d $cassandra_trunk_dir;
}

unless ( -f $cassandra_class ) {
    say 'Building Cassandra';
    chdir $cassandra_trunk_dir;
    system "ant";
    die 'Failed to build' unless -f $cassandra_class;
}

unless ( -d $gen_perl_dir ) {
    say 'Generating Perl bindings';
    system
        "$thrift_installed_dir/bin/thrift --gen perl $cassandra_trunk_dir/interface/cassandra.thrift";
    die 'Failed to generate' unless -d $gen_perl_dir;
}

unless ( -f $cassandra_class ) {
    say 'Building Cassandra';
    chdir $cassandra_trunk_dir;
    system "ant";
    die 'Failed to build' unless -f $cassandra_class;
}

# my $gen_perl_dir = dir( cwd, 'gen-perl' );
# my $perl_dir = dir(cwd, 'lib', 'Net', 'Cassandra', 'Backend');

unless ( -f "$perl_dir/Cassandra.pm" ) {
    say 'Munging Cassandra Perl modules';

    # first let's find the package names
    my %packages;
    foreach my $source ( File::Find::Rule->new->file->name('*.pm')
        ->in( $gen_perl_dir, $thrift_perl_dir ) )
    {

        # say "$source";
        my $document = PPI::Document->new($source);
        my $find
            = PPI::Find->new( sub { $_[0]->isa('PPI::Statement::Package') } );
        $find->start($document) or die "Failed to execute search";
        while ( my $package = $find->match ) {
            # say $package->namespace;
            $packages{ $package->namespace } = 1;
        }
    }
    
    $packages{'Cassandra::Types'}  = 1;    # fake
    $packages{'Thrift'} = 1;    # fake
    $packages{'Thrift::Socket'} = 1;    # fake
    $packages{'Thrift::ServerTransport'} = 1;    # fake
        
    # now fix up the new package names
    foreach my $source ( File::Find::Rule->new->file->name('*.pm')
        ->in( $gen_perl_dir, $thrift_perl_dir ) )
    {
        my $destination = file( $perl_dir, file($source)->basename );
        if ( $source =~ m{/Thrift/} ) {
            $destination =~ s{/([^/]+?)$}{/Thrift/$1};
        }
        say "$source -> $destination";

        my $document = PPI::Document->new($source);

        # first change the words
        my $find = PPI::Find->new( sub { $_[0]->isa('PPI::Token::Word') } );
        $find->start($document) or die "Failed to execute search";
        while ( my $word = $find->match ) {
            my $namespace = $word->content;

            if ( $packages{$namespace} ) {
                $namespace =~ s/^Cassandra:://;
                $namespace = 'Net::Cassandra::Backend::' . $namespace;
                $word->set_content($namespace);

                #say "* $word";
            } else {
                my ( $pre, $post ) = split( '::', $namespace, 2 );
                if ( $packages{$pre} ) {
                    $namespace
                        = 'Net::Cassandra::Backend::' . $pre . '::' . $post;
                    $word->set_content($namespace);

                    # say "* $word";
                }

                #say $word;
            }
        }

        # now try quotes
        $find = PPI::Find->new( sub { $_[0]->isa('PPI::Token::Quote') } );
        $find->start($document) or die "Failed to execute search";
        while ( my $word = $find->match ) {
            my $namespace = $word->content;
            $namespace =~ s/^'//;
            $namespace =~ s/'$//;
            if ( $packages{$namespace} ) {
                $namespace = 'Net::Cassandra::Backend::' . $namespace;
                $word->set_content( "'" . $namespace . "'" );

                #say "** $word" if $namespace =~ /TExcept/;
            } else {

                #say "?? $word" if $namespace =~ /TExcept/;
            }
        }
        
               # now try qw
        $find = PPI::Find->new( sub { $_[0]->isa('PPI::Token::QuoteLike::Words') } );
        $find->start($document) or die "Failed to execute search";
        while ( my $word = $find->match ) {
            my $namespace = $word->content;
            $namespace =~ s/^qw\(//;
            $namespace =~ s/\)$//;
#         die "[$namespace] / [$word]" if $word =~ /TExcept/;
            if ( $packages{$namespace} ) {
                            $namespace =~ s/^Cassandra:://;
                $namespace = 'Net::Cassandra::Backend::' . $namespace;
                $word->set_content( 'qw(' . $namespace . ")" );
 #               die $word if $word =~ /TExcept/;

                say "** $word" if $namespace =~ /TExcept/;
            } else {

                say "?? $word" if $namespace =~ /TExcept/;
            }
        }
        dir($destination)->parent->mkpath;
        $document->save($destination);
    }
    die 'Failed to build' unless -f "$perl_dir/Cassandra.pm";
}
