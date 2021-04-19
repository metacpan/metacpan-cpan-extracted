#!/usr/bin/env perl
use strict;
use warnings;

use Myriad;

{
package Example::Service::Trigger;

# Simple service, has a value that sends an event on every update to it.

use Myriad::Service;
use Ryu::Source;

has $count = 0;
has $value;
has $call_event_handler = Ryu::Source->new;

async method current : RPC {
    return { value => $value, count => $count};
}

async method update : RPC (%args) {

    $value = $args{new_value};
    $count = 0 if $args{reset};
    $call_event_handler->emit(1);
    return await $self->current;

}


async method value_updated : Emitter() ($sink, $api, %args){
    $call_event_handler->each(sub {
        my $emit = shift;
        my $e = {name => "EMITTER-Trigger service", value => $value, count => ++$count};
        $sink->emit($e) if $emit;
    });
}

}


{
package Example::Service::Holder;

# Simple service, react on a received event by keeping the sum of its emitted values.

use Myriad::Service;
use JSON::MaybeUTF8 qw(:v1);

has $sum = 0;
has $count = 0;

async method value_updated :Receiver(service => 'example.service.trigger') ($sink, $api, %args) {
    $log->warnf('Receiver Called | %s | %s | %s');

    while(1) {
        await $sink->map(
            sub {
                my $e = shift;
                my %info = ($e->@*);
                $log->tracef('INFO %s', \%info);

                my $data = decode_json_utf8($info{'data'});
                if ( ++$count == $data->{count} ){
                    $sum += $data->{value};
                } else {
                    $sum = $data->{value};
                    $count = $data->{count};
                }
            })->completed;
    }

}

async method current_sum : RPC {
    return { sum => $sum, count => $count};
}


}

no indirect;

use Syntax::Keyword::Try;
use Future::AsyncAwait;
use Log::Any qw($log);
use Test::More;

(async sub {
    my $myriad = Myriad->new;

    my @arg = ("-l","debug","--redis_uri","redis://redis6:6379","Example::Service::Trigger,Example::Service::Holder");
    $myriad->configure_from_argv(@arg)->get;
    $log->warnf('done configuring');
    $myriad->run;

})->()->get;

done_testing();
