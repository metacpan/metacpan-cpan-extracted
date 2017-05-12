package Net::Async::AMQP::Storage;
$Net::Async::AMQP::Storage::VERSION = '2.000';
use strict;
use warnings;

=pod

Information to be stored:

server:
* []vhosts
* []connections

vhost:
* name
* []exchanges
* []queues
* []bindings
* []connections

Connection:
* user
* vhost
* []channels

Channel:
* active request
* []consumers

Queue:
* name
* exclusive
* durable
* []consumers
* []bindings to exchanges
* []messages
* expiry

Consumer:
* queue
* ctag

Message:
* Routing key
* Type
* []Headers
* Payload
* Expiry

Exchange:
* name
* type
* []bindings to queues
* []bindings to other exchanges

--

Server owns client connections, vhosts
Connection owns channels
Channel owns consumers
VHost owns exchanges, queues
Exchange owns bindings
Queue owns messages

=cut

1;
