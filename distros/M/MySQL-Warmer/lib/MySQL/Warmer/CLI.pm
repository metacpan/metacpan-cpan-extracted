package MySQL::Warmer::CLI;
use strict;
use warnings;
use utf8;

use MySQL::Warmer;

use Getopt::Long ();
use Pod::Usage;
use Term::ReadKey;

sub run {
    my ($class, @argv) = @_;

    my ($opt, ) = $class->parse_options(@argv);
    MySQL::Warmer->new($opt)->run;
}

sub parse_options {
    my ($class, @argv) = @_;

    my $parser = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case bundling permute pass_through auto_help/],
    );
    local @ARGV = @argv;
    $parser->getoptions(\my %opt, qw/
        host|h=s
        user|u=s
        password|p:s
        port|P=i
        socket|S=s
        dry-run
    /) or pod2usage(1);

    if (exists $opt{password} && $opt{password} eq '') {
        ReadMode 'noecho';
        print 'Enter password: ';
        chomp ($opt{password} = ReadLine);
    }
    $opt{database} = shift @ARGV;
    unless (defined $opt{database}) {
        pod2usage(1);
    }

    my $dry_run = delete $opt{'dry-run'};

    my $user =
        exists $opt{user} ? delete $opt{user} :
        exists $ENV{USER} ? $ENV{USER}        : '';
    my $password = exists $opt{password} ? delete $opt{password} : '';
    my $dsn = $class->_build_dsn(%opt);
    my @dsn = ($dsn, $user, $password, {
        RaiseError          => 1,
        PrintError          => 0,
        ShowErrorStatement  => 1,
        AutoInactiveDestroy => 1,
        mysql_enable_utf8   => 1,
    });

    (+{
        dsn => \@dsn,
        $dry_run ? (dry_run => 1) : (),
    }, \@ARGV);
}

sub _build_dsn {
    my ($self, %args) = @_;
    if (exists $args{socket}) {
        $args{mysql_socket} ||= delete $args{socket};
    }
    'DBI:mysql:' . join(';', map { "$_=$args{$_}" } sort keys %args);
}

1;
