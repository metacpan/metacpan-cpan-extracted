package t::Client;

use strict;
use warnings;
use Data::Dumper;
use Carp;

use JSON::XS;

our $HAVE_ALGORITHM_DIFF;
BEGIN {
    eval "use Algorithm::Diff";
    $HAVE_ALGORITHM_DIFF = 1 unless $@;
}


use constant DEBUG => 0;
my $NODES = {};

*is = \&main::is;
*ok = \&main::ok;
*isnt = \&main::isnt;
*diag = \&main::diag;
*fail = \&main::fail;
*pass = \&main::pass;


#################################################################
sub new 
{
    my $package = shift;
    my $self = bless { @_ }, $package;
    $self->{APP} ||= 'Test';
    $self->{PORT} ||= 8881;
    $self->{HOST} ||= 'localhost';
    $self->{name} ||= '';
    $self->{NODES} = $NODES;
    $self->{NODES} = {} if $self->{parent};
    $self->{R} = 0;
    return $self;
}


######################################################
sub get_node
{
    my( $self, $id ) = @_;
    return $self->{NODES}->{$id};
}

######################################################
sub find_ID
{
    my( $self, $id ) = @_;
    return $self->{NODES}->{ $id };
}

######################################################
sub decode_resp
{
    my( $self, $resp, $phase ) = @_;
    ok( $resp->is_success, "'$phase' successful" );
    
    is( scalar $resp->content_type, 'application/json', 
            "Right content type" ) or die $resp->content;

    my $content = $resp->content;
    # warn "content='$content'";
    my $data;
    if( $JSON::XS::VERSION > 2 ) {
        $data = JSON::XS::decode_json( $content );
    }
    else {
        $data = JSON::XS::from_json( $content );
    }
    is( ref( $data ), 'ARRAY', "'$phase' returned an array" ) or die Dumper $data;
    return $data;
}

######################################################
sub check_boot
{
    my( $self, $data ) = @_;

    is( $data->[0][0], 'SID', "First response is the SID" );
    my $n = 1;
    if( $data->[$n][0] ne 'for' ) {
        is( $data->[$n][0], 'boot', "Second response is the boot" );
        ok( $data->[$n][1],         " ... message" );
        $n++;
    }
    is( $data->[$n][0], 'for', "Next response is for" );
    is( $data->[$n][1], '',    " ... the main window" );
    $n++;
    is( $data->[$n][0], 'new', "Last response is the new" );
    is( $data->[$n][2], 'window', " ... window" );
}

######################################################
sub handle_resp
{
    my( $self, $data, $phase ) = @_;

    local $self->{deleted} = {};
    return unless @$data;

#    warn Dumper $data;
    my %accume;
    my $for = $self->{name};
    foreach my $I ( @$data ) {
        next unless $I->[0];
        if( $I->[0] eq 'for' ) {
            $for = $I->[1];
            next;
        }
        if( $for eq $self->{name} ) {
            $self->handle_one( @$I );
        }
        else {
            push @{ $accume{$for} }, $I;
        }
    }

    if( %accume ) {
        # warn "accume=", Dumper \%accume;
        if( $self->{parent} ) {
            $self->{parent}->for_window( \%accume, $phase );
        }
        else {
            $self->for_window( \%accume, $phase );
        }
    }
    my $close = delete $self->{close_window};
    return unless $close and @$close;
    foreach my $id ( @$close ) {
        $self->close_window( $id );
    }
}

######################################################
sub for_window
{
    my( $self, $accume, $phase ) = @_;
    Carp::carp "Must be parent" if $self->{parent} or $self->{name};

    foreach my $id ( keys %$accume ) {
        my $win = $self->{windows}{ $id };
        $win = $win->{browser} if $win;
        my $name = $id;
        if( $id eq '' ) {
            $win = $self;
            $name = 'main window';
        }
    
        ok( $win, "Instructions for |$name|" ) or die "PAIN FOLLOWS";
        $win->handle_resp( $accume->{ $id }, $phase );
    }
}

