#+##############################################################################
#                                                                              #
# File: No/Worries/Export.pm                                                   #
#                                                                              #
# Description: symbol exporting without worries                                #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::Export;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Params::Validate qw(validate_with :types);

#
# simple yet powerful export control
#

sub export_control ($$$@) {
    my($callpkg, $pkg, $exported, @names) = @_;
    my($name, $regexp, $ref);

    validate_with(
        params => \@_,
        spec => [ { type => SCALAR }, { type => SCALAR }, { type => HASHREF } ],
        allow_extra => 1,
    );
    while (@names) {
        $name = shift(@names);
        # special case for * and /.../ and x.y
        if ($name eq "*") {
            unshift(@names, grep(!ref($exported->{$_}), keys(%{ $exported })));
            next;
        } elsif ($name =~ /^\/(.*)\/$/) {
            $regexp = $1;
            unshift(@names, grep(/$regexp/, grep(!ref($exported->{$_}),
                                                 keys(%{ $exported }))));
            next;
        } elsif ($name =~ /^\d/) {
            # version checking via UNIVERSAL
            $pkg->VERSION($name);
            next;
        }
        die("\"$name\" is not exported by the $pkg module\n")
            unless defined($exported->{$name});
        $ref = ref($exported->{$name});
        if ($ref eq "") {
            # normal symbol
            if ($name =~ /^(\w+)$/) {
                # function
                no strict qw(refs);
                no warnings qw(once prototype);
                *{"${callpkg}::${1}"} = \&{"${pkg}::${1}"};
            } elsif ($name =~ /^\$(\w+)$/) {
                # scalar
                no strict qw(refs);
                *{"${callpkg}::${1}"} = \${"${pkg}::${1}"};
            } elsif ($name =~ /^\@(\w+)$/) {
                # array
                no strict qw(refs);
                *{"${callpkg}::${1}"} = \@{"${pkg}::${1}"};
            } elsif ($name =~ /^\%(\w+)$/) {
                # hash
                no strict qw(refs);
                *{"${callpkg}::${1}"} = \%{"${pkg}::${1}"};
            } else {
                die("unsupported export by the $pkg module: $name\n");
            }
        } elsif ($ref eq "CODE") {
            # special symbol
            $exported->{$name}->($name);
        } else {
            die("unsupported export by the $pkg module: $name=$ref\n");
        }
    }
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(export_control));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

No::Worries::Export - symbol exporting without worries

=head1 SYNOPSIS

  use No::Worries::Export qw(export_control);

  sub foo () { ... }

  our $bar = 42;

  sub import : method {
      my($pkg, %exported);
      $pkg = shift(@_);
      grep($exported{$_}++, qw(foo $bar));
      export_control(scalar(caller()), $pkg, \%exported, @_);
  }

=head1 DESCRIPTION

This module eases symbol exporting by providing a simple yet powerful
alternative to the L<Exporter> module.

The symbols that can be imported are defined in a hash (the third
argument of export_control()), the key being the symbol name and the
value being:

=over

=item * a scalar: indicating a normal symbol

=item * a code reference: to be called at import time

=back

The normal symbols can be functions (such as C<foo>), scalars
(<$foo>), arrays (<@foo>) or hashes (<%foo>).

All the normal symbols can be imported at once by using an asterisk in
the import code:

  use Foo qw(*);

Alternatively, a regular expression can be given to filter what to
import:

  # import "foo" and all the normal symbols starting with "bar"
  use Foo qw(foo /^bar/);

The special symbols can be used to execute any code. For instance:

  # exporting module
  our $backend = "stdout";
  sub import : method {
      my($pkg, %exported);
      $pkg = shift(@_);
      $exported{syslog} = sub { $backend = "syslog" };
      export_control(scalar(caller()), $pkg, \%exported, @_);
  }

  # importing code
  use Foo qw(syslog);

Finally, anything looking like a number will trigger a version check:

  use Foo qw(1.2);
  # will trigger
  Foo->VERSION(1.2);

See L<UNIVERSAL> for more information on the VERSION() mthod.

=head1 FUNCTIONS

This module provides the following function (not exported by default):

=over

=item export_control(CALLERPKG, PKG, EXPORT, NAMES...)

control the symbols exported by the module; this should be called from
an C<import> method

=back

=head1 SEE ALSO

L<Exporter>,
L<No::Worries>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
