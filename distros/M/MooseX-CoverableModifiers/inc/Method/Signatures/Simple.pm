#line 1
package Method::Signatures::Simple;
BEGIN {
  $Method::Signatures::Simple::VERSION = '1.02';
}

use warnings;
use strict;

#line 17

use base q/Devel::Declare::MethodInstaller::Simple/;

sub import {
    my $class = shift;
    my %opts  = @_;
    $opts{into} ||= caller;

    my $meth = delete $opts{name} || delete $opts{method_keyword};
    my $func = delete $opts{function_keyword};

    # if no options are provided at all, then we supply defaults
    unless (defined $meth || defined $func) {
        $meth = 'method';
        $func = 'func';
    }

    # we only install keywords that are requested
    if (defined $meth) {
        $class->install_methodhandler(
        name     => $meth,
        invocant => '$self',
        %opts,
        );
    }
    if (defined $func) {
        $class->install_methodhandler(
          name     => $func,
          %opts,
          invocant => undef,
        );
    }
}

sub parse_proto {
    my $self = shift;
    my ($proto) = @_;
    $proto ||= '';
    $proto =~ s/[\r\n]//g;
    my $invocant = $self->{invocant};

    $invocant = $1 if $proto =~ s{^(\$\w+):\s*}{};

    my $inject = '';
    $inject .= "my ${invocant} = shift;" if $invocant;
    $inject .= "my ($proto) = \@_;"      if defined $proto and length $proto;

    return $inject;
}


#line 315

1; # End of Method::Signatures::Simple
