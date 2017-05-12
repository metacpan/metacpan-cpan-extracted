package StateML::SAXHandler ;

$VERSION = 0.001 ;

=head1 NAME

StateML::SAXHandler - convert a SAX stream to a StateML::Machine

=head1 SYNOPSIS

    ## From StateML::parse()
    require StateML::SAXHandler;
    require XML::Filter::Mode;
    my $handler = StateML::SAXHandler->new( $machine ) ;

    my $mode_filter = XML::Filter::Mode->new(
        Handler => $handler,
        Modes   => [$machine->modes],
    );

    ## Require PurePerl for now to get the bugs out
    local $XML::ParserPackage = "XML::SAX::PurePerl";
    my $p = XML::SAX::ParserFactory->parser( 
        Handler           => $mode_filter,
        UseAttributeOrder => 1,
        Source            => $source,
    ) ;

    return $p->parse ;

=head1 DESCRIPTION

Use like a normal SAX handler, then collect the machine from the
SAX pipline's end_document() event. 

See L<XML::Filter::Modes|XML::Filter::Modes> for an oft-used
prefilter to "shape" your machines by giving elements to nodes.

See L<StateML|StateML>::parse() for source examples.

=cut

use strict ;
    
use Carp ;
use StateML::Machine;
use StateML::Constants qw( stateml_1_0_ns );

sub new {
    my $proto = shift ;
    my $class = ref $proto || $proto ;
    my $self = bless {
    }, $class ;
    $self->machine( @_ ) if @_ ;
    return $self ;
}


sub machine {
    my $self = shift ;
    $self->{MACHINE} = shift if @_ ;
    return $self->{MACHINE} ;
}


sub parser {
    my $self = shift ;
    $self->{PARSER} = shift if @_ ;
    return $self->{PARSER} ;
}


sub _location {
    my $self = shift ;
    return '';# unless $self->{DOC_LOCATOR};
    my $pl = $self->{DOC_LOCATOR};
    return join(
        " ",
        "",
        "at",
        defined $pl->{SystemId}
            ? "$pl->{SystemId},"
            : (),
        "line",
        $pl->{LineNumber},
        "column",
        $pl->{ColumnNumber}
    ) ;
}


sub _X {
    my $self = shift ;
    die @_, $self->_location, "\n" ;
}


sub _top {
    return shift->{ELT_STACK}->[-1] ;
}


sub set_document_locator {
    my $self = shift;

    $self->{DOC_LOCATOR} = shift;
}


sub start_document {
    my $self = shift ;
    $self->{ELT_STACK} = [
        { ELT => {Name => "#root"}},  ## Fake elt, so stack never empty
    ] ;
    $self->{InStateMLElt} = [ 0 ];
}

sub end_document { shift->machine }

## Poor excuse for a DTD :)
my %can_be_in = (
    "machine"       => [ "#root" ],
    "class"         => [ qw( machine state ) ],
    "state"         => [ qw( machine state ) ],
    "event"         => [ qw( machine arc ) ],
    "action"        => [ qw( machine ) ],

    "name"          => [ qw( state event action ) ],
    "description"   => [ qw( machine event state arc action ) ],

    "version"       => [ qw( machine ) ],
    "preamble"      => [ qw( machine ) ],
    "postamble"     => [ qw( machine ) ],

    "api"           => [ qw( event ) ],
    "pre-handler"   => [ qw( event ) ],
    "post-handler"  => [ qw( event ) ],

    "entry-handler" => [ qw( state ) ],
    "exit-handler"  => [ qw( state ) ],
    "arc"           => [ qw( state ) ],

    "handler"       => [ qw( event arc action ) ],
) ;


