package Protocol::XMLRPC::Method;

use strict;
use warnings;

use Protocol::XMLRPC::Value::Double;
use Protocol::XMLRPC::Value::String;
use Protocol::XMLRPC::Value::Integer;
use Protocol::XMLRPC::Value::Array;
use Protocol::XMLRPC::Value::Boolean;
use Protocol::XMLRPC::Value::DateTime;
use Protocol::XMLRPC::Value::Struct;
use Protocol::XMLRPC::Value::Base64;

use XML::LibXML;

use overload '""' => sub { shift->to_string }, fallback => 1;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub parse {
    my $class = shift;
    my ($xml) = @_;

    my $parser = XML::LibXML->new;
    my $doc;
    eval {
        $doc = $parser->parse_string($xml);
        1;
    } or do {
        die "Can't parse XML: $@";
    };

    return $class->_parse_document($doc);
}

sub _parse_document {
}

sub _parse_value {
    my $self = shift;
    my ($value) = @_;

    my @types = $value->childNodes;

    if (@types == 1 && !$types[0]->isa('XML::LibXML::Element')) {
        return Protocol::XMLRPC::Value::String->new($types[0]->textContent);
    }
    elsif (@types == 0) {
        return Protocol::XMLRPC::Value::String->new('');
    }

    my ($type) = grep { $_->isa('XML::LibXML::Element') } @types;

    if ($type->getName eq 'string') {
        return Protocol::XMLRPC::Value::String->new($type->textContent);
    }
    elsif ($type->getName eq 'i4' || $type->getName eq 'int') {
        return Protocol::XMLRPC::Value::Integer->parse($type->textContent,
            alias => $type->getName);
    }
    elsif ($type->getName eq 'double') {
        return Protocol::XMLRPC::Value::Double->parse($type->textContent);
    }
    elsif ($type->getName eq 'boolean') {
        return Protocol::XMLRPC::Value::Boolean->parse($type->textContent);
    }
    elsif ($type->getName eq 'dateTime.iso8601') {
        return Protocol::XMLRPC::Value::DateTime->parse($type->textContent);
    }
    elsif ($type->getName eq 'base64') {
        return Protocol::XMLRPC::Value::Base64->parse($type->textContent);
    }
    elsif ($type->getName eq 'struct') {
        my $struct = Protocol::XMLRPC::Value::Struct->new;

        my @members = $type->findnodes('member')->get_nodelist;
        foreach my $member (@members) {
            my ($name)  = $member->getElementsByTagName('name');
            my ($value) = $member->getElementsByTagName('value');

            if (defined(my $param = $self->_parse_value($value))) {
                $struct->add_member($name->textContent => $param);
            }
            else {
                last;
            }
        }

        return $struct;
    }
    elsif ($type->getName eq 'array') {
        my $array = Protocol::XMLRPC::Value::Array->new;

        my ($data) = $type->getElementsByTagName('data');

        my (@values) = grep {$_->isa('XML::LibXML::Element')} $data->childNodes;
        foreach my $value (@values) {
            if (defined(my $param = $self->_parse_value($value))) {
                $array->add_data($param);
            }
            else {
                last;
            }
        }

        return $array;
    }

    die "Unknown type '" . $type->getName . "'";
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Method - methodCall and methodResponse base class

=head1 SYNOPSIS

    package Protocol::XMLRPC::MethodCall;

    use warnings;
    use strict;

    use base 'Protocol::XMLRPC::Method';

    ...

    1;

=head1 DESCRIPTION

A base class for L<Protocol::XMLRPC::MethodCall> and
L<Protocol::XMLRPC::MethodCall>. Used internally.

=head1 METHODS

=head2 C<parse>

Parses xml.
