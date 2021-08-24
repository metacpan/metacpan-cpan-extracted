#!perl

use 5.010;
use strict;
use warnings;
use lib '../lib'; # omit if MooseX::Traits::SetScalarByRef is installed
use MooseX::Traits::SetScalarByRef;
use Scalar::Util qw(refaddr);

=comment

This example shows for what this module was originally intended:
to glue Tk's bindvariable to Moose attributes.

=cut

{
    package Local::Example;
    use Moose;
    use Moose::Util::TypeConstraints;
    use Tk;
    use Tk::LabEntry;

    subtype 'TkRef', as 'ScalarRef';
    coerce 'TkRef', from 'Str', via { my $r = $_; return \$r };

    has _some_val => (
        traits   => [ 'MooseX::Traits::SetScalarByRef' ],
        isa      => 'TkRef',
        init_arg => 'some_val',
        default  => 'default value',
        handles  => 1,
    );
    
    sub run {
        my $self = shift;
        
        my $mw = Tk::MainWindow->new;
        
        $mw->LabEntry(
            -label        => 'This entry will update along with the entry. Both share a bindvariable.',
            -labelPack    => [-side => 'top', -anchor => 'w',],
            -width        => 35,
            -textvariable     => $self->some_val,
        )->pack;
        
        $mw->Label(
            -textvariable => $self->some_val,
        )->pack;
        
        $mw->Button(
            -text => 'set some_val to localtime',
            -command => sub{
                $self->some_val("localtime (hrhr)");
            },
        )->pack;
        
        $mw->MainLoop;
        
        return;
    } # /run
    
}

my $eg = Local::Example->new;
$eg->run;
exit(0);