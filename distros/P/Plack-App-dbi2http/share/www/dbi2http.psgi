#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use DBI;
use DBIx::FunctionalAPI;
use File::Slurp::Tiny;
use File::Write::Rotate;
use Perinci::Access::Base::Patch::PeriAHS;
use Plack::Builder;
use Plack::Util::PeriAHS qw(errpage);
use YAML::Syck ();

my $confpath = $ENV{DBI2HTTP_CONFIG_PATH} // do {
    my $home = (getpwuid($>))[7];  # $ENV{HOME} is empty if via fcgi
    "$home/dbi2http.conf.yaml";
};
my $conf = YAML::Syck::LoadFile($confpath);

my $fwr = File::Write::Rotate->new(
    dir       => $conf->{riap_access_log_dir},
    prefix    => $conf->{riap_access_log_prefix},
    size      => $conf->{riap_access_log_size},
    histories => $conf->{riap_access_log_histories},
);

$DBIx::FunctionalAPI::dbh = DBI->connect(
    $conf->{db_dsn}, $conf->{db_user}, $conf->{db_password},
    {RaiseError=>1},
);

# remove all dbh arguments from function
for my $meta (%DBI::FunctionalAPI::SPEC) {
    delete $meta->{args}{dbh};
}

# to prevent Text::ANSITable spewing Unicode characters
$ENV{UTF8} = 0;

# to prevent Text::ANSITable spewing borders
$ENV{INTERACTIVE} = 0;

my $app = builder {
    enable(
        "PeriAHS::LogAccess",
        dest => $fwr,
    );

    # you can add access control by IP here
    #enable "PeriAHS::CheckAccess";

    enable(
        "PeriAHS::ParseRequest",
        #parse_path_info => $args{parse_path_info},
        #parse_form      => $args{parse_form},
        #parse_reform    => $args{parse_reform},
        riap_uri_prefix  => '/DBIx/FunctionalAPI',
    );

    # you can add authentication here
    #enable "Auth::Basic", ...

    enable "PeriAHS::Respond";
};

=head1 SYNOPSIS


=head1 ENVIRONMENT

=head2 DBI2HTTP_CONFIG_PATH => str

Set location of config file. The default is C<~/dbi2http.conf.yaml>.

=cut
