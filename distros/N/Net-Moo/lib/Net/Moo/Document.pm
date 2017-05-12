use strict;

package Net::Moo::Document;
use base qw (XML::Writer);

$Net::Moo::Document::VERSION = '0.11';

=head1 NAME 

Net::Moo::Document - object methods to generate XML documents for the Moo API.

=head1 SYNOPSIS

 There is no SYNOPSIS. Consult Net::Moo for details.

=head1 DESCRIPTION

Object methods to generate XML documents for the Moo API.

=cut

sub new {
        my $pkg = shift;
        my $fh = shift;

        my %args = (
                    'OUTPUT' => $fh,
                    'DATA_MODE' => 1,
                    'DATA_INDENT' => 2,
                    'NAMESPACES' => 1,
                    'ENCODING' => 'utf-8',
                    'PREFIX_MAP' => {"http://www.w3.org/2001/XMLSchema-instance" => 'xsi'}
                    );

        my $self = $pkg->SUPER::new(%args);

        bless $self, $pkg;
        return $self;
}

sub startDocument {
        my $self = shift;
        my $args = shift;

        $self->xmlDecl("UTF-8");
        $self->startTag("moo", ["http://www.w3.org/2001/XMLSchema-instance", "noNamespaceSchemaLocation"] => "http://www.moo.com/xsd/api_0.7.xsd");

        $self->startTag("request");
        $self->startTag("version");
        $self->characters("0.7");
        $self->endTag("version");

        $self->startTag("api_key");
        $self->characters($args->{'api_key'});
        $self->endTag("api_key");

        $self->startTag("call");
        $self->characters("build");
        $self->endTag("call");

        $self->endTag("request");
        $self->startTag("payload");

        return $self;
}

sub endDocument {
        my $self = shift;
        $self->endTag("payload");
        $self->endTag("moo");
        $self->end();
}

sub product {
        my $self = shift;
        my $type = shift;
        my $designs = shift;

        $self->startTag("product");

        $self->startTag("product_type");
        $self->characters($type);
        $self->endTag("product_type");

        $self->startTag("designs");

        foreach my $data (@$designs){
                $data->{'__product'} = $type;
                $self->design($data);
        }

        $self->endTag("designs");
        $self->endTag("product");
}

sub design {
        my $self = shift;
        my $args = shift;

        $self->startTag("design");
        $self->image($args);

        if ($args->{'text'}){
                $self->text_collection($args);
        }

        $self->endTag("design");
}

sub image {
        my $self = shift;
        my $args = shift;

        my $type = ($args->{'type'}) ? $args->{'type'} : 'variable';
        my $crop = ($args->{'crop'}) ? $args->{'type'} : 'auto';

        $self->startTag("image");

        $self->startTag("url");
        $self->characters($args->{'url'});
        $self->endTag("url");

        $self->startTag("type");
        $self->characters($type);
        $self->endTag("type");

        $self->startTag("crop");
        
        if ($crop eq 'auto'){
                $self->startTag("auto");
                $self->characters("true");
                $self->endTag("auto");
        }

        else {
                $self->startTag("manual");
                
                foreach my $el (keys %{$args->{'manual'}}){
                        $self->startTag($el);
                        $self->characters($crop->{$el});
                        $self->endTag($el);
                }

                $self->endTag("manual");
        }
        
        $self->endTag("crop");
        $self->endTag("image");
}

sub text_collection {
        my $self = shift;
        my $data = shift;

        my $type = $data->{'__product'};

        if ($type eq 'greetingcard'){
                return $self->text_collection_greetingcard($data);
        }

        # because the order of elements apparently matters...

        my @possible = ('id', 'string', 'bold', 'align', 'font', 'colour');

        $self->startTag("text_collection");
        $self->startTag($type);

        foreach my $ln (@{$data->{'text'}}){

                $self->startTag('text_line');

                foreach my $el (@possible){
                        if (exists($ln->{$el})){
                                $self->startTag($el);
                                $self->characters($ln->{$el});
                                $self->endTag($el);
                        }
                }

                $self->endTag('text_line');
        }

        $self->endTag($type);
        $self->endTag("text_collection");
}

sub text_collection_greetingcard {
        my $self = shift;
        my $data = shift;

        $self->startTag("text_collection");
        $self->startTag('greetingcard');

        # because the order of elements apparently matters...

        my %possible = ('main' => ['string', 'align', 'font', 'colour'],
                        'back' => ['id', 'string', 'bold', 'align', 'font', 'colour']);

        foreach my $part ('main', 'back'){

                if (! exists($data->{'text'}->{$part})){
                        next;
                }

                $self->startTag($part);

                foreach my $ln (@{$data->{'text'}->{$part}}){

                        if ($part eq 'back'){
                                $self->startTag('text_line');
                        }

                        foreach my $el (@{$possible{$part}}){

                                if (exists($ln->{$el})){
                                        $self->startTag($el);
                                        $self->characters($ln->{$el});
                                        $self->endTag($el);
                                }
                        }

                        if ($part eq 'back'){
                                $self->endTag('text_line');
                        }
                }

                $self->endTag($part);
        }

        $self->endTag('greetingcard');
        $self->endTag("text_collection");
}

=head1 VERSION

0.11

=head1 DATE

$Date: 2008/06/19 15:15:34 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<Net::Moo>

=head1 LICENSE

Copyright (c) 2008 Aaron Straup Cope. All rights reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

return 1;
