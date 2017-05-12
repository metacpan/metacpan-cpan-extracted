package Tapir::Validator;

use strict;
use warnings;
use Data::Dumper;
use Tapir::Exceptions;
use Tapir::Validator::Length;
use Tapir::Validator::Range;
use Tapir::Validator::Regex;

sub new {
    my ($class, %self) = @_;

    if (! keys %self) {
        %self = (
            audit_types => 1,
            warn_unused_types => 0,
            docs => {
                require => {
                    return => 0,      # @return not required
                    params => 0,  # @param's must match with method arguments
                    methods => 1, # every method must be documented

                    typedefs => 0,
                    exceptions => 0,
                    structs => 0,
                    rest => 0,
                },
            },
        );
    }
    $self{docs}{flags} ||= {
        # List the '@' keys that are flags and will have no value following them
        optional => 1,
        utf8     => 1,
    };
    return bless \%self, $class;
}

=head2 audit_idl_document ($thrift_idl_document)

=cut

sub audit_idl_document {
    my ($self, $document) = @_;

    $self->{custom_types} = {};

    my (%methods_types_used);

    my @audit;
    foreach my $child (@{ $document->children }) {
        foreach my $type ($self->_audit_flatten_types($child)) {
            next unless $type->isa('Thrift::IDL::Type::Custom');
            if ($child->isa('Thrift::IDL::Service')) {
                $methods_types_used{ $type->full_name }++;
            }
            if ($self->{audit_types} && ! $self->{custom_types}{ $type->full_name }) {
                push @audit, "$child contains reference to custom type ".$type->full_name." which hasn't yet been defined";
            }
        }

        my $audit_error = $self->_audit_parse_structured_comment($child);

        if ($child->isa('Thrift::IDL::TypeDef')
            || $child->isa('Thrift::IDL::Struct')
            || $child->isa('Thrift::IDL::Enum')
            || $child->isa('Thrift::IDL::Senum')
        ) {
            push @audit, $audit_error if $audit_error && $self->{docs}{require}{typedefs};
            $self->{custom_types}{ $child->full_name } = $child;
        }

        if ($self->{docs}{require}{exceptions} && $child->isa('Thrift::IDL::Exception')) {
            push @audit, $audit_error if $audit_error;
        }
        elsif ($self->{docs}{require}{structs} && $child->isa('Thrift::IDL::Struct') && ! $child->isa('Thrift::IDL::Exception')) {
            push @audit, $audit_error if $audit_error;
        }
        elsif ($child->isa('Thrift::IDL::Service')) {
            my $service = $child;

            # Ensure that each child method has a comment that defines it's documentation,
            # and parse this comment into a data structure and store in the $method object.
            foreach my $method (@{ $child->methods }) {
                my %ids;
                foreach my $field (@{ $method->arguments }) {
                    # Check for 'optional' flag
                    if ($field->optional) {
                        push @audit, "Service $child method $method field '".$field->name."' has 'optional' flag: not valid for an argument field; rewrite as '\@optional' in comment";
                    }

                    # Check for non-duplication of field ids
                    if (! defined $ids{$field->id}) {
                        $ids{$field->id} = $field;;
                    }
                    else {
                        push @audit, "Service $child method $method field '".$field->name."' id ".$field->id." was already assigned to field '".$ids{$field->id}->name."'";
                    }
                }

                if (! $method->comments) {
                    if ($self->{docs}{require}{methods}) {
                        push @audit, "Service $child method $method has no comment documentation";
                    }
                    next;
                }

                my $failed = $self->_audit_parse_structured_comment($method);
                if ($failed) {
                    push @audit, $failed;
                    next;
                }
            }
        }
    }

    if ($self->{warn_unused_types} && (my @unused = sort grep { ! $methods_types_used{$_} } keys %{ $self->{custom_types} })) {
        print STDERR "AUDIT WARN: The following types were custom defined but weren't used in any method I saw:\n";
        print STDERR "  " . join(', ', @unused) . "\n";
    }

    return @audit;
}

sub _audit_flatten_types {
    my ($self, $node) = @_;
    if (! defined $node) {
        print STDERR "_audit_flatten_types() called on undef\n";
        return ();
    }
    # Resolve named custom types to their original typedef objects
    if ($node->isa('Thrift::IDL::Type::Custom') && $self->{custom_types} && $self->{custom_types}{ $node->full_name }) {
        $node = $self->{custom_types}{ $node->full_name };
    }
    my @types = map { $node->$_ } grep { $node->can($_) } qw(type val_type key_type returns);
    my @children = map { ref $_ ? @$_ : $_ } map { $node->$_ } grep { $node->can($_) && defined $node->$_ } qw(arguments throws children fields);
    return @types, map { $self->_audit_flatten_types($_) } @types, @children;
}

