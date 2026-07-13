# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package OpenSearch::Client::Core::3_0::Role::Helper::Bulk;
$OpenSearch::Client::Core::3_0::Role::Helper::Bulk::VERSION = '3.007008';

use Moo::Role;
requires 'add_action', 'flush';

use OpenSearch::Client::Util qw(parse_params throw);
use namespace::clean;

has 'os'        => ( is => 'ro', required => 1 );
has 'max_count' => ( is => 'rw', default  => 1_000 );
has 'max_size'  => ( is => 'rw', default  => 1_000_000 );
has 'max_time'  => ( is => 'rw', default  => 0 );

has 'on_success'  => ( is => 'ro', default => 0 );
has 'on_error'    => ( is => 'lazy' );
has 'on_conflict' => ( is => 'ro', default => 0 );
has 'verbose'     => ( is => 'rw' );

has '_buffer' => ( is => 'ro', default => sub { [] } );
has '_buffer_size'  => ( is => 'rw', default => 0 );
has '_buffer_count' => ( is => 'rw', default => 0 );
has '_serializer'   => ( is => 'lazy' );
has '_bulk_args'    => ( is => 'ro' );
has '_last_flush' => ( is => 'rw', default => sub {time} );

has '_query_metadata'     => ( is => 'ro' );
has '_action_metadata'    => ( is => 'ro' );
has '_action_data_types'  => ( is => 'ro' );
has '_update_data_types'  => ( is => 'ro' );

has '_index_in_path'   => ( is => 'ro' );
has '_require_alias_in_path' => ( is => 'ro' );   

our %Actions = (
    'index'  => 1,
    'create' => 1,
    'update' => 1,
    'delete' => 1
);

our %DataTransform = (
    'string'  => sub { return "$_[0]" },
    'number'  => sub { return 0 + $_[0] },
    'REF'     => sub { return $_[0] },
    'boolean' => sub {
        my $val = shift;
        return \0 unless defined $val;
        return $val if(ref($val));
        if( $val =~ /^[0-9]$/ ) {
            return ( $val > 0) ? \1 : \0;
        }
        return ( $val eq 'true' ) ? \1 : \0;
    },
);

## help use of this as a drop in for Search::Elasticsearch
sub es { shift->os; }

#===================================
sub _build__serializer { shift->os->transport->serializer }
#===================================

#===================================
sub _build_on_error {
#===================================
    my $self       = shift;
    my $serializer = $self->_serializer;
    return sub {
        my ( $action, $result, $src ) = @_;
        warn( "Bulk error [$action]: " . $serializer->encode($result) );
    };
}

#===================================
sub BUILDARGS {
#===================================
    my ( $class, $params ) = parse_params(@_);
    
    my $os = $params->{os} || $params->{es};
    delete($params->{$_}) for(qw(os es));
    $params->{os} = $os;
    
    throw( 'Param', 'Missing required param <os>' ) unless($os);
           
    ## NEW
    $params->{_query_metadata}     = $os->api('bulk_helper.metadata_qs')->{params};
    $params->{_action_metadata}    = $os->api('bulk_helper.metadata_action')->{params};
    $params->{_action_data_types}  = $os->api('bulk_helper.action_data_types')->{params};
    $params->{_update_data_types}  = $os->api('bulk_helper.update_data_types')->{params};
    
    my $bulk_spec = $os->api('_core.bulk');
    my %args;
    
    for ( keys %{ $bulk_spec->{qs} }, keys %{ $bulk_spec->{parts} } ) {
        $args{$_} = delete $params->{$_}
            if exists $params->{$_};
    }
    
    $params->{'_index_in_path'} = 1 if(exists($args{'index'}) || exists($args{'_index'}));
    $params->{'_require_alias_in_path'} = 1 if(exists($args{'require_alias'}) || exists($args{'_require_alias'}));
    
    $params->{_bulk_args} = \%args;
    return $params;
}

#===================================
sub index {
#===================================
    shift->add_action( map { ( 'index' => $_ ) } @_ );
}

#===================================
sub create {
#===================================
    shift->add_action( map { ( 'create' => $_ ) } @_ );
}

#===================================
sub delete {
#===================================
    shift->add_action( map { ( 'delete' => $_ ) } @_ );
}

#===================================
sub update {
#===================================
    shift->add_action( map { ( 'update' => $_ ) } @_ );
}

#===================================
sub create_docs {
#===================================
    my $self = shift;
    $self->add_action( map { ( 'create' => { source => $_ } ) } @_ );
}

#===================================
sub delete_ids {
#===================================
    my $self = shift;
    $self->add_action( map { ( 'delete' => { _id => $_ } ) } @_ );
}

