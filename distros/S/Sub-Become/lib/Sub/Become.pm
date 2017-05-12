package Sub::Become;

use warnings;
use strict;
use Carp;
use base qw( Exporter );

our @EXPORT_OK = our @EXPORT = qw( become );

=head1 NAME

Sub::Become - Syntactic sugar to allow a sub to replace itself

=head1 VERSION

This document describes Sub::Become version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Sub::Become;
    
    sub foo {
        my $t = Date->new();
        become {
            return $t;
        }
        return foo();
    }
  
=head1 DESCRIPTION

A useful technique in languages like JavaScript is to write a function
that replaces its own definition:

    var foo = function() {
        var t = new Date();
        foo = function() {
            return t;
        };
        return foo();
    };

See L<http://peter.michaux.ca/article/3556> for a complete explanation
of the technique.

C<Sub::Become> provides a little syntactic sugar to make this
easy in Perl too. See the SYNOPSIS for an example.

=head1 INTERFACE 

=head2 C<< become >>

Replace the current subroutine with the supplied code block:

    sub bar {
        become { 2 }; # return 2 next time
        return 1;     # return 1 first time
    }

If you need to return the value that the new subroutine definition would
have returned in the same invocation either have the subroutine recurse:

    sub expensive {
        my $thing = some_expensive_calculation();
        become { $thing };
        return expensive();
    }

Or exploit the fact that C<become> returns the code reference for the
new definition:

    sub expensive {
        my $thing = some_expensive_calculation();
        return (become { $thing })->();
    }

=cut

sub become(&) {
    croak "become needs a coderef"
      unless @_ == 1 && 'CODE' eq ref $_[0];
    no strict 'refs';
    no warnings 'redefine';
    return *{ ( caller 1 )[3] } = shift;
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Sub::Become requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-sub-become@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2008, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