######################################################
sub handle_one
{
    my( $self, $op, $id, @args ) = @_;
    return unless $op;
    if( $op eq 'ERROR' ) {
        die $args[0];
    }

    return if $id and $self->{deleted}{ $id };
    if( $op eq 'SID' ) {
        ok( !$self->{SID}, "New SID $id" );
        $self->{SID} = $id;
    }
    elsif( $op eq 'boot' ) {
        ok( !$self->{boot}, "Boot message '$id'" );
        $self->{boot} = $id;
    }
    elsif( $op eq 'textnode' ) {
        ok( defined( $args[1] ), "Got a $id.textnode" );
        ok( $self->{NODES}->{$id}, " ... and we have its parent ($id)" )
                or die "$self->NODES=", 
                           sort keys %{ $self->{NODES} };
        my $parent = $self->{NODES}->{$id}{zC};
        if( $args[0] < 0 ) {
            push @$parent, { tag=>'textnode', nodeValue=>$args[1] };
        } 
        else {
            ok( ( $args[0] <= @{$parent} ), " ... and this isn't impossible" );
            my $tn = $parent->[ $args[0] ];
            if( $tn and $tn->{tag} eq 'textnode' ) {
                $tn->{nodeValue} = $args[1];
            }
            else {
                $parent->[ $args[0] ] =
                    { tag=>'textnode', nodeValue=>$args[1] };
            }
        }
    }
    elsif( $op eq 'cdata' ) {
        ok( defined( $args[1] ), "Got a cdata $id" );
        ok( $self->{NODES}->{$id}, " ... and we have its parent ($id)" );
        my $parent = $self->{NODES}->{$id}{zC};
        ok( ( $args[0] <= @{$parent} ), " ... and this isn't way out there" );
        if( $args[0] < 0 ) {
            push @$parent, { tag=>'cdata', cdata=>$args[1] };
        }
        else {
            my $tn = $parent->[ $args[0] ];
            if( $tn and $tn->{tag} eq 'cdata' ) {
                $tn->{nodeValue} = $args[1];
            }
            else {
                $parent->[ $args[0] ] =
                    { tag=>'cdata', cdata=>$args[1] };
            }
        }
    }
    elsif( $op eq 'new' ) {
        ok( ! $self->{NODES}->{$id}, "New node $id" );
        ok( $args[0], " ... with a tag type" );
        my $new = $self->{NODES}->{$id} = 
                    { tag => $args[0], id=>$id, zC=>[] };
        if( $args[1] ) {
            my $parent = $self->{NODES}->{$args[1]};
            ok( $parent, " ... and we have its parent ($args[0] wants $args[1])" );

            if( $args[2] < 0 ) {
                $parent->{zC} ||= [];
                push @{ $parent->{zC} }, $new;
            }
            else {
                my $old = $parent->{zC}[ $args[2] ];
                if( $old ) {
                    delete $self->{NODES}->{ $old->{id} };
                }

                $parent->{zC}[ $args[2] ] = $new;
            }
        }
        if( ($new->{tag}||'') eq 'window' ) {
            ok( !$self->{W}, "New window" );
            $self->{W} = $new;
        }
    }
    elsif( $op eq 'set' ) {
        ok( 2==@args, "Going to set attribute $args[0]" );
        my $m = 'an existing node'; 
        $m = $args[1] if $args[0] eq 'id';
        ok( $self->{NODES}->{$id}, " ... on $m" )
                or die "Where is $id in ", join ', ', sort keys %{ $self->{NODES} }, 
                                Dumper [ $op, $id, @args ];

        isnt( $self->{NODES}->{$id}{tag}, 'textnode', 
                        "One can't reference a text node!" );

        if( $args[0] eq 'id' ) {
            my $N = delete $self->{NODES}->{$id};
            DEBUG and diag( "$N->{id} -> $args[1]" );
            $N->{id} = $args[1];
            $self->{NODES}->{ $N->{id} } = $N;
        }
        else {
            $self->{NODES}->{$id}{$args[0]} = $args[1];
        }
    }
    elsif( $op eq 'remove' ) {
        ok( 1==@args, "Going to remove attribute $args[0]" );
        ok( $self->{NODES}->{$id}, " ... on an existing node" )
                or die "Where is $id in ", join ', ', sort keys %{ $self->{NODES} }, 
                                Dumper [ $op, $id, @args ];

        delete $self->{NODES}->{$id}{$args[0]};
    }
    elsif( $op eq 'bye' ) {
        next unless $self->{NODES}->{$id};

        ok( 0==@args, "Going to delete element $id" );
        ok( $self->{NODES}->{$id}, " ... we know that node" );
        isnt( $self->{NODES}->{$id}{tag}, 'textnode', 
                        " ... can't reference a text node" );
        my $old = delete $self->{NODES}->{$id};

        my( $parent, $index ) = $self->find_parent( $old );

        if( $parent and defined $index ) {
            ok( $parent, " ... and we know the parent" );
            ok( defined $index, " ... we know the offset" );
            my $node = splice @{ $parent->{zC} }, $index, 1;
            is( $old, $node, " ... it's right node" );
        }
        else {
            pass( " ... parent is already bye-bye" );
        }
        $self->drop_node( $old );
    }
    elsif( $op eq 'bye-textnode' ) {
        ok( 1==@args, "Going to delete textnode $args[0] from $id" );
        if( $self->{NODES}->{$id} ) {
            ok( $self->{NODES}->{$id}, " ... we know of the node" );
            ok( ( $args[0] < @{ $self->{NODES}->{$id}{zC} } ), " ... in range" );
            my $node = splice @{ $self->{NODES}->{$id}{zC} }, $args[0], 1;
            is( $node->{tag}, 'textnode', " ... it's a textnode" );
        }
        else {
            pass( " ... already bye-bye" );
        }
    }
    elsif( $op eq 'framify' ) {
        ok( 0==@args, "Going to framify element $id" );
        ok( $self->{NODES}->{$id}, " ... we know of the node" );
        isnt( $self->{NODES}->{$id}{tag}, 'textnode', 
                        " ... can't framify a text node" );
        my $old = delete $self->{NODES}->{$id};

        my( $parent, $index ) = $self->find_parent( $old );

        ok( $parent, " ... and we know the parent of $old->{id}" )
                or die "We need to know the parent!";
        ok( ( $index < @{ $parent->{zC} } ), " ... in range" );

        my $new = {
                    tag => 'iframe',
                    id  => "IFRAME-$old->{id}",
                    src => { type      => 'XUL-from', 
                             source_id => $old->{id}
                           }
                };
        ok( !$self->{NODES}->{$new->{id}}, " ... never been framified" );
        $self->{NODES}->{$new->{id}} = $new;

        my $node = splice @{ $parent->{zC} }, $index, 1, $new;
        is( $old, $node, " ... it's right node" );
        $self->drop_node( $node );
    }
    elsif( $op eq 'timeslice' ) {
        # ignore
    }
    elsif( $op eq 'popup_window' ) {
        $self->popup_window( $id, @args );
    }
    elsif( $op eq 'close_window' ) {
        push @{ $self->{close_window} }, $id;
    }
    elsif( $op eq 'timeslice' ) {
        # ignore it
    }
    elsif( $op eq 'style' ) {
        ok( 2==@args, "Going to set style $args[0]" );
        ok( $self->{NODES}->{$id}, " ... on an existing node" )
                or die "Where is $id in ", join ', ', sort keys %{ $self->{NODES} }, 
                                Dumper [ $op, $id, @args ];

        my $N = $self->{NODES}->{$id};
        
        isnt( $N->{tag}, 'textnode', "One can't set the style of a text node!" );
        
        $self->{style} ||= {};
        if( not ref $N->{style} ) {
            $N->{style} = { map { split /:\s*/, $_, 2 } 
                                split /;\s*/, $N->{style} #**
                          };
        }
        $N->{style}{$args[0]} = $args[1];
    }
    else {
         die "What do i do with op=$op";
    }
}

