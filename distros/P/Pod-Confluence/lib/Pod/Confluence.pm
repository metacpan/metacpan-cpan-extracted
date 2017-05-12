use strict;
use warnings;

package Pod::Confluence;
$Pod::Confluence::VERSION = '1.01';
# ABSTRACT: Converts pod to confluence flavored markdown
# PODNAME: Pod::Confluence

use parent qw(Pod::Simple::Methody);

use HTML::Entities;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return shift->Pod::Simple::Methody::new()->_init(@_);
}

sub _confluence_macro_end {
    my ( $self, %options ) = @_;

    my @optional_elements = ( ( $options{has_text} ? ']]></ac:plain-text-body>' : () ), );

    return join( '', @optional_elements, '</ac:structured-macro>' );
}

sub _confluence_macro_start {
    my ( $self, $name, %options ) = @_;
    my $parameters = $options{parameters} || {};

    my @optional_elements = (
        (   map {"<ac:parameter ac:name='$_'>$parameters->{$_}</ac:parameter>"}
                keys(%$parameters)
        ),
        ( $options{has_text} ? '<ac:plain-text-body><![CDATA[' : () ),
    );

    return join( '',
        "<ac:structured-macro ac:name='$name' ac:schema-version='$self->{confluence_schema_version}'",
        ( $options{self_close} ? ' /' : '' ), ">", @optional_elements );
}

sub end_B {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</strong>');
}

sub end_C {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</code>');
}

sub end_F {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</em>');
}

sub end_head1 {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</h1>');
    pop( @{ $self->{element_stack} } );
}

sub end_head2 {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</h2>');
    pop( @{ $self->{element_stack} } );
}

sub end_head3 {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</h3>');
    pop( @{ $self->{element_stack} } );
}

sub end_head4 {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</h4>');
    pop( @{ $self->{element_stack} } );
}

sub end_I {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</em>');
}

sub end_item_text {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</strong>');
    $self->end_Para();
}

sub end_L {
    my ( $self, $attribute_hash ) = @_;
    if ( $self->{link_type} eq 'pod' ) {
        $self->{in_cdata} = 0;
        $self->_print( ']]></ac:plain-text-link-body>' . '</ac:link>' );
    }
    elsif ( $self->{link_type} eq 'url' ) {
        $self->_print('</a>');
    }
    delete( $self->{link_type} );
}

sub end_over_text {
    my ( $self, $attribute_hash ) = @_;
    $self->{indent} -= 2;
}

sub end_Para {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('</p>');
    pop( @{ $self->{element_stack} } );
}

sub end_S {
    my ( $self, $attribute_hash ) = @_;
    $self->{in_non_breaking} = 0;
}

sub end_Verbatim {
    my ( $self, $attribute_hash ) = @_;
    $self->{in_cdata} = 0;
    $self->_print( $self->_confluence_macro_end( has_text => 1 ) );
    pop( @{ $self->{element_stack} } );
}

sub _handle_element_end {
    $logger->tracef( '_handle_element_end(%s,%s)', $_[1], $_[2] );
    Pod::Simple::Methody::_handle_element_end(@_);
}

sub _handle_element_start {
    $logger->tracef( '_handle_element_start(%s,%s)', $_[1], $_[2] );
    Pod::Simple::Methody::_handle_element_start(@_);
}

sub handle_text {
    my ( $self, $text ) = @_;

    $text = encode_entities($text) unless ( $self->{in_cdata} );
    $text =~ s/[ \t]/&nbsp;/g if ( $self->{in_non_breaking} );

    $logger->tracef( 'handle_text(%s)', $text );
    $self->_print($text);
}

sub _init {
    my ( $self, %options ) = @_;

    $self->{space_key} = $options{space_key};
    $self->{packages_in_space} =
        { map { $_ => 1 } @{ $options{packages_in_space} } };
    $self->{confluence_schema_version} = $options{confluence_schema_version} || 1;

    $self->{element_stack} = [];
    $self->{indent}        = 0;

    return $self;
}

sub _print {
    my ( $self, $text ) = @_;
    print( { $self->{output_fh} } $text );
}

sub start_B {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('<strong>');
}

sub start_C {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('<code>');
}

sub start_F {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('<em>');
}

sub start_Document {
    my ( $self, $attribute_hash ) = @_;
    $self->_print( '<p>' . $self->_confluence_macro_start( 'toc', self_close => 1 ) . '</p>' );
}

