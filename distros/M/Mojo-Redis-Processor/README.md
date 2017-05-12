[![Build Status](https://travis-ci.org/binary-com/perl-Mojo-Redis-Processor.svg?branch=master)](https://travis-ci.org/binary-com/perl-Mojo-Redis-Processor)
[![codecov](https://codecov.io/gh/binary-com/perl-Mojo-Redis-Processor/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Mojo-Redis-Processor)



# perl-Mojo-Redis-Processor

# NAME

Mojo::Redis::PubSub - Message distribution and processing using Redis backend.

# DESCRIPTION

This module will encapsulate a communication process between Websocket code implemented as a Mojo app which need stream of prices and daemons which get the pricing parameters and publish market price whenever there is a market signal (trigger).

As price that be common between different Mojo children they will race over setting a pricing request in Redis. It will be handles by SET NX in Redis.

Daemon will take the pricing jobs for every Market signal calculate and publish the price back for Mojo children using Redis PUB/SUB.

# VERSION

0.02


# SYNOPSIS
Mojo app which wants to send data and get stream of processed results will look like:

	use Mojo::Redis::Processor;
	use Mojolicious::Lite;

	my $rp = Mojo::Redis::Processor->new({
	    data       => 'Data',
	    trigger    => 'R_25',
	});

	$rp->send();
	my $redis_channel = $rp->on_processed(
	    sub {
	        my ($message, $channel) = @_;
	        print "Got a new result [$message]\n";
	    });

	app->start;

Try it like:

	$ perl -Ilib ws.pl daemon


Processor daemon code will look like:

	use Mojo::Redis::Processor;
	use Parallel::ForkManager;

	use constant MAX_WORKERS  => 1;

	$pm = new Parallel::ForkManager(MAX_WORKERS);

	while (1) {
	    my $pid = $pm->start and next;

	    my $rp = Mojo::Redis::Processor->new;

	    $next = $rp->next();
	    if ($next) {
	        print "next job started [$next].\n";

	        $rp->on_trigger(
	            sub {
	                my $payload = shift;
	                print "processing payload\n";
	                return rand(100);
	            });
	        print "Job done, exiting the child!\n";
	    } else {
	        print "no job found\n";
	        sleep 1;
	    }
	    $pm->finish;
	}

Try it like:

	$ perl -Ilib daemon.pl

Daemon needs to pick a forking method and also handle ide processes and timeouts.


# SOURCE CODE

[GitHub](https://github.com/binary-com/perl-Mojo-Redis-Processor)

# AUTHOR

binary.com, `<perl at binary.com>`

# BUGS

Please report any bugs or feature requests to
[https://github.com/binary-com/perl-Mojo-Redis-Processor/issues](https://github.com/binary-com/perl-Mojo-Redis-Processor/issues).

# LICENSE AND COPYRIGHT

Copyright (C) 2016 binary.com

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