######################################################
sub find_parent
{
    my( $self, $node ) = @_;
    return unless defined $node;
    foreach my $N ( values %{$self->{NODES}} ) {
        next if $N->{tag} eq 'textnode' or $N->{tag} eq 'cdata';
        use Data::Dumper;
        die Dumper $N unless $N->{zC};
        for( my $q1=0; $q1 < @{ $N->{zC} }; $q1++ ) {
            unless( defined $N->{zC}[ $q1 ] ) {
                # die "$q1=", Dumper $N->{zC};
                next;
            }
            next unless $N->{zC}[$q1] == $node;
            return $N, $q1 if wantarray;
            return $N;
        }
    }
    return;
}

############################################################
sub is_visible
{
    my( $self, $node ) = @_;
    $node = $self->find_ID( $node ) unless ref $node;
    return unless $node;
    my $style = $self->style( $node );
    return not ( $style =~ /display:\s*none/ );
}

######################################################
sub style
{
    my( $self, $node ) = @_;
    my $S = $node->{style};
    return '' unless $S;
    return $S unless ref $S;
    
    return join "\n", map { "$_: $S->{$_};" } sort keys %$S;
}


######################################################
sub nodeText
{
    my( $self, $node ) = @_;
    return $node->{nodeValue} if $node->{tag} eq 'textnode';
    my @ret;
    foreach my $N ( @{ $node->{zC} } ) {
        push @ret, $self->nodeText( $N );
    }
    return @ret if wantarray;
    return join " ", @ret;
}

