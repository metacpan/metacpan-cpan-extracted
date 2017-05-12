package Prophet::Server::Dispatcher;
{
  $Prophet::Server::Dispatcher::VERSION = '0.751';
}
use Any::Moose;
use Path::Dispatcher::Declarative -base,
  -default => { token_delimiter => '/', };

has server => ( isa => 'Prophet::Server', is => 'rw', weak_ref => 1 );

under { method => 'POST' } => sub {
    on qr'.*' => sub {
        my $self = shift;
        return $self->server->_send_401 if ( $self->server->read_only );
        next_rule;
    };

    under qr'/records' => sub {
        on qr|^/(.*)/(.*)/(.*)$| =>
          sub { shift->server->update_record_prop( $1, $2, $3 ) };
        on qr|^/(.*)/(.*).json$| =>
          sub { shift->server->update_record( $1, $2 ) };
        on qr|^/(.*).json$| => sub { shift->server->create_record($1) };
    };
};

under { method => 'GET' } => sub {
    on qr'^/=/prophet/autocomplete' => sub {
        shift->server->show_template('/_prophet_autocompleter');
    };
    on qr'^/static/prophet/(.*)$' =>
      sub { shift->server->send_static_file($1) };

    on qr'^/records.json' => sub { shift->server->get_record_types };
    under qr'/records' => sub {
        on qr|^/(.*)/(.*)/(.*)$| =>
          sub { shift->server->get_record_prop( $1, $2, $3 ); };
        on qr|^/(.*)/(.*).json$| =>
          sub { shift->server->get_record( $1, $2 ) };
        on qr|^/(.*).json$| => sub { shift->server->get_record_list($1) };

    };

    on qr'^/replica(/resolutions)?' => sub {
        my $self = shift;
        if ( $1 && $1 eq '/resolutions' ) {
            $_->metadata->{replica_handle} =
              $self->server->app_handle->handle->resolution_db_handle;
        } else {
            $_->metadata->{replica_handle} = $self->server->app_handle->handle;
        }
        next_rule;
    };

    under qr'^/replica(/resolutions/)?' => sub {
        on 'replica-version' =>
          sub { shift->server->send_replica_content('1') };
        on 'replica-uuid' => sub {
            my $self = shift;
            $self->server->send_replica_content(
                $_->metadata->{replica_handle}->uuid );
        };
        on 'database-uuid' => sub {
            my $self = shift;
            $self->server->send_replica_content(
                $_->metadata->{replica_handle}->db_uuid );
        };
        on 'latest-sequence-no' => sub {
            my $self = shift;
            $self->server->send_replica_content(
                $_->metadata->{replica_handle}->latest_sequence_no );
        };

        on 'changesets.idx' => sub {
            my $self  = shift;
            my $index = '';
            my $repl  = $_->metadata->{replica_handle};
            $repl->traverse_changesets(
                after           => 0,
                load_changesets => 0,
                callback        => sub {
                    my %args                 = (@_);
                    my $data                 = $args{changeset_metadata};
                    my $changeset_index_line = pack( 'Na16NH40',
                        $data->[0],
                        $repl->uuid_generator->from_string( $data->[1] ),
                        $data->[2], $data->[3] );
                    $index .= $changeset_index_line;
                }
            );
            $self->server->send_replica_content($index);
        };
        on qr|cas/changesets/././(.{40})$| => sub {
            my $self = shift;
            my $sha1 = $1;
            $self->server->send_replica_content( $_->metadata->{replica_handle}
                  ->fetch_serialized_changeset( sha1 => $sha1 ) );
        };

    };
};

on qr'^(.*)$' => sub { shift->server->show_template($1) || next_rule; };

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Server::Dispatcher

=head1 VERSION

version 0.751

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