sub _audit_parse_structured_comment {
    my ($self, $object) = @_;

    my @comments = @{ $object->comments };

    if (! @comments) {
        return "$object has no comments";
    }

    my $comment = join "\n", map { $_->escaped_value_with_whitespace } @comments;

    # If it's a multi-line comment, remove the common whitespace in front of each line
    if ($comment =~ m/\n/) {
        $comment =~ s/^[ ]*\n?//;
        $comment =~ s/\n?[ ]*$//;

        my ($common_whitespace) = $comment =~ m/^(\s+)/;
        my @lines = split /\n/, $comment;
        my @match = grep { /^($common_whitespace|$)/ } @lines;
        if (int @lines == int @match) {
            $comment = join "\n", map { s/^$common_whitespace//; $_ } @lines;
        }
    }
    else {
        $comment =~ s/^\s+//;
        $comment =~ s/\s+$//;
    }

    my %doc;
    $object->{doc} = \%doc;
    {
        my @parts = split /(\@\w+)/x, $comment;
        while (defined (my $part = shift @parts)) {
            next if ! length $part;
            my ($javadoc_key) = $part =~ m{^\@(\w+)$};

            if (! $javadoc_key) {
                $part =~ s/\s+$//;
                if (! defined $doc{description}) {
                    $doc{description} = $part;
                }
                else {
                    $doc{description} .= "\n" . $part;
                }
                next;
            }

            if ($self->{docs}{flags}{$javadoc_key}) {
                $doc{$javadoc_key} = 1;
                next;
            }

            my $value = shift @parts;
            next unless defined $value && length $value;

            $value =~ s/^\s+//;
            if ($javadoc_key eq 'param') {
                my ($param, $description) = $value =~ m{^(\w+) \s* (.*)$}x;
                $doc{param}{$param} = $description || '';
            }
            elsif ($javadoc_key eq 'validate') {
                my ($param, $args) = $value =~ m{^(\w+) \s* (.*)$}x;
                my $class = 'Tapir::Validator::' . ucfirst($param);
                push @{ $doc{validators} }, $class->new_from_string($args);
            }
            elsif ($javadoc_key eq 'rest') {
                my ($method, $route) = split /\s+/, $value, 2;
                if ($method !~ /^(any|get|put|post|head|delete)$/i) {
                    return "\@rest method '$method' is invalid";
                }
                $doc{rest} = { method => lc($method), route => $route };
            }
            else {
                push @{ $doc{$javadoc_key} }, $value;
            }
        }
    }

    # Allow fields/arguments to have structured comments and to describe themselves
    {
        # Only use arguments or fields, not both (some objects allow both)
        my @keys = grep { $object->can($_) } qw(arguments fields);
        if (@keys) {
            my $key = $keys[0];
            my @fields = @{ $object->$key };
            foreach my $field (@fields) {
                $self->_audit_parse_structured_comment($field) if int @{ $field->comments };
                if ($field->{doc} && (my $description = $field->{doc}{description})) {
                    if (defined $doc{param}{$field->name}) {
                        $doc{param}{$field->name} .= '; ' . $description;
                    }
                    else {
                        $doc{param}{$field->name} = $description;
                    }
                }
            }
        }
    }

    # Check for completeness of the documentation
    if ($object->isa('Thrift::IDL::Method')) {
        if ($self->{docs}{require}{return}) {
            # Non-void return value requires description
            my $return = $object->returns;
            unless ($return->isa('Thrift::IDL::Type::Base') && $return->name eq 'void') {
                if (! $doc{return}) {
                    return "$object has a non-void return value but no docs for it";
                }
            }
        }

        if ($self->{docs}{require}{params}) {
            # Check the params (make a copy as I'll be destructive)
            my %params = %{ $doc{param} };
            my @fields = map { @{ $object->$_ } } grep { $object->can($_) } qw(arguments fields);
            foreach my $field (@fields) {
                if (defined $params{$field->name}) {
                    delete $params{$field->name};
                }
                else {
                    return "$object doesn't document argument $field";
                }
            }
            foreach my $remaining (keys %params) {
                return "$object documented param $remaining which doesn't exist in the object fields";
            }
        }

        if ($self->{docs}{require}{rest} && ! $doc{rest}) {
            return "$object doesn't provide a \@rest route";
        }
    }

    return;
}

sub validate_parser_message {
    my ($self, $message, $opt) = @_;
    $opt ||= {};

    my $idl = $message->method->idl_doc; 
    my $method_doc = $message->{method}->idl->{doc};

    foreach my $spec (@{ $message->method->idl->arguments }) {
        my $field = $message->arguments->id($spec->id);
        $self->_validate_parser_message_argument($idl, $opt, $spec, $field, $message);
    }
}

sub validate_parser_reply {
    my ($self, $message, $opt) = @_;
    $opt ||= {};

    my $idl = $message->method->idl_doc; 
    my $return = $message->arguments->field_named('return_value');

    if ($return->value->isa('Thrift::Parser::FieldSet')) {
        foreach my $spec (@{ $return->idl->fields }) {
            my $field = $return->value->id($spec->id);
            $self->_validate_parser_message_argument($idl, $opt, $spec, $field, $message);
        }
    }
    else {
        die "FIXME";
    }
}

sub doc_from_idl_object {
    my ($self, $idl, $spec) = @_;

    my @docs;
    push @docs, $spec->{doc} if defined $spec->{doc};

    if ($spec->type->isa('Thrift::IDL::Type::Custom')) {
        my $ref_object = $idl->object_full_named($spec->type->full_name);
        push @docs, $ref_object->{doc} if defined $ref_object->{doc};
    }

    # Create an aggregate doc from the list of @docs
    my $doc = {};
    foreach my $sub (@docs) {
        # Make a copy of it, as I'll be deleting keys from it
        my %sub = %$sub;

        # Overrides
        foreach my $key (qw(description), keys %{ $self->{docs}{flags} }) {
            next unless defined $sub{$key};
            $doc->{$key} = delete $sub{$key};
        }

        # Hash-based
        foreach my $key (qw(param)) {
            next unless defined $sub{$key};
            $doc->{$key}{$_} = $sub{$key}{$_} foreach keys %{ $sub{$key} };
            delete $sub{$key};
        }

        # Validate
        if ($sub{validators}) {
            push @{ $doc->{validators} }, @{ delete $sub{validators} };
        }

        # All else is array
        foreach my $key (keys %sub) {
            push @{ $doc->{$key} }, @{ $sub{$key} };
        }
    }

    return $doc;
}

sub _validate_parser_message_argument {
    my ($self, $idl, $opt, $spec, $field, $message) = @_;

    my $doc = $self->doc_from_idl_object($idl, $spec);

    if (defined $field && $spec->type->isa('Thrift::IDL::Type::Custom')) {
        my $ref_object = $idl->object_full_named($spec->type->full_name);
        if ($ref_object && $ref_object->isa('Thrift::IDL::Struct')) {
            my $field_set = $field->value;
            foreach my $child_spec (@{ $ref_object->fields }) {
                my $child_field = $field_set->id($child_spec->id);
                if (! defined $child_field) {
                    next;
                }
                #print "Child spec/field: " . Dumper({ field_set => $field_set, child_field => $child_field, child_spec => $child_spec });
                $self->_validate_parser_message_argument($idl, $opt, $child_spec, $child_field, $message);
            }
        }
    }

    if ($doc->{default}) {
        # TODO
    }

    if (! defined $field && ! $doc->{optional} && ! $spec->optional) {
        Tapir::InvalidArgument->throw(
            error => "Missing non-optional field ".$spec->name,
            key => $spec->name,
        );
    }

    return unless defined $field;

    # Store a reference to the Thrift::IDL::Type spec in the Thrift::Parser::Type object
    # This will give the message arguments direct access to the docs on the spec
    $field->{spec} = $spec;

    my $desc = (defined $field->value ? '"' . $field->value . '"' : 'undef') . ' (' . $spec->name . ')';

    if (defined $field->value
        && $field->isa('Thrift::Parser::Type::string')
        && ! $doc->{utf8}
        && $field->value =~ m{[^\x00-\x7f]}) {
        Tapir::InvalidArgument->throw(
            error => "String $desc contains > 127 bytes but isn't permitted to have utf8 data",
            key => $field->name, value => $field->value
        );
    }

    return unless $doc->{validators};
    foreach my $validator (@{ $doc->{validators} }) {
        $validator->validate_field($field, $desc);
    }
}

1;