######################################################
sub drop_node
{
    my( $self, $node ) = @_;
    if( $node->{id} ) {
        delete $self->{NODES}->{ $node->{id} };
        $self->{deleted}{ $node->{id} } = 1;
    }

    return if not $node->{tag} or $node->{tag} eq 'textnode' or $node->{tag} eq 'cdata';
    foreach my $C ( @{ $node->{zC} } ) {
        $self->drop_node( $C );
    }
    $node->{zC} = [];
}

######################################################
sub root_uri
{
    my( $self ) = @_;
    return URI->new( "http://$self->{HOST}:$self->{PORT}/" );
}

######################################################
sub base_uri
{
    my( $self ) = @_;
    return URI->new( "http://$self->{HOST}:$self->{PORT}/xul" );
}

######################################################
sub default_args
{
    my( $self ) = @_;
    return ( version=>1, window=>$self->{name}, reqN=> $self->{R}++ );
}

######################################################
sub boot_uri
{
    my( $self ) = @_;
    my $URI = $self->base_uri;
    $URI->query_form( $self->boot_args );
    return $URI;
}

######################################################
sub boot_args
{
    my( $self, $button ) = @_;
    return { $self->default_args, app=> $self->{APP} };
}

######################################################
sub list_ID
{
    my( $self ) = @_;
    my @list = sort grep { !/^PX/ } keys %{ $self->{NODES} };
    return join ', ', @list unless wantarray;
    return @list;
}

sub find_by_tag
{
    my( $self, $tag ) = @_;

    return map { $self->find_ID( $_ ) } $self->list_by_tag( $tag );
}

sub list_by_tag
{
    my( $self, $tag ) = @_;
    my @list;
    foreach my $id ( keys %{ $self->{NODES} } ) {
        my $node = $self->find_ID( $id );
        next unless $node->{tag} eq $tag;
        push @list, $id;
    }
    return join ', ', @list unless wantarray;
    return @list;
}

sub find_by_attr
{
    my( $self, $attr, $want ) = @_;
    foreach my $node ( values %{ $self->{NODES} } ) {
        next unless ($node->{$attr}||'') eq $want;
        return $node;
    }
    return;
}


######################################################
sub test_node
{
    my( $self, $node, $type ) = @_;
    my $name = $node;
    unless( ref $node ) {
        $node = $self->find_ID( $node );
    }
    else {
        $name = $node->{id};
    }
    $type ||= 'node';
    ok( $node, "Found $type $name" )
            or die "I really need that $type\nHave: ". $self->list_ID;
    return $node;    
}

######################################################
sub Click
{
    my( $self, $button ) = @_;

    unless( ref $button ) {
        diag( "Clicking $button" ) if not $ENV{AUTOMATED_TESTING};
        $button = $self->test_node( $button, 'button' );
    }
    else {
        diag( "Clicking $button->{id}" ) if not $ENV{AUTOMATED_TESTING};
    }

    my $URI = $self->Click_uri( $button );
    my $resp = $self->{UA}->get( $URI );
    my $data = $self->decode_resp( $resp, "Click $button->{id}" );
    die $data->[0][2] if $data->[0][0] eq 'ERROR';
    $self->handle_resp( $data, "Click $button->{id}" );
}

