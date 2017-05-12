package Pod::ToDocBook;

#$Id: ToDocBook.pm 695 2010-01-18 17:48:33Z zag $

=head1 NAME

Pod::ToDocBook - Pluggable converter POD data to DocBook.

=head1 SYNOPSIS

    use Pod::ToDocBook 'create_parser';
    my $buf;
    my $src = shift;
    open FH, "< $src" or die "Error open $src: $!";
    my $w = new XML::SAX::Writer:: Output => \$buf;

    my $p = create_parser({header => 0, doctype => 'chapter'}, $w );
    $p->parse( \*FH );
    print $buf;

=head1 DESCRIPTION

Pod::ToDocBook - set of L<XML::ExtOn> filters for process POD data.

=over 

=item * Pod::ToDocBook::Pod2xml - convert POD to  XML

=item * Pod::ToDocBook::DoSequences - process format sequences and links

=item * Pod::ToDocBook::ProcessHeads - process =head's elements

=item *  Pod::ToDocBook::TableDefault 
=back

Sample  for add new processor:

    package MyFilter1;
    use Test::More;
    use XML::ExtOn;
    use base 'XML::ExtOn';

    sub on_start_element {
        my ( $self ,$el ) = @_;
        if ( $el->local_name eq 'para') {
            #simply warn when para start
            diag "para!";
        }
    }
    
    package main;
    use strict;
    use warnings;
    use Pod::ToDocBook 'create_parser';
    
    my $buf;
    my $src = shift;
    open FH, "< $src" or die "Error open $src: $!";
    my $w = new XML::SAX::Writer:: Output => \$buf;
    #add custom filter "MyFilter1" to parser pipe
    my $p = create_parser({header => 0, doctype => 'chapter'}, "MyFilter1", $w );
    $p->parse( \*FH );
    print $buf;


=cut

use warnings;
use strict;
use XML::ExtOn('create_pipe');
use Pod::ToDocBook::Pod2xml;
use Pod::ToDocBook::ProcessHeads;
use Pod::ToDocBook::ProcessItems;
use Pod::ToDocBook::DoSequences;
use Pod::ToDocBook::TableDefault;
use Pod::ToDocBook::FormatList;
use XML::SAX::Writer;

require Exporter;
*import                    = \&Exporter::import;
@Pod::ToDocBook::EXPORT_OK = qw(create_parser);
$Pod::ToDocBook::VERSION   = '0.9';

=head1 FUNCTIONS

=head2 create_parser { head=>0|1,  doctype=>chapter|some_root_tag [ , base_id =>'some_namespace']} [, 'MyFilter1', $link_to_SAX_object ]

Create parser for process pod.

    my $p = create_parser({header => 0, doctype => 'chapter', base_id=>'name_space'}, "MyFilter1", $w );
    $p->parse( \*FH );

=cut

sub create_parser {

    my $attr = shift;

    my $px = new Pod::ToDocBook::Pod2xml::
      header  => $attr->{header},
      doctype => $attr->{doctype},
      base_id => defined($attr->{base_id}) ? $attr->{base_id} : '';

    my $p = create_pipe(
        $px, 'Pod::ToDocBook::FormatList','Pod::ToDocBook::ProcessItems',
         'Pod::ToDocBook::TableDefault',
        'Pod::ToDocBook::DoSequences', 'Pod::ToDocBook::ProcessHeads',
        , @_
    );
    return $p;
}

1;
__END__

=head1 SEE ALSO

Pod::ToDocBook::Pod2xml, Pod::ToDocBook::DoSequences, Pod::ToDocBook::ProcessHeads, XML::ExtOn, XML::Writer, Pod::2::DocBook,  Pod::ToDocBook::TableDefault

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

