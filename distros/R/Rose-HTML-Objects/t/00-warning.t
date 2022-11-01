#!/usr/bin/perl

use strict;

# XXX: Can't use Scalar::Defer 0.11 (or possibly later) until some things
# XXX: are sorted out.  See: http://rt.cpan.org/Ticket/Display.html?id=31039

# use Scalar::Defer;
# 
# if($Scalar::Defer::VERSION == 0.11)
# {
#   print STDERR<<"EOF";
# 
# ***
# *** WARNING: Scalar::Defer version 0.11 detected.  Rose::HTML::Objects 0.550
# *** and later are not compatible with Scalar::Defer 0.11.  Please install 
# *** Scalar::Defer 0.10 or some other, later version of Scalar::Defer.  The
# *** test suite will continue, but many tests will fail.
# ***
# *** Press return to continue (or wait 60 seconds)
# EOF
# 
#   my %old;
#   
#   $old{'ALRM'} = $SIG{'ALRM'} || 'DEFAULT';
#   
#   eval
#   {
#     # Localize so I only have to restore in my catch block
#     local $SIG{'ALRM'} = sub { die 'alarm' };
#     alarm(60);
#     my $res = <STDIN>;
#     alarm(0);
#   };
#   
#   if($@ =~ /alarm/)
#   {
#     $SIG{'ALRM'} = $old{'ALRM'};
#   }
# }

print "1..1\n",
      "ok 1\n";

1;