sub start_head1 {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('<h1>');
    $self->{indent} = 0;
}

sub start_head2 {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('<h2>');
    $self->{indent} = 0;
}

sub start_head3 {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('<h3>');
    $self->{indent} = 0;
}

sub start_head4 {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('<h4>');
    $self->{indent} = 0;
}

sub start_I {
    my ( $self, $attribute_hash ) = @_;
    $self->_print('<em>');
}

sub start_item_text {
    my ( $self, $attribute_hash ) = @_;
    $self->{indent} -= 1;
    $self->start_Para();
    $self->{indent} += 1;
    $self->_print('<strong>');
}

sub start_L {
    my ( $self, $attribute_hash ) = @_;
    $self->{link_type} = $attribute_hash->{type};
    if ( $attribute_hash->{type} eq 'pod' ) {
        my $to = $attribute_hash->{to};
        if ( !$to || $self->{packages_in_space}{"$to"} ) {
            $self->{link_type} = 'pod';
            $self->_print(
                (   $attribute_hash->{section}
                    ? "<ac:link ac:anchor='$attribute_hash->{section}'>"
                    : '<ac:link>'
                )
                . ( $to ? "<ri:page ri:content-title='$to' ri:space-key='$self->{space_key}'/>"
                    : ''
                    )
                    . '<ac:plain-text-link-body><![CDATA['
            );
            $self->{in_cdata} = 1;
        }
        else {
            my $url = $to ? "https://metacpan.org/pod/$to" : '';
            my $section = $attribute_hash->{section};
            if ($section) {
                $section =~ s/[^a-zA-Z0-9]+/-/g;
                $section =~ s/-$//g;
                $url .= "#$section";
            }
            $self->{link_type} = 'url';
            $self->_print("<a href='$url'>");
        }
    }
    elsif ( $attribute_hash->{type} eq 'url' ) {
        $self->{link_type} = 'url';
        $self->_print("<a href='$attribute_hash->{to}'>");
    }
}

sub start_over_text {
    my ( $self, $attribute_hash ) = @_;
    $self->{indent} += 2;
}

sub start_Para {
    my ( $self, $attribute_hash ) = @_;
    my $style;
    if ( $self->{indent} ) {
        $style = 'style="margin-left: ' . ( $self->{indent} * 30 ) . 'px;"';
    }
    $self->_print( $style ? "<p $style>" : '<p>' );
}

sub start_S {
    my ( $self, $attribute_hash ) = @_;
    $self->{in_non_breaking} = 1;
}

sub start_Verbatim {
    my ( $self, $attribute_hash ) = @_;
    $self->_print(
        $self->_confluence_macro_start(
            'code',
            has_text   => 1,
            parameters => { language => 'perl' }
        )
    );
    $self->{in_cdata} = 1;
}

1;

__END__

=pod

=head1 NAME

Pod::Confluence - Converts pod to confluence flavored markdown

=head1 VERSION

version 1.01

=head1 SYNOPSIS

    my $parser = Pod::Confluence->new(
        space_key => 'FooPod',
        packages_in_space => [
            'Foo',
            'Foo::Bar',
            'Foo::Baz',
        ]);

    my $structured_storage_markdown;
    $parser->output_string(\$structured_storage_markdown);
    $parser->parse_file('/path/to/Foo.pm');

=head1 DESCRIPTION

This module uses L<Pod::Simple> to convert POD to Confluence structured 
storage format.  The output can be cut/paste into the source view of a page,
or you can use the Confluence API to push directly to the server.

=head1 CONSTRUCTORS

=head2 new(%options)

Creates a new parser to process POD into markdown.  Available options are:

=over 4

=item space_key

The C<spaceKey> from the Confluence space this page will be added to.  This
is necessary to ensure all the links between pages are properly generated.

=item packages_in_space

This is a list of all the packages that will be in this space.  When a POD 
link is encountered, this list will be checked.  If the package is in the
list, a local link will be generated.  Otherwise, the link will point to
metacpan.

=back

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Simple|Pod::Simple>

=back

=for Pod::Coverage end_B end_C end_F end_head1 end_head2 end_head3 end_head4 end_I end_item_text end_L end_over_text end_Para end_S end_Verbatim handle_text start_B start_C start_F start_Document start_head1 start_head2 start_head3 start_head4 start_I start_item_text start_L start_over_text start_Para start_S start_Verbatim 

=cut