sub _stateml_attrs {
    my ( $elt ) = @_;

    ## Return a list of ( Name => $value ) pairs of all attrs in
    ## the empty namespace or in the StateML namespace
    (
        map {
            ( my $key = uc $_->{LocalName} ) =~ s/-/_/g;
            my $value = $_->{Value};
            $value = [ grep length, split /,/, $value ]
                if $key eq "CLASS_IDS";
            ( $key => $value );
        } grep $_->{NamespaceURI} eq ""
            || $_->{NamespaceURI} eq stateml_1_0_ns,
            values %{ $elt->{Attributes} }
    );
}


sub start_element {
    my $self = shift ;

    my ( $elt ) = @_ ;

    push @{$self->{InStateMLElt}}, $elt->{NamespaceURI} eq stateml_1_0_ns;
    if ( $self->{InStateMLElt}->[-1] ) {
        push @{$self->{InStateMLElt}}, 1;
        my $parent = $self->_top ;
        my $parent_type = $parent->{ELT}->{Name} ;

        my $elt_type = $elt->{Name} ;

        croak "<$elt> may not have a missing prefix\n"
            if substr( $elt, 0, 1 ) eq ":" ;
        croak "<$elt> may not have multiple prefixes\n"
            if substr( $elt, 0, 1 ) eq ":" ;

        my $h = {
            ELT      => $elt,
            LOCATION => $self->_location,
            _stateml_attrs $elt,
        } ;

        $elt_type =~ s/.*:// ;
        $elt->{Name} =~ s/.*:// ;

        $self->_X( "<$elt_type> not allowed in <$parent_type>" )
            unless grep $parent_type eq $_, @{$can_be_in{$elt_type}} ;

        if ( $elt_type eq "api" ) {
            push @{$parent->{APIS}}, $h ;
        }
        elsif ( $elt_type =~ /amble$/ ) {
            $h->{CODE} = "" ;
        }
        elsif ( $elt_type =~ /handler$/ ) {
            $h->{CODE} = "" ;
        }
        elsif ( $elt_type eq "action" ) {
            $h = StateML::Action->new( %$h ) ;
            $self->machine->add( $h ) ;
        }
        elsif ( $elt_type eq "class" ) {
            $h = StateML::Class->new( %$h ) ;
            $self->machine->add( $h ) ;
        }
        elsif ( $elt_type eq "event" ) {
            $h = StateML::Event->new( %$h ) ;
            $self->machine->add( $h ) ;
            if ( UNIVERSAL::isa( $parent, "StateML::Arc" ) ) {
                ## Bypass event_id() to prevent defaulting
                my $old_event_id = $parent->{EVENT_ID};
                my $id = $h->id;
                die
                "<arc event_id='$old_event_id'> conflicts with <event id='$id'>\n"
                    if defined $old_event_id && $old_event_id ne $id;
                $parent->event_id( $id );
            }
        }
        elsif ( $elt_type eq "machine" ) {
            $self->{MACHINE_ID} = $h->{ID};
            my $m = $self->machine ;
            $m->{$_} = $h->{$_} for grep !defined $m->{$_}, keys %$h;
            $h = $m ;
            $h->{ID} = "#MACHINE 1" unless defined $h->{ID};
        }
        elsif ( $elt_type eq "state" ) {
            my $id = $h->{ID};
            $self->_X( "<state> missing an id=" ) unless defined $id ;

            my $old_h = $self->machine->state_by_id( $id ) ;

            if ( $old_h ) {
                $old_h->{LOCATION} .= " and $h->{LOCATION}" ;
                $h = $old_h ;
                $h->{ELT} = $elt ;
            }
            else {
                $h = StateML::State->new(
                    %$h,
                    ELT            => $elt,
                    ID             => $id,
                    PARENT_ID      => $self->{MACHINE_ID},
                    ORDER          => scalar $self->machine->states,
                ) ;
                $self->machine->add( $h ) ;
            }
        }
        elsif ( $elt_type eq "arc" ) {
            $h->{TO} = delete $h->{GOTO} if exists $h->{GOTO};
            $h = StateML::Arc->new( %$h ) ;
            $h->from( $parent->id ) unless defined $h->from;
            $h->to( $parent->id )   unless defined $h->to;
            $self->machine->add( $h ) ;
        }

        $h->{LOCATION} = $self->_location ;

        $h->{ATTRS} = {
            map
                { ( $_ => $elt->{Attributes}->{Value} ); }
                keys %{$elt->{Attributes}}
        };

        push @{$self->{ELT_STACK}}, $h ;
    }
}


