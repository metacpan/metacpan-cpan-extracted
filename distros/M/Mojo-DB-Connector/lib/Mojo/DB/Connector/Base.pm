package Mojo::DB::Connector::Base;
use Mojo::Base -role;
use Mojo::Parameters;
use Mojo::URL;

has env_prefix  => sub { 'MOJO_DB_CONNECTOR_' };
has scheme      => sub { shift->_attr_default('scheme', 'SCHEME', 'postgresql') };
has userinfo    => sub { shift->_attr_default('userinfo', 'USERINFO', '') };
has host        => sub { shift->_attr_default('host', 'HOST', 'localhost') };
has port        => sub { shift->_attr_default('port', 'PORT', '5432') };
has database    => sub { shift->_attr_default(sub { $_->path->to_string }, 'DATABASE', '') };
has options     => sub {
    my $options = shift->_attr_default(sub { $_->query->pairs }, 'OPTIONS', '');
    return $options if ref $options;
    return Mojo::Parameters->new($options)->pairs;
};
has url         => sub {
    my $env_url = $ENV{shift->env_prefix . 'URL'};
    return unless $env_url;

    my $url = Mojo::URL->new($env_url);
    # so database does not have a leading slash
    $url->path->leading_slash(undef);

    return $url;
};
has strict_mode => sub { $ENV{shift->env_prefix . 'STRICT_MODE'} // 1 };

has [qw(_required_mysql _required_pg)];

sub new_connection {
    my $self = shift;
    my %config = $self->_config(@_);

    my ($package, $constructor);
    my $scheme = $config{scheme};
    if ($scheme eq 'mariadb' or $scheme eq 'mysql') {
        $package = 'Mojo::mysql';
        $constructor = $config{strict_mode} ? 'strict_mode' : 'new';

        if (not $self->_required_mysql) {
            eval { require Mojo::mysql; 1 } or Carp::croak "Failed to require Mojo::mysql $@";
            $self->_required_mysql(1);
        }
    } elsif ($scheme eq 'postgresql') {
        $package = 'Mojo::Pg';
        $constructor = 'new';

        if (not $self->_required_pg) {
            eval { require Mojo::Pg; 1 } or Carp::croak "Failed to require Mojo::Pg $@";
            $self->_required_pg(1);
        }
    } else {
        Carp::croak "unknown scheme '$scheme'. Supported schemes are: mariadb, mysql, postgresql";
    }

    return $package->$constructor($self->_to_url(%config)->to_unsafe_string);
}

sub _to_url {
    my ($self, %config) = @_;

    my $url =
        Mojo::URL->new
                 ->scheme($config{scheme})
                 ->userinfo($config{userinfo})
                 ->host($config{host})
                 ->port($config{port})
                 ->path($config{database})
                 ;
    $url->query($self->options);

    if ($config{options}) {
        if ($config{replace_options}) {
            $url->query(@{ $config{options} });
        } else {
            $url->query($config{options});
        }
    }

    return $url;
}

sub _config {
    my $self = shift;

    return (
        (map { $_ => $self->$_ } qw(scheme userinfo host port database strict_mode)),
        @_,
    );
}

sub _attr_default {
    my ($self, $url_method, $env_suffix, $default) = @_;

    if (my $url = $self->url) {
        return ref $url_method ? $url_method->(local $_ = $url) : $url->$url_method;
    }

    return $ENV{$self->env_prefix . $env_suffix} // $default;
}

1;
__END__

=encoding utf-8

=head1 NAME

L<Mojo::DB::Connector::Base> - Base role for DB Connectors

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-DB-Connector"><img src="https://travis-ci.org/srchulo/Mojo-DB-Connector.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-DB-Connector?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-DB-Connector/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  package MyDBConnector;

  with 'Mojo::DB::Connector::Base';

  # hack hack hack...

=head1 DESCRIPTION

L<Mojo::DB::Connector::Base> is the base role for all of the functionality
in L<Mojo::DB::Connector>. See L<Mojo::DB::Connector> for documentation.

=head1 SEE ALSO

=over 4

=item

L<Mojo::DB::Connector>

=item

L<Mojo::DB::Connector::Role::Cache>

=item

L<Mojo::DB::Connector::Role::ResultsRoles>

Apply roles to Mojo database results from L<Mojo::DB::Connector> connections.

=item

L<Mojo::mysql>

=item

L<Mojo::Pg>

=back

=head1 LICENSE

This software is copyright (c) 2020 by Adam Hopkins

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=cut
