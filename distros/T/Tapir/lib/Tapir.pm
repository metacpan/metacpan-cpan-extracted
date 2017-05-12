package Tapir;

=head1 NAME

Tapir - A Thrift-based rapid API framework

=head1 DESCRIPTION

Tapir sets forth a way to declare an API framework that's protocol and transport agnostic.  It provides for strict datatyping (via L<Thrift>) and automatic documentation with easy deployment scenarios over HTTP, AMQP or some other transport of your choice.  The core of the implementation is asynchronous but can be called in a synchronous environment so long as your method implementation doesn't use asynchronous logic.

=head1 COPYRIGHT

Copyright (c) 2012 Eric Waters.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

use strict;
use warnings;

our $VERSION = '0.03';

1;
