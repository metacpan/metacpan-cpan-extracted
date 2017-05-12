package Sphinx::XMLpipe2;

use XML::Hash::XS;

our $VERSION = "0.05";

sub new {
    my ($class, %args) = @_;
    return undef unless %args;

    my $self = \%args;
    $self->{'data'} = {};

    $self->{'xmlprocessor'} = XML::Hash::XS->new(
        xml_decl => 0,
        indent   => 4,
        use_attr => 1,
        content  => 'content',
        encoding => 'utf-8',
        utf8     => 0,
    );

    bless $self, $class;
    return $self
}

sub fetch {
    my ($self, ) = @_;

    my $content1 = $self->_fetch_header();
    my $content2 = $self->_fetch_data();
    return qq~<?xml version="1.0" encoding="utf-8"?>\n<sphinx:docset>$content1$content2</sphinx:docset>~;
}

sub add_data {
    my ($self, $data) = @_;
    return undef unless exists $data->{'id'};

    $self->{'data'}->{'sphinx:document'} = []
        unless exists $self->{'data'}->{'sphinx:document'};

    my %params = ();
    my @keys   = ();

    if (ref($self->{'attrs'}) eq 'HASH') {
        @keys = (@{$self->{'fields'}}, keys %{$self->{'attrs'}});
        map { $params{$_} = [$data->{$_}] } @keys;
    }
    elsif (ref($self->{'attrs'}) eq 'ARRAY') {
        my @def = ();
        for my $definition (@{$self->{'attrs'}}) {
            push @def, $definition->{'name'};
        }
        @keys = (@{$self->{'fields'}}, @def);
    }
    map { $params{$_} = [$data->{$_}] if exists $data->{$_}; } @keys;

    push @{$self->{'data'}->{'sphinx:document'}}, {
        id => $data->{'id'},
        %params
    };
    return $self;
}

sub remove_data {
    my ($self, $data) = @_;
    return undef unless exists $data->{'id'};

    $self->{'data'}->{'sphinx:killlist'} = {'id' => []}
        unless exists $self->{'data'}->{'sphinx:killlist'}->{'id'};

    push @{$self->{'data'}->{'sphinx:killlist'}->{'id'}}, [$data->{'id'}];
    return $self;
}


sub _fetch_header {
    my ($self, ) = @_;
    my $header = {
        'sphinx:schema' => {
            'sphinx:field' => [],
            'sphinx:attr'  => [],
        }
    };

    for my $field (@{$self->{'fields'}}) {
        push @{$header->{'sphinx:schema'}->{'sphinx:field'}}, {'name' => $field};
    }

    if (ref($self->{'attrs'}) eq 'HASH') {
        for my $attr (keys %{$self->{'attrs'}}) {
            push @{$header->{'sphinx:schema'}->{'sphinx:attr'}}, {'name' => $attr, 'type' => $self->{'attrs'}->{$attr}};
        }
    }
    elsif (ref($self->{'attrs'}) eq 'ARRAY') {
        for my $definition (@{$self->{'attrs'}}) {
            my $node = {};
            map {$node->{$_} = $definition->{$_} if exists $definition->{$_};} qw(name type bits default);
            push @{$header->{'sphinx:schema'}->{'sphinx:attr'}}, $node;
        }
    }
    @{$header->{'sphinx:schema'}->{'sphinx:attr'}} = sort {$a->{name} cmp $b->{name}} @{$header->{'sphinx:schema'}->{'sphinx:attr'}};

    return _pruning_xml($self->{'xmlprocessor'}->hash2xml($header));
}

sub _fetch_data {
    my ($self, ) = @_;
    return _pruning_xml($self->{'xmlprocessor'}->hash2xml($self->{'data'}));
}

sub _pruning_xml {
    my ($xml) = @_;
    $xml =~ s/^\s*<root>//is;
    $xml =~ s/<\/root>\s*$//is;
    return $xml;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sphinx::XMLpipe2 - Kit for SphinxSearch xmlpipe2 interface

=head1 SYNOPSIS

    use Sphinx::XMLpipe2;

    my $sxml = new Sphinx::XMLpipe2(
        fields => [qw(author title content)],
        attrs  => {published => 'timestamp', section => 'int',}
    );

    or

    my $sxml = new Sphinx::XMLpipe2(
        fields => [qw(author title content)],
        attrs  => [
            {
                name => 'published',
                type => 'timestamp',
            },
            {
                name    => 'section',
                type    => 'int',
                bits    => 8, # optional
                default => 1  # optional
            },
        ]
    );

    $sxml->add_data({
        id         => 314159265,
        author     => 'Oscar Wilde',
        title      => 'Illusion is the first of all pleasures',
        content    => 'Man is least himself when he talks in his own person. Give him a mask, and he will tell you the truth.',
        published  => time(),
        section    => 100500,
    });

    $sxml->remove_data({id => 27182818});

    print $sxml->fetch(), "\n";

=head1 METHODS

=over

=item new %options

Constructor. Takes a hash with options as an argument (required).
The hash contains two keys: fields (arrayref) and attrs (hashref or arrayref if you want to specify additional fields: "bits", "default").
For details about "fields" and "attrs" see SphinxSearch manual.

=back

=over

=item add_data $hashref

Adds a B<single> document to xml. The argument contains key-value pairs with fields/attrs.
You can do multiple calls this method with different params set.
Кeys are not properly validated by package.

=back

=over

=item remove_data $hashref

Request for a B<single> document remove from index (adds killist record to xml).
The argument contains document_id: {id => $document_id}.
You can do multiple calls this method with different params.

=back

=over

=item fetch

Fetch the result (xml)

=back

=head1 SEE ALSO

L<Sphinx reference manual: xmlpipe2 data source|http://sphinxsearch.com/docs/latest/xmlpipe2.html>

Yet another xmlpipe2 package L<Sphinx::XML::Pipe2|http://search.cpan.org/~egor/Sphinx-XML-Pipe2-0.002/lib/Sphinx/XML/Pipe2.pm>

=head1 LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

bbon <bbon@mail.ru>

=cut
