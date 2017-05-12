use strict;
use warnings;
use Net::Drizzle ':constants';
use Test::More;
use constant {
  CLIENT_QUERY  => 1,
  CLIENT_FIELDS => 2,

  true  => 1,
  false => 0,
};
my $QUERIES = 10;
plan tests => 6*$QUERIES;

sub DEBUG { print "@_\n" if $ENV{DEBUG} }

&main;exit;

sub main {
    my $port = shift;

    my $drizzle = Net::Drizzle->new()
                                ->add_options(DRIZZLE_NON_BLOCKING);
    my @containers; 
    my $wait_for_connections = 0;
    for (1..$QUERIES) {
        my $container = _send_query($drizzle, $port);
        push @containers, $container;
        if (client_process($container) == 1) {
            $wait_for_connections++;
        }
    }

    DEBUG("READY TO NONBLOCKING_LOOP!");
    while ($wait_for_connections > 0) {
        DEBUG("LOOP");
        $drizzle->con_wait();
        my $con;
        while ($con = $drizzle->con_ready()) {
            DEBUG("CON_READY --");
            my $container = $con->data;
            # die "invalid container: $container, $con" unless ref($container) eq 'HASH';
            if (client_process($container) == 0) {
                $wait_for_connections--;
            }
        }
    }
    for my $container (@containers) {
        is join(',', @{$container->{columns}}), 'table_schema,table_name';
        cmp_ok(@{$container->{rows}}, '>', 1, 'rows: '.@{$container->{rows}});
    }
}

sub _send_query {
    my ($drizzle, $port) = @_;
    my $con = $drizzle->con_create()
                      ->add_options(DRIZZLE_CON_MYSQL)
                      ->set_db('information_schema');
    my $container = +{
        con   => $con,
        state => CLIENT_QUERY,
        query => "SELECT table_schema,table_name FROM tables",
    };
    $con->set_data($container);
    $container;
}

sub client_process {
    my $container = shift;
    my $func = +{
        CLIENT_QUERY()  => 'client_query',
        CLIENT_FIELDS() => 'client_fields',
    }->{$container->{state}};
    no strict 'refs';
    my $code = *{$func} or die "missing func? $func";
    $code->($container);
}

sub client_query {
    my $container = shift;
    my ($ret, $result) = $container->{con}->query($container->{query});
    $container->{result} = $result;
    if ($ret == DRIZZLE_RETURN_IO_WAIT) {
        DEBUG("IO_WAIT");
        return 1;
    } elsif ($ret != DRIZZLE_RETURN_OK) {
        die "error occured at drizzle_query: $ret, ".$container->{con}->drizzle->error;
    }

    is $result->row_count, 0;
    is $result->insert_id, 0;
    is $result->warning_count, 0;
    is $result->column_count, 2;
    if ($result->column_count != 0) {
        DEBUG("HAS FIELDS");
        $container->{state} = CLIENT_FIELDS;
        return client_fields($container);
    }
    return 0;
}

sub client_fields {
    my $container = shift;
    DEBUG("CLIENT_FIELDS");
    my $result = $container->{result};
    my $ret = $result->buffer;
    if ($ret == DRIZZLE_RETURN_IO_WAIT) {
        DEBUG("IO_WAIT");
        return 1;
    } elsif ($ret != DRIZZLE_RETURN_OK) {
        die "error occured at drizzle_query: $ret";
    }
    while (my $column = $result->column_next) {
        push @{$container->{columns}}, $column->name;
    }
    while (my $row = $result->row_next()) {
        push @{$container->{rows}}, $row;
    }

    return 0;
}

