package POE::Component::IKC::Specifier;

############################################################
# $Id: Specifier.pm 1247 2014-07-07 09:06:34Z fil $
#
# Copyright 1999-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Carp;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( specifier_parse specifier_name specifier_part);
$VERSION = '0.2402';

sub DEBUG { 0 }

#----------------------------------------------------
# Turn an specifier into a hash ref
sub specifier_parse ($)
{
    my($specifier)=@_;
    return if not $specifier;
    my $kernelRE = q((?:\*)                             |
                     (?:[-. \w]+)                       |
                     (?:[a-zA-Z0-9][-.a-zA-Z0-9]+:\d+)  |
                     (?:unix:[-.\w]+(?::\d+-\d+)?)
                    );
    unless(ref $specifier) {
        if($specifier=~m(^poe:
                        (?:
                            (//)
                            ($kernelRE)?
                        )?
                        (?:
                            (/)
                            ([- \w]+)
                        )?
                        (?:
                            (/)?
                            ([- \w]*)
                        )?
                        (?: \x3f
                            (\w+)
                        )?
                        $)x) {
            $specifier={kernel=>$2, session=>$4, state=>$6};
            $specifier->{args}=$7 if $7;
        } 
        elsif( $specifier =~ m(^  (?:(?://)($kernelRE)/)?
                                 (?:([- \w]+)/)?
                                 (?:([- \w]+))?
                                 (?: \x3f (\w+) )?
                               $)x ) {
            $specifier = { kernel=>$1, session=>$2, state=>$3 };
            $specifier->{args} = $4 if $4;
        }
        else {
            return;
        }
    } 
    elsif('HASH' ne ref $specifier) {
#        carp "Why is specifier a ", ref $specifier;
        return;
    }

    $specifier->{kernel}||='';
    $specifier->{session}||='';
    $specifier->{state}||='';
    return $specifier;
}

sub specifier_part ($$)
{
    my($specifier, $part)=@_;
    return if not $specifier;

    $specifier="poe://$specifier" unless ref $specifier or $specifier=~/^poe:/;
    $specifier=specifier_parse $specifier;
    return if not $specifier;
    return $specifier->{$part};
}

#----------------------------------------------------
# Turn an specifier into a string
sub specifier_name ($)
{
    my($specifier)=@_;
    return $specifier unless(ref $specifier);
    if(ref($specifier) eq 'ARRAY')
    {
        $specifier={kernel=>'', 
                    session=>$specifier->[0], 
                    state=>$specifier->[1],
                   };
    }

    my $name='poe:';
    if($specifier->{kernel})
    {
        $name.='//';
        $name.=$specifier->{kernel};
    }
    if($specifier->{session})
    {
        $name.='/'.$specifier->{session};
    }
    $name.="/$specifier->{state}"    if $specifier->{state};
    return $name;
}


1;

__END__

=head1 NAME

POE::Component::IKC::Specifier - IKC event specifer

=head1 SYNOPSIS

    use POE;
    use POE::Component::IKC::Specifier;
    $state=specifier_parse('poe://*/timeserver/connect');
    print 'The foreign state is '.specifier_name($state);

=head1 DESCRIPTION

This is a helper module that encapsulates POE IKC specifiers.  An IKC
specifier is a way of designating either a kernel, a session or a state
within a IKC cluster.  

IKC specifiers have the folloing format :

    poe:://kernel/session/state

B<kernel> may a kernel name, a kernel ID, blank (for local kernel), a
'*' (all known foreign kernels) or host:port (not currently supported).

B<session> may be any session alias that has been published by the foreign
kernel.

B<state> is a state that has been published by a foreign session.

Examples :

=over 4

=item C<poe://Pulse/timeserver/connect>

State 'connect' in session 'timeserver' on kernel 'Pulse'.

=item C<poe:/timeserver/connect>

State 'connect' in session 'timeserver' on the local kernel.

=item C<poe://*/timeserver/connect>

State 'connect' in session 'timeserver' on any known foreign kernel.
    
=item C<poe://Billy/bob/>

Session 'bob' on foreign kernel 'Billy'.

=back

=head1 EXPORTED FUNCTIONS

=head2 C<specifier_parse($spec)>

Turn a specifier into the internal representation (hash ref).  Returns
B<undef()> if the specifier wasn't valid.

    print Dumper specifer_parse('poe://Pulse/timeserver/time');

would print

    $VAR1 = {
        kernel => 'Pulse',
        session => 'timeserver',
        state => 'time',
    };

B<Note> : the internal representation might very well change some day.

=head2 C<specifier_name($spec)>

Turns a specifier into a string.


=head1 BUGS

=head1 AUTHOR

Philip Gwyn, <perl-ikc at pied.nu>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2014 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/language/misc/Artistic.html>

=head1 SEE ALSO

L<POE>, L<POE::Component::IKC::Responder>

=cut

