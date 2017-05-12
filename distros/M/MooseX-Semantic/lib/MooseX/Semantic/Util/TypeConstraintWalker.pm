package MooseX::Semantic::Util::TypeConstraintWalker;
use Moose::Role;
use Try::Tiny;
use Data::Dumper;
use MooseX::Semantic::Types qw(UriStr);
use Data::Printer;
use feature qw(switch);
use Log::Log4perl;
my $logger = Log::Log4perl->get_logger(__PACKAGE__);

#TODO proper support for MooseX::Types!!!

sub _find_parent_type {
    my ($self, $attr_or_type_constraint, $needle, %opts) = @_;
    return unless $attr_or_type_constraint;

    $opts{match_all} //= 1;
    $opts{match_any} //= 1;

    my ($attr, $attr_name, $type_constraint);
    my $type_ref = ref $attr_or_type_constraint;

    if (ref $needle && ref ($needle) eq 'ARRAY') {
        my $needles_searched_size = scalar @{$needle};
        my @needles_matched = grep {$self->_find_parent_type($attr_or_type_constraint, $_, %opts)} @{$needle};
        if ($opts{match_any}) {
            return @needles_matched;
        }
        if ($opts{match_all}){
            return $needles_searched_size == scalar @needles_matched;
        }
        # TODO
        # return @needles_matched;
    }

    if ( ! ref $attr_or_type_constraint ) {
        return unless $self->meta->has_attribute($attr_or_type_constraint);
        $type_constraint = $self->meta->get_attribute($attr_or_type_constraint)->type_constraint;
    }
    elsif ($type_ref =~ m'^Moose::Meta::(?:Attribute|Class)') {
        $type_constraint = $attr_or_type_constraint->type_constraint;
    }
    # elsif ($type_ref =~ m'^(?:Moose::Meta::TypeConstraint::Class)') {
    #     $type_constraint = $attr_or_type_constraint;
    # }
    elsif ($type_ref =~ m'^(?:Moose::Meta::TypeConstraint|MooseX::Types::TypeDecorator)') {
        $type_constraint = $attr_or_type_constraint;
    }
    else {
        # warn ref $attr_or_type_constraint;
        # warn $attr_or_type_constraint;
        return;
    }
    if ($opts{look_vertically}) {
        if ($type_constraint->can('type_parameter') && $type_constraint->type_parameter) {
            $type_constraint = $type_constraint->type_parameter;
        }
    }
    return $self->_find_parent_type_for_type_constraint( $type_constraint, $needle, %opts );
}

sub _find_parent_type_for_type_constraint {
    my ($self, $type_constraint, $needle, %opts) = @_;
    # warn Dumper $type_constraint->name;
    # warn Dumper $needle;
    $opts{max_depth} = 9999 unless defined $opts{max_depth};
    $opts{max_width} = 9999 unless defined $opts{max_width};
    $opts{current_depth} = 0 unless $opts{current_depth};
    $opts{current_width} = 0 unless $opts{current_width};
    # warn Dumper [keys(%$type_constraint)];
    # warn Dumper $type_constraint->name;
    # warn Dumper \%opts;
    # warn Dumper $opts{current_depth};

    if (   ( $opts{current_depth} > $opts{max_depth} )
        || ( $opts{current_width} > $opts{max_width} ) )
    {
        return;
    }
    $opts{current_depth}++;

    my $type_name = $type_constraint->name;
    if ($opts{look_vertically} && $type_constraint->can('type_parameter') && $type_constraint->type_parameter) {
        $opts{current_width}++;
        return $self->_find_parent_type_for_type_constraint( $type_constraint->type_parameter, $needle, %opts );
    }
    if (ref $needle && ref ($needle) eq 'CODE'){
        if ($type_name->can('does') && $needle->( $type_constraint->name )) {
            return $type_constraint->name 
        }
    }
    elsif ($type_constraint->name eq $needle) {
        return $needle;
    }
    if ( $type_constraint->can('class') && ! blessed $type_constraint->class && $type_constraint->class eq $needle ) {
        return $type_constraint->class;
    }
    if ( $type_constraint->{'__type_constraint'} 
    ) {
        # warn Dumper $type_constraint->{'__type_constraint'};
        # if( $type_constraint->{'__type_constraint'}->can('class')
        #     && $type_constraint->{'__type_constraint'}->class eq $needle 
        # ) {
            # return $needle;
        # warn Dumper [ keys(%{$type_constraint}->{'__type_constraint'}) ];
        # warn Dumper {%{$type_constraint->{'__type_constraint'}}};
        return $self->_find_parent_type_for_type_constraint($type_constraint->{'__type_constraint'}, $needle, %opts);
        # }
        # else {
        #     return
        # }
    }
    if ($type_constraint->has_parent) {
        # warn Dumper {keys(%{$type_constraint})};
        return $self->_find_parent_type_for_type_constraint($type_constraint->parent, $needle, %opts );
    }
    else {
        return;
    }
}

