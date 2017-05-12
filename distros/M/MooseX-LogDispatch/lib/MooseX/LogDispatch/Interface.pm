package # Hide from pause
  MooseX::LogDispatch::Interface;
use Moose::Role;

requires qw{
  log
  debug
  info
  notice
  warning
  error
  critical
  alert
  emergency
};

no Moose::Role;
1;
__END__
