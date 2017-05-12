   # Connects to NNTP Server, selects a group, then downloads all current articles.
   use strict;
   use POE;
   use POE::Component::Client::NNTP;
   use Mail::Internet;
   use FileHandle;

   $|=1;

   POE::Component::Client::NNTP->spawn ( 'NNTP-Client', { NNTPServer => 'news.host' } );

   POE::Session->create(
        package_states => [
                'main' => { nntp_disconnected => '_shutdown',
                            nntp_socketerr    => '_shutdown',
                            nntp_421          => '_shutdown',
                            nntp_200          => '_connected',
                            nntp_201          => '_connected',
                },
                'main' => [ qw(_start nntp_211 nntp_220 nntp_223)
                ],
        ],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
        my ($kernel,$heap) = @_[KERNEL,HEAP];

        # Our session starts, register to receive all events from poco-client-nntp
        $kernel->post ( 'NNTP-Client' => register => 'all' );
        # Okay, ask it to connect to the server
        $kernel->post ( 'NNTP-Client' => 'connect' );
        undef;
   }

   sub _connected {
        my ($kernel,$heap,$text) = @_[KERNEL,HEAP,ARG0];

        print "$text\n";

        # Select a group to download from.
        $kernel->post( 'NNTP-Client' => group => 'random.group' );
        undef;
   }

   sub nntp_211 {
        my ($kernel,$heap,$text) = @_[KERNEL,HEAP,ARG0];
        print "$text\n";

        # The NNTP server sets 'current article pointer' to first article in the group.
        # Retrieve the first article
        $kernel->post( 'NNTP-Client' => 'article' );
   }

   sub nntp_220 {
        my ($kernel,$heap,$text,$article) = @_[KERNEL,HEAP,ARG0,ARG1];
        print "$text\n";

        my $message = Mail::Internet->new( $article );
        my $filename = $message->head->get( 'Message-ID' );
        my $fh = new FileHandle "> articles/$filename";
        $message->print( $fh );
        $fh->close;

        # Set 'current article pointer' to the 'next' article in the group.
        $kernel->post( 'NNTP-Client' => 'next' );
        undef;
   }

   sub nntp_223 {
        my ($kernel,$heap,$text) = @_[KERNEL,HEAP,ARG0];
        print "$text\n";

        # Server has moved to 'next' article. Retrieve it.
        # If there isn't a 'next' article an 'nntp_421' is generated
        # which will call '_shutdown'
        $kernel->post( 'NNTP-Client' => 'article' );
        undef;
   }

   sub _shutdown {
        my ($kernel,$heap) = @_[KERNEL,HEAP];

        # We got disconnected or a socketerr unregister and terminate the component.
        $kernel->post ( 'NNTP-Client' => unregister => 'all' );
        $kernel->post ( 'NNTP-Client' => 'shutdown' );
        undef;
   }
