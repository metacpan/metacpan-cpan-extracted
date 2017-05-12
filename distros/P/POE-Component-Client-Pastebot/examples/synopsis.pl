  use strict;
  use POE qw(Component::Client::Pastebot);

  my $pastebot = 'http://sial.org/pbot/';

  my $pbobj = POE::Component::Client::Pastebot->spawn( alias => 'pococpb' );

  POE::Session->create(
        package_states => [
          'main' => [ qw(_start _got_paste _got_fetch) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    seek( DATA, 0, 0 );
    local $/;
    my $source = <DATA>;

    $poe_kernel->post( 'pococpb', 'paste',

        { event => '_got_paste',
          url   => $pastebot,
          paste => $source,
          channel => '#perl',
          nick => 'pococpb',
          summary => 'POE::Component::Client::Pastebot synopsis',
        },
    );
    undef;
  }

  sub _got_paste {
    my ($kernel,$ref) = @_[KERNEL,ARG0];
    if ( $ref->{pastelink} ) {
        print STDOUT $ref->{pastelink}, "\n";
        $kernel->post( 'pococpb', 'fetch', { event => '_got_fetch', url => $ref->{pastelink} } );
        return;
    }
    warn $ref->{error}, "\n";
    $kernel->post( 'pococpb', 'shutdown' );
    undef;
  }

  sub _got_fetch {
    my ($kernel,$ref) = @_[KERNEL,ARG0];
    if ( $ref->{content} ) {
        print STDOUT $ref->{content}, "\n";
    }
    else {
        warn $ref->{error}, "\n";
    }
    $kernel->post( 'pococpb', 'shutdown' );
    undef;
  }

__END__
