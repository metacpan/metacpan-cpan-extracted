package Perl6::Builtins;

use version; $VERSION = qv('0.0.3');

use warnings;
use strict;
use Carp;

sub import {
    use Contextual::Return;
    my $package = shift;

    # system...
    if (!@_ || grep m/\A system \z/xms, @_) {
        *CORE::GLOBAL::system = \&_p6_system;
    }

    # caller...
    if (!@_ || grep m/\A caller \z/xms, @_) {
        *CORE::GLOBAL::caller = \&_p6_caller;
    }
}

sub _p6_system {
    undef $!;
    my $status = CORE::system @_;
    my $error = $!;
    return
        BOOL  { !$status }
        VALUE { $error   };
}

my @CALLER_FIELDS = qw(
    package
    file
    line
    sub
    args
    want
    eval
    require
    hints
    bitmask
);

sub _p6_caller {
    my @caller;
    if (@_) {
        @caller = CORE::caller($_[0]+1);
    }
    else {
        @caller = (CORE::caller(1))[0..2];
    }
    return (
        HASHREF { my %hash;
                  @hash{@CALLER_FIELDS} = @caller;
                  \%hash;
                }
        SCALAR  { $caller[0]; }
        LIST    { @caller; }
    );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Perl6::Builtins - Provide Perl 5 versions of the new Perl 6 builtins


=head1 VERSION

This document describes Perl6::Builtins version 0.0.3


=head1 SYNOPSIS

    use Perl6::Builtins qw( system );

    system $system_cmd
        or die "Could not $system_cmd: $!";

    my $package = caller->{package};
    my $file    = caller->{file};
    my $line    = caller->{line};
  
  
=head1 DESCRIPTION

Several of the builtins in Perl 6 have different (i.e. more useful, less
confusing) behaviours than their Perl 5 counterparts. This module provides
Perl 5 versions of those builtins.


=head1 INTERFACE 

=over 

=item C<system>

If C<system> is loaded on the use line, the builtin is altered so that it
returns true if the system command suceeds. In any other context, the command
returns the value in C<$!>.

=item C<caller>

If C<caller> is loaded on the use line, the builtin is altered so that it
behaves as in Perl 5 in scalar and list contexts. However, if the result of a 
call to C<caller> is used as a hash reference it returns a reference to a
hash with the following keys:

=over

=item 'package'

=item 'file'

=item 'line'

=item 'sub'

=item 'args'

=item 'want'

=item 'eval'

=item 'require'

=item 'hints'

=item 'bitmask'

=back

with each of the values for these keys being the equivalent item from
the list returned by C<caller> in list context. This is useful because
it means that, instead of:

    $subname = (caller)[3];

you can write the much more readable:

    $subname = caller->{sub};

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Perl6::Builtins requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module uses the Contextual::Return module.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl6-builtins@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
