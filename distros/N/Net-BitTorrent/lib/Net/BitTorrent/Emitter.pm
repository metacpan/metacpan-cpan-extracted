use v5.40;
use feature 'class', 'try';
no warnings 'experimental::class', 'experimental::try';
class Net::BitTorrent::Emitter v2.1.0 {
    field %on;                            # event_name => [ sub { ... }, ... ]
    field $parent_emitter : reader;
    use constant MAX_LISTENERS => 100;    # Max callbacks per event

    method on ( $event, $cb ) {
        if ( exists $on{$event} && $on{$event}->@* >= MAX_LISTENERS ) {
            warn "Too many listeners for event '$event', ignoring";
            return $self;
        }
        push $on{$event}->@*, $cb;
        return $self;
    }

    method off ( $event, $cb = undef ) {
        if ($cb) {
            $on{$event} = [ grep { $_ ne $cb } $on{$event}->@* ] if exists $on{$event};
        }
        else {
            delete $on{$event};
        }
        return $self;
    }

    method set_parent_emitter ($parent) {
        if ( defined $parent ) {
            my $current = $parent;
            for my $depth ( 0 .. 10 ) {
                last unless defined $current;
                if ( $current eq $self ) {
                    warn 'Cycle detected in parent emitter chain, ignoring';
                    return;
                }
                $current = eval { $current->parent_emitter() };
            }
        }
        $parent_emitter = $parent;
        builtin::weaken($parent_emitter) if defined $parent_emitter;
    }

    method _emit ( $event, @args ) {
        state $depth = 0;
        $depth++;
        if ( $depth > 100 ) {
            $depth--;
            warn "Emitter recursion depth exceeded for event '$event', stopping";
            return;
        }
        if ( $event eq 'log' ) {
            my %extra;
            if ( @args % 2 != 0 ) {
                my $msg = shift @args;
                %extra = ( log => $msg, @args );
            }
            else {
                %extra = @args;
            }
            if ( ( $extra{level} // '' ) eq 'fatal' ) {
                $depth--;
                die $extra{log};
            }
            @args = %extra;
        }
        if ( exists $on{$event} ) {
            for my $cb ( $on{$event}->@* ) {
                try {
                    $cb->( $self, @args );
                }
                catch ($e) {
                    warn "Callback for $event failed: $e";
                }
            }
        }
        if ( defined $parent_emitter ) {
            $parent_emitter->_emit( $event, @args );
        }
        $depth--;
    }

    method _emit_log ( $level, $message, @extra ) {
        $message =~ s/\n+$//;
        $self->_emit( log => $message, level => $level, @extra );
    }
};
1;
