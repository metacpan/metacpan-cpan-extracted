package Sphinx::XML::Pipe2;

# ABSTRACT: generates xml to feed xmlpipe2 of Sphinx Search


use strict;
use warnings;
use XML::LibXML;

sub new {
    bless {
        schema => { field => [], attr  => [] },
        data => []
    }, shift;
}

sub field { shift->declare('field', @_) }

sub attr { shift->declare('attr', @_) }

sub declare { push @{shift->{schema}->{ do { shift } } }, [@_] }

sub add { push @{shift->{data}}, [@_] }

sub xml { shift->process->toString(2) }

sub process {
    my ($self) = @_;
    my $dom = XML::LibXML::Document->new();
    $dom->addChild(do {
        my $docset = $dom->createElement('sphinx:docset');
        $docset->addChild(do {
            my $schema = $dom->createElement('sphinx:schema');
            map {
                $schema->addChild(do {
                    my $node = $dom->createElement('sphinx:field');
                    $node->setAttribute(name => $_->[0]);
                    $node->setAttribute(attr => $_->[1]) if defined $_->[1];
                    $node;
                });
            } @{$self->{schema}->{field}};
            map {
                $schema->addChild(do {
                    my $node = $dom->createElement('sphinx:attr');
                    $node->setAttribute(name => $_->[0]);
                    $node->setAttribute(type => $_->[1]) if defined $_->[1];
                    $node->setAttribute(bits => $_->[2]) if defined $_->[2];
                    $node->setAttribute(default => $_->[3]) if defined $_->[3];
                    $node;
                });
            } @{$self->{schema}->{attr}};
            $schema;
        });
        map {  # write docs with sub elements (id[, @attr[, @field]])
            my $i = $_;
            my $n = 1;
            my $doc = $dom->createElement('sphinx:document');
            $doc->setAttribute('id', $i->[0]);
            map {
                my $node = $dom->createElement($_);
                $node->appendText($i->[$n++]);
                $doc->addChild($node);
            } map($_->[0], @{$self->{schema}->{attr}}, @{$self->{schema}->{field}});
            $docset->addChild($doc);
        } @{$self->{data}};
        $docset;
    });
    $dom;
}

1;

__END__
=pod

=head1 NAME

Sphinx::XML::Pipe2 - generates xml to feed xmlpipe2 of Sphinx Search

=head1 VERSION

version 0.002

=head1 SYNOPSIS

Example script which creates XML data for Sphinx Search L<xmlpipe2 data source|http://sphinxsearch.com/docs/current.html#xmlpipe2> of some documents in directories specified as script arguments 

     use v5.14;
     use Sphinx::XML::Pipe2;
     use File::Find;

     binmode STDIN, ":encoding(utf8)";  
     binmode STDOUT, ":encoding(utf8)"

     my $p = Sphinx::XML::Pipe2->new;
      
     $p->attr('size', 'int');
     $p->attr('type', 'str2ordinal');
     $p->field('content');
     $p->field('path');
    
     my $i = 0;
     find( sub {
        my $file = $_;
        if (-f -r $file && (my $size = -s $file) && $file =~ /\.(html?|txt|rtf)?$/i) {
            $p->add( 
                $i, # document id
                $size, # attributes in declaration order, i.e. 'size'
                lc($1), # 'type'
                do { local( @ARGV, $/ ) = $name; <> }, # then fields in declaration order, i.e. 'content' 
                $File::Find::name # 'path'
            );
        }
    }, @ARGV);
    
    print $p->xml;

=head1 METHODS

=head2 attr($name, $type, $bits, $default)

Declare document attribute. $name and $type is mandatory.

=head2 field($name, $attr)

Declare document field. $name is mandatory.

=head2 add($id, @attr, @field)

Add document. $id - must be integer, @attr and @field must be be in declaration order.

=head2 xml

Returns XML data suitable for xmlpipe2 data source.

=head2 process

Returns XML::LibXML::Document

=head1 NOTICE

Experimental state

=head1 SEE ALSO

L<Sphinx Search xmlpipe2 data source|http://sphinxsearch.com/docs/current.html#xmlpipe2>

=head1 AUTHOR

Yegor Korablev <egor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yegor Korablev.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

