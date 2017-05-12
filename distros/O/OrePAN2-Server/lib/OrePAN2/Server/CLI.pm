package OrePAN2::Server::CLI;
use strict;
use warnings;
use utf8;

use File::Basename ();
use File::Path ();
use Plack::App::Directory;
use Plack::Builder;
use Plack::Runner;

use OrePAN2::Server;

use Getopt::Long qw/:config posix_default no_ignore_case bundling auto_help pass_through/;
use Pod::Usage   qw/pod2usage/;

sub new {
    my $class = shift;
    local @ARGV = @_;

    my %opt = ('compress-index' => 1);
    GetOptions(\%opt, qw/
        delivery-dir=s
        delivery-path=s
        authenquery-path=s
        compress-index!
    /) or pod2usage(1);

    $opt{delivery_dir}     = delete $opt{'delivery-dir'}     || 'orepan';
    $opt{delivery_path}    = delete $opt{'delivery-path'}    || File::Basename::basename($opt{delivery_dir});
    $opt{authenquery_path} = delete $opt{'authenquery-path'} || 'authenquery';
    $opt{compress_index}   = delete $opt{'compress-index'};

    for my $path (qw/delivery_path authenquery_path/) {
        $opt{$path} = '/' . $opt{$path} if $opt{$path} !~ m!^/!;
    }
    $opt{argv} = \@ARGV;

    $class->new_with_options(%opt);
}

sub new_with_options {
    my $class = shift;
    bless {@_}, $class;
}

sub app {
    my $self = shift;

    $self->{app} ||= do {
        File::Path::mkpath $self->{delivery_dir};
        my $app = builder {
            mount $self->{authenquery_path} => OrePAN2::Server->uploader(
                directory      => $self->{delivery_dir},
                compress_index => $self->{compress_index},
            );
            mount $self->{delivery_path} => Plack::App::Directory->new({root=> $self->{delivery_dir}})->to_app;
        };
    };
}

sub run {
    my $self = shift;

    my $runner = Plack::Runner->new;
    $runner->parse_options(@{ $self->{argv} || [] });
    $runner->run($self->app);
}

1;
