package RDF::Helper::PerlConvenience;
use Moose::Role; 

sub get_perl_type {
    my $self = shift;
    my $wtf = shift;

    my $type = ref( $wtf );
    if ( $type ) {
        if ( $type eq 'ARRAY' or $type eq 'HASH' or $type eq 'SCALAR') {
            return $type;
        }
        else {
            # we were passed an object, yuk.
            # props to barrie slaymaker for the tip here... mine was much fuglier. ;-) 
            if ( UNIVERSAL::isa( $wtf, "HASH" ) ) {
                return 'HASH';
            }
            elsif ( UNIVERSAL::isa( $wtf, "ARRAY" ) ) {
                return 'ARRAY';
            }
            elsif ( UNIVERSAL::isa( $wtf, "SCALAR" ) ) {
                return 'SCALAR';
            }
            else {
                return $type;
            }
        }

    }
    else {
        if ( $wtf =~ /^(http|file|ftp|urn|shttp):/ ) {
            #warn "type for $wtf is resource";
            return 'resource';
        }
        else {
            return 'literal';
        }
    }
}

sub hashlist_from_statement {
    my $self = shift;
    my ($s, $p, $o) = @_;
    my @lookup_subjects = ();
    my @found_data = ();
    
    foreach my $stmnt ( $self->get_statements( $s, $p, $o ) ) {
        my $subj = $stmnt->subject;
        my $key = $subj->is_resource ? $subj->uri->as_string : $subj->blank_identifier;
        push @found_data, [$key, $self->property_hash( $subj )];
        
    }
    
    return @found_data;
}

sub property_hash {
    my $self = shift;
    my $resource = shift;
    my %found_data = ();
    my %seen_keys = ();
    
    $resource ||= $self->new_bnode;
    
    foreach my $t ( $self->get_triples( $resource ) ) {
        
        my $key = $self->resolved2prefixed( $t->[1] ) || $t->[1];
        if ( $seen_keys{$key} ) {
            if ( ref $found_data{$key} eq 'ARRAY' ) {
                push @{$found_data{$key}}, $t->[2];
            }
            else {
                my $was = $found_data{$key};
                $found_data{$key} = [$was, $t->[2]];
            }
        }
        else {
            $found_data{$key} = $t->[2];
        }
        
        $seen_keys{$key} = 1;
        
    }
    
    return \%found_data;
}

sub deep_prophash {
    my $self = shift;
    my $resource = shift;
    my $seen_nodes	= shift || {};
    
    my %found_data = ();
    $seen_nodes->{ $resource }	||= \%found_data;
    my %seen_keys = ();
    
    foreach my $stmnt ( 
$self->get_statements($resource, undef, undef)) {
        
        my $pred = $stmnt->predicate->uri->as_string,
        my $obj  = $stmnt->object;
        my $value;
        
        if ( $obj->is_literal ) {
            $value = $obj->literal_value;
        }
        elsif ( $obj->is_resource ) {
            # if nothing else in the model points to this resource
            # just give the URI as a literal string
            if ( $self->count( $obj, undef, undef) == 0 ) {
                $value = $obj->uri->as_string;
            }
            # otherwise, recurse
            else {
            	if (exists $seen_nodes->{ $obj->uri->as_string }) {
	                $value = $seen_nodes->{ $obj->uri->as_string };
            	} 
            	else {
	                $value = $self->deep_prophash( $obj, $seen_nodes );
	            }
            }

        }
        else {
            if (exists $seen_nodes->{ $obj->blank_identifier }) {
	            $value = $seen_nodes->{ $obj->blank_identifier };
        	} 
        	else {
	            $value = $self->deep_prophash( $obj, $seen_nodes );
	        }
        }

        my $key = $self->resolved2prefixed( $pred ) || $pred;
        
        if ( $seen_keys{$key} ) {
            if ( ref $found_data{$key} eq 'ARRAY' ) {
                push @{$found_data{$key}}, $value;
            }
            else {
                my $was = $found_data{$key};
                $found_data{$key} = [$was, $value];
            }
        }
        else {
            $found_data{$key} = $value;
        }
        
        $seen_keys{$key} = 1;
        
    }
    
    return \%found_data;
}

