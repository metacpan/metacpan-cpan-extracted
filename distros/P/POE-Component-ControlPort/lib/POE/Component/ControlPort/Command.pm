# $Id: Command.pm 222 2004-04-24 17:55:11Z sungo $

=pod

=head1 NAME

POE::Component::ControlPort::Command - Register control port commands

=head1 SYNOPSIS

    use POE::Component::ControlPort::Command;

    POE::Component::ControlPort::Command->register(
        name => 'test',
        topic => 'sample_commands',
        usage => 'test [ text to echo ]'
        help_text => 'test command. will echo back all parameters',
        command => sub {  my %args = @_; return join(" ", @{$args{args}}); }
    );

=head1 DESCRIPTION

This module has one command for public consumption. C<register()> is the
way that one registers commands for use in the control port. The
arguments listed in the synopsis are all the available arguments and are
all mandatory.

=cut

package POE::Component::ControlPort::Command;

use warnings;
use strict;

use Carp;
use Params::Validate qw(:all);

our $VERSION = do { my @r= (q|$Revision: 1.3 $| =~/\d+/g); sprintf "%d."."%04d"x$#r, @r };

our %TOPICS;

our %REGISTERED_COMMANDS;


sub register {
    my $class = shift;

    my %args = validate( @_, {
        help_text => { type => SCALAR },
        usage => { type => SCALAR },
        topic => { type => SCALAR },
        name => { type => SCALAR },
        command => { type => CODEREF }, 
    } );

    push @{ $TOPICS{ $args{topic} } }, $args{name};
    $REGISTERED_COMMANDS{ $args{name} } = \%args;

    return 1;
}

sub run {
    my $class = shift;

    my %args = validate( @_, {
        command => { type => SCALAR },
        oob_data => { type => HASHREF, optional => 1 },
        arguments => { type => ARRAYREF, optional => 1 },
    } );

    if($REGISTERED_COMMANDS{ $args{command} }) {
         return "Bad command '$args{command}" unless 
            ref $REGISTERED_COMMANDS{ $args{command} }{ command }  eq 'CODE';

        my $txt = eval { 
            &{$REGISTERED_COMMANDS{ $args{command} }{ command }}( 
                args => $args{arguments},
                oob => $args{oob_data},
            );
        };
            

        if($@) {
            return "ERROR: $@";
        } else {
            return $txt;
        }
    } else {
        return "ERROR: '$args{command}' is unknown.";
    }
}


1;
__END__

=pod 

=head1 AUTHOR

Matt Cashner (cpan@eekeek.org)

=head1 REVISION

$Revision: 1.3 $

=head1 DATE

$Date: 2004-04-24 13:55:11 -0400 (Sat, 24 Apr 2004) $

=head1 LICENSE

Copyright (c) 2004, Matt Cashner

Permission is hereby granted, free of charge, to any person obtaining 
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject 
to the following conditions:

The above copyright notice and this permission notice shall be included 
in all copies or substantial portions of the Software.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