sub _walk_attributes{
    my ($self, $cb_opts, $cb_selector) = @_;
    my $cb;
    for (qw(before literal resource literal_in_array resource_in_array model)) { 
        $cb->{$_} = defined $cb_opts->{$_} ? $cb_opts->{$_} : sub {}
    }
    ATTR:
    for my $attr ($self->meta->get_all_attributes) {
        my $attr_name = $attr->name;
        # my $attr = $self->meta->get_attribute($attr_name);
        next unless ($attr->does('MooseX::Semantic::Meta::Attribute::Trait'));
        my $attr_type = $attr->type_constraint;
        if (ref $attr_type eq 'MooseX::Types::TypeDecorator') {
            # warn Dumper $attr_name;
            # warn Dumper ref $attr_type;
            $attr_type = $attr_type->__type_constraint->parent;
#            p $attr_type;
        }
        # else {
        #     # p $attr_name;
        #     # p $attr_type;
        # }

        my $stash = {};
        $stash->{uris}  = [$attr->uri] if $attr->has_uri;
        $stash->{attr_val} = $self->$attr_name if blessed $self;

        if ($cb_opts->{'schema'}){
            $cb_opts->{'schema'}->( $attr );
            next ATTR;
        }

        # XXX
        # skip this attribute if the 'before' callback returns a true value
        next if $cb->{before}->($attr, $stash, @_);
        my $callback_name;
        if ( $attr->has_rdf_formatter
            || ! $attr_type
            || $attr_type eq 'Str'
            || $self->_find_parent_type( $attr_type, 'Num' )
            || $self->_find_parent_type( $attr_type, 'Bool' ))
        {
            $callback_name = 'literal';
        }
        elsif ($self->_find_parent_type($attr_type, 'Object')
            # || $self->_find_parent_type($attr_type, 'ClassName')
            )
        {
            $callback_name = 'resource';
            # warn Dumper keys(%{ $attr->type_constraint->{__type_constraint} });
            if ( 
                # $self->$attr_name->isa('RDF::Trine::Model')
                $self->_find_parent_type( $attr, 'RDF::Trine::Model' 
                # || $attr->uri->as_string eq '<http://moosex-semantic.org/onto#rdf_graph>'
                )
                # || $self->uri eq 'http:
            ) {
                # warn "It's amodel";
                $callback_name = 'model';
            }
        }
        elsif ($self->_find_parent_type($attr_type, 'Str')) {
            $callback_name = 'literal';
        }
        elsif ($self->_find_parent_type($attr->type_constraint, 'ArrayRef')) {
            if ( ! $attr_type->can('type_parameter')) {
                # warn Dumper ref $attr_type;
                # p $attr_type;
                $callback_name = 'literal_in_array';
            }
            elsif ( $attr_type->type_parameter =~ 'Literal' ) {
                # warn Dumper ref $attr_type;
                # p $attr_type;
                $callback_name = 'literal_in_array';
            }
            elsif ( $self->_find_parent_type( $attr_type->type_parameter, 'Object' ) 
            or      $self->_find_parent_type( $attr_type->type_parameter, 'ClassName' ) ) 
            {
                $callback_name = 'resource_in_array';
            }
            elsif ( $attr_type->type_parameter eq 'Str'
            or      $self->_find_parent_type( $attr_type->type_parameter, 'Num' )
            or      $self->_find_parent_type( $attr_type->type_parameter, 'Bool' ))
            {
                $callback_name = 'literal_in_array';
            }
            else {
                warn "Can't handle this ArrayRef: " . $attr_type;
                warn Dumper ref $attr_type;
            }
        }
        else {
            # warn Dumper $attr_type->has_parent;
            # warn Dumper $attr_type->parent;
            warn Dumper ref $attr_type;
            # warn Dumper $self->_find_parent_type($attr_type, 'Object');
            warn "Can't handle this attribute: $attr_name";
            next;
        }
        # warn Dumper $attr->uri;
        # warn Dumper $callback_name;
        $cb->{$callback_name}->($attr, $stash, @_);
    }
}

sub _get_hash_keys_for_attr {
    my $self = shift;
    my ($attr, %opts) = @_;
    $opts{hash_key} //= 'Moose';
    my @keys;
    if ($opts{hash_key} =~ 'RDF') {
        push (@keys, $attr->uri) if $attr->has_uri;
        push (@keys, @{$attr->uri_writer}) if $attr->has_uri_writer;
    }
    if ($opts{hash_key} =~ 'Moose') {
        push @keys, $attr->name;
    }
    unless (scalar @keys) {
        die "Bad value for hash_key $opts{hash_key}";
    }
    return [ map { UriStr->coerce($_) } @keys];
}

sub _attr_to_hash {
    my $self = shift;
    my ($hash, $attr, $val, %opts ) = @_;
    my $keys_aref = $self->_get_hash_keys_for_attr($attr, %opts) ;
    # warn Dumper $keys_aref;
    my @keys = @{ $keys_aref };
    for (@keys) {
        $hash->{$_} = $val;
    }
    return 1;
}

1;