sub tied_property_hash {
    my $self = shift;
    my $lookup_uri = shift;
    my $options = shift;
    eval "require RDF::Helper::TiedPropertyHash";
    
    return RDF::Helper::TiedPropertyHash->new( Helper => $self, ResourceURI => $lookup_uri, Options => $options);
}

sub arrayref2rdf {
    my $self = shift;
    my $array     = shift;
    my $subject   = shift;
    my $predicate = shift;
    
    $subject ||= $self->new_bnode;
    
    foreach my $value (@{$array}) {
        my $type = $self->get_perl_type( $value );
                
        if ( $type eq 'HASH' ) {
            my $obj = $self->new_bnode;
            $self->assert_resource( $subject, $predicate, $obj );
            $self->hashref2rdf( $value, $obj );
        }
        elsif ( $type eq 'ARRAY' ) {
            die "Lists of lists (arrays of arrays) are not compatible with storage via RDF";
        }
        elsif ( $type eq 'SCALAR' ) {
            $self->assert_resource(
                $subject, $predicate, $$value
            );
        }
        else {
            $self->assert_literal(
                $subject, $predicate, $value
            );
        }
    }
}

sub resourcelist {
    my $self = shift;
    my ( $p, $o ) = @_;
    
    my %seen_resources = ();
    my @retval = ();
    
    foreach my $stmnt ( $self->get_statements( undef, $p, $o ) ) {
        my $s = $stmnt->subject->is_resource ? $stmnt->subject->uri->as_string : $stmnt->subject->blank_identifier;
        next if defined $seen_resources{$s};
        push @retval, $s;
        $seen_resources{$s} = 1;
    }

    return @retval;
}


sub resolved2prefixed {
    my $self = shift;
    my $lookup = shift;
    foreach my $uri ( sort {length $b <=> length $a} (keys( %{$self->_NS} )) ) { 
        #warn "URI $uri LOOKUP $lookup ";
        if ( $lookup =~ /^($uri)(.*)$/ ) {
            my $prefix = $self->_NS->{$uri};
            return $2 if $prefix eq '#default';
            return $prefix . ':' . $2;
        }
    }
    return undef;
}

sub hashref2rdf {
    my $self = shift;
    my $hash = shift;
    my $subject = shift;
    
    $subject ||= $hash->{"rdf:about"};
    $subject ||= $self->new_bnode;
    
    unless ( ref( $subject ) ) {
        $subject = $self->new_resource( $subject );
    }
    
    foreach my $key (keys( %{$hash} )) {
        next if ($key eq 'rdf:about');
        
        my $value = $hash->{$key};
        my $type = $self->get_perl_type( $value );
        my $predicate = $self->prefixed2resolved( $key );
        
        if ( $type eq 'HASH' ) {
            my $obj = $value->{'rdf:about'} || $self->new_bnode;
            $self->assert_resource( $subject, $predicate, $obj );
            $self->hashref2rdf( $value, $obj );
        }
        elsif ( $type eq 'ARRAY' ) {
            $self->arrayref2rdf( $value, $subject, $predicate );
        }
        # XXX Nacho: This part was buggy, but it's been ages since
        # I ran into this problem.
        elsif ( $type eq 'SCALAR' ) {
            $self->assert_resource(
                $subject, $predicate, $$value
            );        
        }
        elsif ( $type eq 'resource' ) {
            $self->assert_resource(
                $subject, $predicate, $value
            );        
        }
        else {
            $self->assert_literal(
                $subject, $predicate, $value
            );
        }
    }
}

sub prefixed2resolved {
    my $self = shift;
    my $lookup = shift;
    
    my ( $name, $prefix ) = reverse ( split /:/, $lookup );
    
    my $uri;
    if ( $prefix ) {
        if ( defined $self->namespaces->{$prefix} ) {
            $uri = $self->namespaces->{$prefix};
        }
        else {
            warn "Unknown prefix: $prefix, in QName $lookup. Falling back to the default predicate URI";
        }
    }
    
    $uri ||= $self->namespaces->{'#default'};
    return $uri . $name;
}

sub qname2resolved {
    my $self = shift;
    my $lookup = shift;
    
    my ( $prefix, $name ) = $lookup =~ /^([^:]+):(.+)$/;
    return $lookup unless ( defined $prefix and exists($self->namespaces->{$prefix}));
    return $self->namespaces->{$prefix} . $name;
}

1;