######################################################
sub Click_uri
{
    my( $self, $button ) = @_;
    ok( $button->{id}, "Clicking on [ $button->{id} ]" );
    my $URI = $self->base_uri;
    $URI->query_form( $self->Click_args( $button ) );
    return $URI;
}

######################################################
sub Click_args
{
    my( $self, $button ) = @_;
    return {    $self->default_args, 
                app => $self->{APP}, 
                SID => $self->{SID}, 
                event => 'Click', 
                source_id => $button->{id}
            };
}

######################################################
sub Change
{
    my( $self, $node, $value ) = @_;
    $node = $self->find_ID( $node ) unless ref $node;
    ok( $node, "Found $node->{id}" ) or die "I really need that node";

    $node->{value} = $value;

    my $URI = $self->Change_uri( $node );
    my $resp = $self->{UA}->get( $URI );
    my $data = $self->decode_resp( $resp, "Change $node->{id}" );
    die Dumper $data if $data->[0] and $data->[0][0] eq 'ERROR';
    $self->handle_resp( $data, "Change $node->{id}" );    
}

######################################################
sub Change_uri
{
    my( $self, $textbox ) = @_;
    ok( $textbox->{id}, "Changing on $textbox->{id}" );
    my $URI = $self->base_uri;
    $URI->query_form( $self->Change_args( $textbox ) );
    return $URI;
}

######################################################
sub Change_args
{
    my( $self, $textbox ) = @_;
    return {    $self->default_args, 
                app => $self->{APP}, 
                SID => $self->{SID}, 
                event => 'Change', 
                source_id => $textbox->{id},
                value => $textbox->{value}
            };
}

######################################################
sub Select_args
{
    my( $self, $textbox ) = @_;
    return {    $self->default_args, 
                app => $self->{APP}, 
                SID => $self->{SID}, 
                event => 'Select', 
                source_id => $textbox->{id},
                selectedIndex => $textbox->{selectedIndex}
            };
}

######################################################
sub RadioClick_args
{
    my( $self, $RG, $index ) = @_;

    ok( $RG, "Going to click a radio" );

    my $selectedId;
    if( ref $index ) {
        $selectedId = $index->{id};
    }
    else {
        my $radio = $RG->{zC}[ $index ];
        ok( $radio, " ... got the radio" );
        is( $radio->{tag}, 'radio', " ... yep, it's a radio" );
        $selectedId = $radio->{id};
    }


    return {    $self->default_args, 
                app => $self->{APP}, 
                SID => $self->{SID}, 
                event => 'RadioClick', 
                source_id => $RG->{id},
                selectedId => $selectedId
            };
}

############################################################
sub Connect
{
    my( $self ) = @_;
    my $URI = $self->Connect_uri;
    my $resp = $self->{UA}->get( $URI );
    my $data = $self->decode_resp( $resp, "Connect $self->{name}" );
    die Dumper $data if $data->[0][0] eq 'ERROR';
    $self->handle_resp( $data, "Connect $self->{name}" );    
}

sub Connect_uri
{
    my( $self ) = @_;

    my $URI = $self->base_uri;
    $URI->query_form( $self->Connect_args );
    return $URI;
}

sub Connect_args
{
    my( $self ) = @_;
    return {    $self->default_args, 
                app => $self->{APP}, 
                SID => $self->{SID},
                event  => 'connect',
                window => $self->{name}
           };
}

######################################################
sub Disconnect
{
    my( $self, $win ) = @_;
    die "Must be parent" if $self->{parent} or $self->{name};
    my $URI = $self->Disconnect_uri( $win );
    my $resp = $self->{UA}->get( $URI );
    my $data = $self->decode_resp( $resp, "Disconnect $win->{name}" );
    # warn "Disconnect name=$self->{name} data=", Dumper $data;
    $self->handle_resp( $data, "Disconnect $win->{name}" );    
}

