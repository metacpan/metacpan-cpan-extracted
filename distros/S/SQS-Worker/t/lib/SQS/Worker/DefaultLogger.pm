package SQS::Worker::DefaultLogger;
  use Moose;
  sub _print { print sprintf "[%s] %s %s\n", @_ };
  sub debug { shift->_print('DEBUG', @_) }
  sub error { shift->_print('ERROR', @_) }
  sub info  { shift->_print('INFO', @_) }
1;
