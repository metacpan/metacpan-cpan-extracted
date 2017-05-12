package RINO::Client;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.03';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

use Module::Pluggable require => 1;
require XML::IODEF;

# Preloaded methods go here.

sub _plugins {
    my @plugs = plugins();
    foreach (@plugs){
        $_ = lc($_);
        $_ =~ s/rino::client::plugin:://;
    }
    return(@plugs);
}

sub new {
    my ($class,%args) = (shift,@_);
    my $self = {};
    bless($self,$class);
    if($args{'iodef'}){
        $self->to_hash($args{'iodef'});
    }
    return($self);
}

sub write_out {
    my $self = shift;
    my $plugin = shift || 'csv';

    $plugin = 'RINO::Client::Plugin::'.ucfirst($plugin);
    eval "require $plugin";
    die($@) if($@);

    my $ref = $self->to_simple();
    return $plugin->write_out($ref);
}

sub to_hash {
    my $self = shift;
    my $xml = shift;
    return($self->{'_tree'}) if(defined($self->{'_tree'}));

    return unless($xml);
    my $iodef = XML::IODEF->new();
    $iodef->in($xml) || return('invalid iodef object',undef);
    $self->{'_xml'} = $iodef;
    $self->{'_tree'} = $iodef->to_tree();
    return(undef,$self->{'_tree'});
}

sub to_simple {
    my $self = shift;
    my $xml = shift;
    my $hash = $self->to_hash($xml); 
    my @incidents;
    my @header = ['IncidentID','Description','Address','DetectTime','Port','Destination','AdditionalData'];

    $hash = $hash->{'Incident'};
    if(ref($hash) eq 'HASH'){
        push(@incidents,$hash);
    } else {
        @incidents = @{$hash};
    }

    #only pass back the header info if we're being called from a plugin
    my $caller = caller();
    my @return_array;
    if($caller =~ /Client$/){
        @return_array = @header;
    }

    foreach my $ri (@incidents) {
        ## embedded " in CSV needs to be ""
        $ri->{IncidentID}{content} =~ s/"/""/g;
        $ri->{Description} =~ s/"/""/g;

        ## within each Incident there may be one or more EventData, "normalize"
        my $re = $ri->{'EventData'};
        my @events_array = ();
        if(ref($re) eq 'HASH') { push(@events_array,$re); } else { @events_array = @{$re}; }

        ## process each EventData
        foreach my $re (@events_array) {
            $re->{DetectTime} =~ s/"/""/g;
            $re->{Flow}{System}{Node}{Address}{content} =~ s/"/""/g;
            if (exists $re->{Flow}{System}{Service}{Port}) {
                $re->{Flow}{System}{Service}{Port} =~ s/"/""/g;
            } else {
                $re->{Flow}{System}{Service}{Port} = '';
            }

            ## within each EventData there may be zero or more AdditionalData
            ## if "destination address" is one of those, it will have it's own position in the CSV
            ## all others will be combined into paired values (JSON-like) and placed in one position in the CSV
            my $destination = '';
            my $additional;

            if (exists $re->{AdditionalData}) {
                ## "normalize"
                my $ra = $re->{AdditionalData};
                my @additionaldata_array = ();
                if(ref($ra) eq 'HASH') { push(@additionaldata_array,$ra); } else { @additionaldata_array = @{$ra}; }

                ## process each AdditionalData
                foreach my $a (@additionaldata_array) {
                    ## if "destination address", then hold separately, otherwise accumulate pairs in $additional
                    if ($a->{meaning} eq 'destination address') {
                        $destination = $a->{content};
                    } else {
                        $additional .= qq|"$a->{meaning}":"$a->{content}", |;
                    }
                }
                ## if there is additiona, remove trailing comma and wrap in braces
                if ($additional) { $additional =~ s/, $//; $additional = '{ '.$additional.' }'; }
            }
            push(@return_array, {
                IncidentID  => $ri->{'IncidentID'}{'content'},
                Description => $ri->{'Description'},
                Address     => $re->{'Flow'}{'System'}{'Node'}{'Address'}{'content'},
                DetectTime  => $re->{'DetectTime'},
                Port        => $re->{'Flow'}{'System'}{'Service'}{'Port'},
                Destination => $destination,
                AdditionalData  => $additional
           });
        }
    }
    return(\@return_array);
}
    

sub sources {
    my $self = shift;
    return('you must ->to_hash($xml) first',undef) unless($self->{'_tree'});
    my $h = $self->{'_tree'};
    my @events = @{$h->{'Incident'}->{'EventData'}};
    foreach my $event (@events){
        my $sys = $event->{'Flow'}->{'System'};
        next unless($sys->{'category'} eq 'source');
    }

}
1;
__END__
=head1 NAME

RINO::Client - Perl extension for parsing and handling RINO data

=head1 SYNOPSIS

 # using the command line client
 $ rino -h
 $ rino -f /tmp/rino.xml -p table
 $ rino -f /tmp/rino.xml -p csv
 $ cat /tmp/rino.xml | rino -p json

 # using the lib
 use RINO::Client;

 my @input;
 while(<STDIN>){
    push(@input,$_);
 }
 my $iodef_xml = join("",@input);

 my $rino = RINO::Client->new(iodef => $iodef_xml);
 print $rino->write_out('table');
 print $rino->write_out('csv');
 print $rino->write_out('json');

 my $simple_hash = $rino->to_simple();
 my $complex_hash = $rino->to_hash();

=head1 SEE ALSO

  http://tools.ietf.org/html/rfc5070
  http://www.ren-isac.net/notifications/using_iodef.html
  http://code.google.com/p/collective-intelligence-framework/
  XML::IODEF

=head1 AUTHOR

  Wes Young, E<lt>wes@ren-isac.netE<gt>
  Doug Pearson, E<lt>dodpears@ren-isac.netE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2011 by Wes Young
  Copyright (C) 2011 by Doug Pearson
  Copyright (C) 2010 REN-ISAC and The Trustees of Indiana University

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