#===================================
sub _encode_action {
#===================================
    my $self   = shift;
    my $action = shift || '';
    my $orig   = shift;

    throw( 'Param', "Unrecognised action <$action>" )
        unless $Actions{$action};

    throw( 'Param', "Missing <params> for action <$action>" )
        unless ref($orig) eq 'HASH';

    my %metadata;
    my $params     = {%$orig};
    my $serializer = $self->_serializer;

    my $meta_params = $self->_action_metadata;
        
    for ( keys %$meta_params ) {
        next unless exists $params->{$_};
        $metadata{$meta_params->{$_}} = delete $params->{$_};
    }
        
    unless( $self->_index_in_path ) {
        throw( 'Param', "Missing required param <index>" )
            unless $metadata{'_index'};
    }
    
    my $action_types = $self->_action_data_types;
            
    for ( keys %metadata ) {
        $metadata{$_} = $DataTransform{$action_types->{$_}}($metadata{$_});
    }
    
    my $source;
    
    if( $action eq 'update' ) {
        throw( 'Param', "Unwanted param for action update <pipeline>: " . $serializer->encode($orig) )
            if ( exists($metadata{'pipeline'}) );
        
        my $update_types = $self->_update_data_types;
            
        for ( keys %$update_types ) {
            $source->{$_} = delete $params->{$_}
                if exists $params->{$_};
        }
        for ( keys %$source ) {
            $source->{$_} = $DataTransform{$update_types->{$_}}($source->{$_});
        }
        
        
    } elsif ( $action ne 'delete' ) {
        $source = delete $params->{source}
            || throw( 'Param',
            "Missing <source> for action <$action>: "
                . $serializer->encode($orig) );
    }
    
    throw(    "Unknown params <"
            . ( join ',', sort keys %$params )
            . "> in <$action>: "
            . $serializer->encode($orig) )
        if keys %$params;
    
    my @returns = map { $serializer->encode($_) }
        grep {$_} ( { $action => \%metadata }, $source );
        
}

#===================================
sub _report {
#===================================
    my ( $self, $buffer, $results ) = @_;
    my $on_success  = $self->on_success;
    my $on_error    = $self->on_error;
    my $on_conflict = $self->on_conflict;

    # assume errors if key not present, bwc
    $results->{errors} = 1 unless exists $results->{errors};

    return
        unless $on_success
        || ( $results->{errors} and $on_error || $on_conflict );

    my $serializer = $self->_serializer;

    my $j = 0;

    for my $item ( @{ $results->{items} } ) {
        my ( $action, $result ) = %$item;
        my @args = ($action);
        if ( my $error = $result->{error} ) {
            if ($on_conflict) {
                my ( $is_conflict, $version )
                    = $self->_is_conflict_error($error);
                if ($is_conflict) {
                    $on_conflict->( $action, $result, $j, $version );
                    next;
                }
            }
            $on_error && $on_error->( $action, $result, $j );
        }
        else {
            $on_success && $on_success->( $action, $result, $j );
        }
        $j++;
    }
}

#===================================
sub _is_conflict_error {
#===================================
    my ( $self, $error ) = @_;
    my $version;
    if ( ref($error) eq 'HASH' ) {
        return 1 if $error->{type} eq 'document_already_exists_exception';
        return unless $error->{type} eq 'version_conflict_engine_exception';
        $error->{reason} =~ /version.conflict,.current.(?:version.)?\[(\d+)\]/;
        return ( 1, $1 );
    }
    return unless $error =~ /
            DocumentAlreadyExistsException
           |version.conflict,.current.\[(\d+)\]
           /x;
    return ( 1, $1 );
}

#===================================
sub clear_buffer {
#===================================
    my $self = shift;
    @{ $self->_buffer } = ();
    $self->_buffer_size(0);
    $self->_buffer_count(0);
}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Core::3_0::Role::Helper::Bulk - Provides common functionality to L<OpenSearch::Client::Core::3_0::Helper::Bulk>

=head1 VERSION

version 3.007008

=head1 MANUAL

Documentation index L<OpenSearch::Client::Manual>

=head1 HISTORY

This distribution is derived from L<Search::Elasticsearch> version 7.714.
All subsequent changes are unique to this distribution.

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt> ( current maintainer )

=head1 CREDITS

L<OpenSearch::Client> is based on L<Search::Elasticsearch> version 7.714
by Enrico Zimuel E<lt>enrico.zimuel@elastic.coE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson ( this distribution )

Copyright (C) 2021 by Elasticsearch BV ( original distribution ) 

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004


=cut
