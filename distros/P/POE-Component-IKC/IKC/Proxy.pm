# $Id: Proxy.pm 1247 2014-07-07 09:06:34Z fil $
package POE::Component::IKC::Proxy;

##############################################################################
# $Id: Proxy.pm 1247 2014-07-07 09:06:34Z fil $
# Copyright 1999-2014 Philip Gwyn.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Contributed portions of IKC may be copyright by their respective
# contributors.  

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $ikc_kernel);
use Carp;
use Data::Dumper;

use POE qw(Session);
use POE::Component::IKC::Specifier;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(create_ikc_proxy);
$VERSION = '0.2402';

sub DEBUG { 0 }

sub create_ikc_proxy
{
    __PACKAGE__->spawn(@_);
}

sub spawn
{
    my($package, $r_kernel, $r_session, $monitor_start, $monitor_stop)=@_;

    my $name=specifier_name({kernel=>$r_kernel, session=>$r_session});
    my $t=$poe_kernel->alias_resolve($name);

    if($t) {
        # why is this commented out?
       # $poe_kernel->call($t, '_add_callback', $r_kernel, $r_session);
    } 
    else {
        POE::Session->create( 
            package_states => [
                        $package => 
                            [qw(
                                _start _stop _delete _default 
                                _shutdown _add_callback
                            )],
                    ],
            args=> [$name, $r_kernel, $r_session, 
                            $monitor_start, $monitor_stop]
                    );
    }
}

sub _start
{
    my($kernel, $heap, $name, $r_kernel, $r_session, $monitor_start, 
                                                     $monitor_stop)=
                    @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3, ARG4];
    
    $heap->{name}=$name;
    $heap->{monitor_stop}=$monitor_stop;
    $heap->{callback}=[];
    _add_callback($heap, $r_kernel, $r_session);

    DEBUG && warn "$$: Proxy for $name ($r_session) created\n";
    $kernel->alias_set($name);
    $kernel->alias_set($r_session)
        unless $kernel->alias_resolve( $r_session );

    # monitor for shutdown events.  
    # this is the best way to get IKC::Responder to tell us about the 
    # shutdown
    $kernel->post(IKC=>'monitor', '*', {shutdown=>'_shutdown'});

    &$monitor_start;
}

sub _shutdown
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    $kernel->alias_remove($heap->{name});
    my $spec=specifier_parse($heap->{name});
    $kernel->alias_remove($spec->{session}) if $spec;
}

sub _add_callback
{
    my($heap, $r_k, $r_s)=@_[HEAP, ARG0, ARG1];
    ($heap, $r_k, $r_s)=@_ if not $heap;
    
    push @{$heap->{callback}},  { kernel=>$r_k, 
                                  session=>$r_s, 
                                  state=>'IKC:proxy'
                                };
}

sub _delete
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    $kernel->alias_remove($heap->{name});    
}

sub _stop
{
    my($kernel, $heap)=@_[KERNEL, HEAP];
    DEBUG && warn "$$: Proxy for $heap->{name} deleted\n";
    &{$heap->{monitor_stop}};
}



sub _default
{
    my($kernel, $heap, $state, $args, $sender)=
                    @_[KERNEL, HEAP, ARG0, ARG1, SENDER];
    return if $state =~ /^_/;

    # use Data::Dumper;
    # warn "$$: _default args=", Dumper $args;
    if(not $heap->{callback})
    {
        warn "$$: Attempt to respond to a callback with $state\n";
        return;
    }

    DEBUG && warn "$$: Proxy $heap->{name}/$state posted.\n";
    # use Data::Dumper;
    # warn "$$: _default args=", Dumper $args;
    my $ARG = [$state, [@$args]];
    foreach my $r_state (@{$heap->{callback}}) {
        # warn "$$: _default ARG=", Dumper $ARG;
        $kernel->call('IKC', 'post2', $r_state, $sender, $ARG);
    }
    return;
}

1;

__END__

=head1 NAME

POE::Component::IKC::Proxy - POE IKC proxy session

=head1 SYNOPSIS

=head1 DESCRIPTION

Used by IKC::Responder to create proxy sessions when you subscribe to a
remote session.  You probably don't want to use it directly.

=head1 AUTHOR

Philip Gwyn, <perl-ikc at pied.nu>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2014 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/language/misc/Artistic.html>

=head1 SEE ALSO

L<POE>, L<POE::Component::IKC>

=cut


