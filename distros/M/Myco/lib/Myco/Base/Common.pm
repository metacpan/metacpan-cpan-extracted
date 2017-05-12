#  $Id: Common.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $

package Myco::Base::Common;

use strict;
use Myco::Exceptions;

use base qw(Class::Tangram);
use Set::Object;

sub import_schema {
    Class::Tangram::import_schema($_[0]);

}

sub attr_kill_handle {
    return \ $_[0]->{$_[1]};
}


my $rawdate_re = qr/^\d{4}-\d{2}-\d{2}$/;
sub check_rawdate {
    Myco::Exception::DataValidation->throw("invalid SQL rawdate")
      unless ${$_[0]} =~ m/$rawdate_re/;
}

1;
