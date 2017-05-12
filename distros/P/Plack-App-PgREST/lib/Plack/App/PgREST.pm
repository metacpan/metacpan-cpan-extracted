package Plack::App::PgREST;
use strict;
use methods;
use 5.008_001;
use Plack::Builder;
use Router::Resource;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw( dsn dbh);
use Plack::Request;
use JSON::PP qw(encode_json decode_json);
use parent qw(Exporter);

our $VERSION = '0.06';
our @EXPORT = qw(pgrest);

sub pgrest {
    __PACKAGE__->new( @_ > 1 ? @_ : dsn => 'dbi:Pg:'.$_[0] )->to_app;
}

# maintain json object field order
use Tie::IxHash;
my $obj_parser_sub = \&JSON::PP::object;
*JSON::PP::object = sub {
	tie my %obj, 'Tie::IxHash';
	$obj_parser_sub->(\%obj);
};

sub n {
    my $n = shift;
    return $n unless $n;
    return (undef) if $n eq 'NaN';
    return int($n);
}

sub j {
    my $n = shift;
    return $n unless $n;
    return decode_json $n

}

method select($param, $args) {
    use Data::Dumper;
    my $req = encode_json({
        collection => $args->{collection},
        l => n($param->get('l')),
        sk => n($param->get('sk')),
        c => n($param->get('c')),
        s => j($param->get('s')),
        q => j($param->get('q')),
    });
    my $ary_ref = $self->{dbh}->selectall_arrayref("select pgrest_select(?)", {}, $req);
    if (my $callback = $param->get('callback')) {
        $callback =~ s/[^\w\[\]\.]//g;
        return [200, ['Content-Type', 'application/javascript; charset=UTF-8'],
            [
                ";($callback)($ary_ref->[0][0]);"
            ]
        ];
    }
    return [200, ['Content-Type', 'application/json; charset=UTF-8'], [$ary_ref->[0][0]]];
}

method bootstrap {
  $self->{dbh}->do("select pgrest_boot('{}')");
}

method to_app {
    unless ($self->{dbh}) {
        require DBIx::Connector;
        $self->{conn} = DBIx::Connector->new($self->{dsn}, '', '', {
          RaiseError => 1,
          AutoCommit => 1,
        });
        $self->{dbh} = $self->{conn}->dbh;
    }
    die unless $self->{dbh};
    $self->bootstrap;
    my $router = router {
        resource '/collections/{collection}' => sub {
            GET  { $self->select(Plack::Request->new($_[0])->parameters, $_[1]) };
        };
    };

    builder {
        sub { $router->dispatch(shift) };
    };
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Plack::App::PgREST - http://postgre.st/

=head1 SYNOPSIS

  # install plv8 extension for pg first

  # install pgrest with npm
  % npm i pgrest
  # bootstrap
  % pgrest --db MYDB --boot

  # start the server
  % plackup -MPlack::App::PgREST -e 'pgrest q{db=MYDB}'

=head1 DESCRIPTION

Plack::App::PgREST is:

=over

=item

a JSON document store

=item

running inside PostgreSQL

=item

working with existing relational data

=item

capable of loading Node.js modules

=item

compatible with MongoLab's REST API

=back

=head1 INSTALL

=over

=item

Install pgxn:

  sudo easy_install pgxnclient

=item

Install libv8 (for older distro (lucid, natty): sudo add-apt-repository ppa:martinkl/ppa)

  sudo apt-get install libv8-dev

=item

Install plv8 pgxn:

  sudo pgxn install plv8

=back

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>
Audrey Tang E<lt>audreyt@audreyt.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
