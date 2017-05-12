package Plucene::SearchEngine::Index::Base;
use Plucene::Document;
use Plucene::Document::DateSerializer;
use Plucene::Document::Field;
use Time::Piece;
use UNIVERSAL::moniker;
use strict;

=head1 NAME

Plucene::SearchEngine::Index::Base - The definitely indexer base class

=head1 DESCRIPTION

This module is the base class from which both frontend and backend
indiexing modules should inherit. It makes it easier for modules to
create C<Plucene::Document> objects through the intermediary of a nested
hash.

=head1 METHODS

=head2 register_handler

    __PACKAGE__->register_handler($ext, $mime_type, $ext2, ...);

This registers the module to handle each given extension or MIME type.
C<Base> works out whether a parameter is a file extension or a MIME
type.

=head2 handler_for

    $self->handler_for($filename, $mime_type)

This finds the relevant handler which has been registered for the givern
mime type or file name extension.

=cut

use constant DEFAULT_HANDLER => "Plucene::SearchEngine::Index::Text";
{
    my %mime_handlers;
    my %extension_handlers;
    sub register_handler {
        my ($package, @specs) = @_;
        for my $spec (@specs) { 
            if ($spec =~ m{/}) {
                $mime_handlers{$spec} = $package;
            } else {
                $extension_handlers{$spec} = $package;
            }
        }
    }
    sub handler_for {
        my ($self, $filename, $mime) = @_;
        if (exists $mime_handlers{$mime}) { return $mime_handlers{$mime} }
        for my $spec (keys %extension_handlers) {
            if ($filename =~ /$spec$/) { return $extension_handlers{$spec} }
        }
        return DEFAULT_HANDLER;
    }
}

=head2 new

This creates a new backend object, which knows about the C<handler>,
C<type> and C<indexed> date for the data.

=cut

sub new { 
    my ($handler) = @_;
    my $self = bless {}, $handler;
    $self->add_data("handler", "Keyword", $handler);
    $self->add_data("type", "Keyword", $handler->moniker);
    $self->add_data("indexed", "Date", Time::Piece->new());
    $self;
}

=head2 add_data

    $self->add_data($field, $type, $data);

This adds data to a backend object. A backend object represents a
C<Plucene::Document>, a hash which will later be turned into a
C<Plucene::Document> object.

The C<$field> element should be the field name that's stored in Plucene.
The C<$type> should be one of the methods that
C<Plucene::Document::Field> can cope with - Keyword, Text, UnIndexed,
UnStored - or C<Date>, which takes a C<Time::Piece> object as its
C<$data>.

=cut

sub add_data {
    my ($self, $field, $type, $data) = @_;
    $self->{$field}{type} = $type;
    push @{$self->{$field}{data}}, $data;
}

=head2 document

This turns the backend's hash into a C<Plucene::Document>.

=cut


sub document {
    my $self = shift;
    my $doc = Plucene::Document->new;
    my $text;
    for my $field_name (keys %{$self}) {
        next if $field_name eq "text";
        my $field = $self->{$field_name};
        my $type = $field->{type};
        warn "No type for field $field_name!" unless $type;
        if ($field->{type} eq "Date") {
            $type = "Keyword";
            for (@{$field->{data}}) { $_ = freeze_date($_) }
        }
        for (@{$field->{data}}) {
            $text .= " ". $_;
            $doc->add(Plucene::Document::Field->$type( $field_name => $_));
        }
    }
    $text .= " ". join " ", @{$self->{text}{data}||[]};
    $doc->add(Plucene::Document::Field->UnStored(text => $text));
    return $doc;
}

1;