sub Disconnect_uri
{
    my( $self, $win ) = @_;

    my $URI = $self->base_uri;
    $URI->query_form( $self->Disconnect_args( $win ) );
    return $URI;
}

sub Disconnect_args
{
    my( $self, $win ) = @_;
    return {    $self->default_args, 
                app => $self->{APP}, 
                SID => $self->{SID},
                event  => 'disconnect',
                window => $win->{name},
           };
}

######################################################
sub Close
{
    my( $self ) = @_;
    croak "Not allowed to close the main window!" unless $self->{parent};
    $self->close_window( $self->{name} );
}


######################################################
sub SearchList_args
{
    my( $self, $SL, $string ) = @_;

    ok( $SL, "Going to search a search-list" );
    ok( $string, " ... for '$string'" );

    return {    $self->default_args, 
                app => $self->{APP}, 
                SID => $self->{SID}, 
                event => 'SearchList', 
                source_id => $SL->{id},
                value => $string
            };
}

############################################################
sub server_size
{
    my( $self, $UA ) = @_;
    my $SIZEuri = $self->base_uri;
    $SIZEuri->path( '/__poe_size' );

    my $resp = $UA->get( $SIZEuri );
    ok( $resp->is_success, "Got the kernel size" );
    is( $resp->content_type, 'text/plain', " ... as text/plain" );

    my $size = 0+$resp->content;
    ok( $size, " ... and it is non-null" );
    return $size;
}

############################################################
sub server_dump
{
    my( $self, $UA ) = @_;
    my $URI = $self->base_uri;
    $URI->path( '/__poe_kernel' );

    my $resp = $UA->get( $URI );
    ok( $resp->is_success, "Got the kernel dump" );
    is( $resp->content_type, 'text/plain', " ... as text/plain" );

    return $resp->content;
}

############################################################
sub compare_dumps
{
    my( $self, $DUMP1, $DUMP2 ) = @_;
    return unless $HAVE_ALGORITHM_DIFF;

    my $diff = Algorithm::Diff->new( [ split "\n", $DUMP1 ],
                                     [ split "\n", $DUMP2 ] );
    $diff->Base( 1 );   # Return line numbers, not indices
    while(  $diff->Next()  ) {
        next   if  $diff->Same();
        my $sep = '';
        if(  ! $diff->Items(2)  ) {
            printf "%d,%dd%d\n",
               $diff->Get(qw( Min1 Max1 Max2 ));
        } elsif(  ! $diff->Items(1)  ) {
            printf "%da%d,%d\n",
               $diff->Get(qw( Max1 Min2 Max2 ));
        } else {
            $sep = "---\n";
            printf "%d,%dc%d,%d\n",
               $diff->Get(qw( Min1 Max1 Min2 Max2 ));
        }
        print "- $_\n"   for  $diff->Items(1);
        # print $sep;
        print "+ $_\n"   for  $diff->Items(2);
    }
}

############################################################
sub popup_window
{
    my( $self, $id, @args ) = @_;
    
    ok( !$self->{windows}{$id}, "Popup window $id" )
            or die "Pain follows";

    push @{ $self->{new_windows} }, $id;
    $self->{windows}{ $id } = { id => $id };
}


############################################################
sub close_window
{
    my( $self, $id ) = @_;
    if( $self->{parent} ) {
        return $self->{parent}->close_window( $id );
    }

    my $win = delete $self->{windows}{$id};
    ok( $win, "Close window $id" )
            or die "Closing a closed window??!";


    $win = $win->{browser};
    $win->{closed} = 1;
    $win->{NODES} = {};
    $self->Disconnect( $win );
    delete $win->{parent};
}

############################################################
sub open_window
{
    my( $self ) = @_;
    my $win_id = pop @{ $self->{new_windows} };
    my $win2 = ref( $self )->new( parent => $self, name => $win_id );

    my @copy = qw( HOST PORT UA APP SID );
    @{ $win2 }{ @copy } = @{ $self }{ @copy };

    $self->{windows}{ $win_id }{browser} = $win2;

    return $win2;
}

1;
