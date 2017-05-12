###########################################
# Foo::Bar -- 2005, Mike Schilli <cpan@perlmeister.com>
###########################################
# Blah Blah Blah
###########################################

###########################################
package Foo::Bar;
###########################################

use strict;
use warnings;

our $VERSION = "0.01";

our $Foo::Bar::var = 1;

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        %options,
    };

    bless $self, $class;
}

1;

__END__

=head1 NAME

Foo::Bar - blah blah blah

=head1 SYNOPSIS

    use Foo::Bar;

=head1 DESCRIPTION

Foo::Bar blah blah blah.

=head1 EXAMPLES

  $ perl -MFoo::Bar -le 'print $foo'

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