sub characters {
    my $self = shift ;
    my ( $h ) = @_ ;
    return unless $self->{InStateMLElt}->[-1];

    my $parent = $self->_top ;
    my $elt_type =  $parent->{ELT}->{Name} ;
    if ( $elt_type =~ /handler$/ && ! $parent->{ACTION_ID} ) {
        $parent->{CODE} .= $h->{Data} ;
    }
    elsif ( $elt_type =~ /amble$/ ) {
        $parent->{CODE} .= $h->{Data} ;
    }
    elsif ( $elt_type eq "api" ) {
        $self->_X( "stack underflow" ) unless @{$self->{ELT_STACK}} >= 2 ;
        $self->{ELT_STACK}->[-2]->{API} .= $h->{Data} ;
    }
    elsif ( $elt_type eq "name" ) {
        $self->_X( "stack underflow" ) unless @{$self->{ELT_STACK}} >= 2 ;
        $self->{ELT_STACK}->[-2]->{NAME} .= $h->{Data} ;
    }
    elsif ( $elt_type eq "description" ) {
        $self->_X( "stack underflow" ) unless @{$self->{ELT_STACK}} >= 2 ;
        $self->{ELT_STACK}->[-2]->{DESCRIPTION} .= $h->{Data} ;
    }
    elsif ( $h->{Data} =~ /\S/ ) {
        my $location = $self->_location || '' ;
        warn "Ignoring '$h->{Data}' in <$elt_type>$location.\n" ;
    }
}


sub _deindent {
    my $ltrim;

    for ( $_[0] =~ /\n( *)\S/mg ) {
        $ltrim = length if ! defined $ltrim || length $_ < $ltrim;
    }

    $_[0] =~ s/[ \t]+$//;  ## Remove trailing spaces.
    $_[0] =~ s/^([ \t]*\n)+//;  ## Remove leading blank lines

    return unless defined $ltrim;

    $_[0] =~ s/^ {$ltrim}//mg;
}


sub end_element {
    my $self = shift ;
 
    my ( $elt ) = @_ ;

    if ( $self->{InStateMLElt}->[-1] ) {

        my $popped = pop @{$self->{ELT_STACK}} ;
        my $elt_type = $popped->{ELT}->{Name} ;

        $elt->{Name} =~ s/.*:// ;
        $self->_X( "</$elt->{Name}> found, expected </$elt_type>" )
            unless $elt->{Name} eq $elt_type ;

        my $parent = $self->_top ;

        if ( $elt_type =~ /handler$/ ) {
            my $htype = uc $elt->{Name} ;
            $htype =~ tr/-/_/ ;
            my $code = defined $popped->{ACTION_ID}
                ? \$popped->{ACTION_ID}
                : do {
                    _deindent $popped->{CODE}
                        unless defined $parent->{DEINDENT} && ! $parent->{DEINDENT};
                    $popped->{CODE};
                };
            push @{$parent->{"${htype}S"}}, $code;
        }

        if ( $elt_type =~ /amble$/ ) {
            my $htype = uc $elt->{Name} ;
            _deindent $popped->{CODE}
                unless defined $parent->{DEINDENT} && ! $parent->{DEINDENT};
            push @{$parent->{$htype}}, $popped->{CODE} ;
        }
    }

    pop @{$self->{InStateMLElt}};
}

=head1 LIMITATIONS

Alpha code.  Ok test suite, but we may need to change things in
non-backward compatible ways.

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1 ;
