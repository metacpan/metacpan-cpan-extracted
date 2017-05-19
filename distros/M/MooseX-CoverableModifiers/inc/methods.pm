#line 1
package methods;
use 5.008;
our $VERSION = '0.03';

use true;
use namespace::autoclean;
use Method::Signatures::Simple;
our @ISA = 'Method::Signatures::Simple';

method import {
    my $want_invoker;
    if (@_ and $_[0] eq '-invoker') {
        $want_invoker = shift;
    }

    true->import;
    namespace::autoclean->import( -cleanee => scalar(caller) );
    Method::Signatures::Simple->import( @_, into => scalar(caller) );

    if ($want_invoker) {
        require invoker;
        unshift @_, 'invoker';
        goto &invoker::import;
    }
}

__END__

=encoding utf8

#line 97
