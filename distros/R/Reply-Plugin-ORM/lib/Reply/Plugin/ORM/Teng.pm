package Reply::Plugin::ORM::Teng;
use strict;
use warnings;

use List::Compare;
use Module::Load;
use Path::Tiny;

my @UNNECESSARY_METHODS = qw/
    new BEGIN DESTROY Iterator:: QueryBuilder:: Row:: Schema:: Plugin:: VERSION SQL_COMMENT_LEVEL load_plugin schema schema_class suppress_row_objects
/;

sub new {
    my ($class, $db_name, $config, %opts) = @_;

    eval { require Teng };
    Carp::croak "[Error] Module 'Teng' not found." if $@;
    eval { require Teng::Schema::Loader };
    Carp::croak "[Error] Module 'Teng::Schema::Loader' not found." if $@;

    load 'Teng';
    load 'Teng::Schema::Loader';

    if ($opts{teng_plugins}) {
        Teng->load_plugin($_) for split /,/, $opts{teng_plugins};
    } 
    my $orm = Teng::Schema::Loader->load(
        connect_info         => $config->{connect_info},
        namespace            => 'Reply::Plugin::ORM::Teng::DB',
        suppress_row_objects => 1,
    );

    my $list = List::Compare->new([ grep { $_ !~ /^_/ } keys %{Teng::} ], \@UNNECESSARY_METHODS);
    my @methods = map { s/(^.)/uc $1/e; $_ } $list->get_Lonly;

    return bless {
        orm     => $orm,
        methods => \@methods,
    }, $class;
}

1;
