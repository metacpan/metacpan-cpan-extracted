package Perl6::Pod::Parser::Utils;

=pod

=head1 NAME

Perl6::Pod::Parser::Utils - set of useful functions

=head1 SYNOPSIS

    use Perl6::Pod::Parser::Utils qw(parse_URI );

=head1 DESCRIPTION

Set of useful functions

=head1 METHODS

=back

=cut
our $VERSION = '0.01';
require Exporter;
*import                = \&Exporter::import;
@Perl6::Pod::Parser::Utils::EXPORT_OK = qw( parse_URI);

=head2 parse_URI ($string)

Parse Pod's URI:.
    
    scheme:path#section_name(rules)

For example:
    
    http://www.exapmple.com/test.pod#Sect1
    test.pod
    file:bundle.pod(para :public)
    file:../file1.txt
    Name|http://www.com#test

Return stucture:

    'Name|http://example.com/index.html#txt':
      {
        'is_external' => 1,
        'name'        => 'Name',
        'section'     => 'txt',
        'address'     => 'example.com/index.html',
        'scheme'      => 'http'
      }


    '../data/test.pod':
      {
        'is_external' => '',
        'name'        => '',
        'section'     => '',
        'address'     => '../data/test.pod',
        'scheme'      => 'file'
      }



    'http://www.com/d.pod(head1 :todo, para)':
     {
          'is_external' => '1',
          'name' => '',
          'section' => '',
          'address' => 'www.com/d.pod',
          'scheme' => 'http',
          'rules' => 'head1 :todo, para'
        }

=cut

sub parse_URI {
    my $txt  = shift;

    #extract linkname and content
    my ( $lname, $lcontent ) = ( '', defined $txt ? $txt : '' );
    if ( $lcontent =~ /\|/ ) {
        my @all;
        ( $lname, @all ) = split( /\s*\|\s*/, $lcontent );
        $lcontent = join "", @all;
    }
    my $attr = {};

    #clean whitespaces
    $lname =~ s/^\s+//;
    $lname =~ s/\s+$//;
    $attr->{name} = $lname;
    #strip include rules ( blockname : attr, ... )
    if ( $lcontent =~  s/\s*\(
                                ([^\(\)]*) 
                             \)
                             \s*$//x) {
        $attr->{rules} = $1
    }
    my ( $scheme, $address, $section ) =
    # Pod::Insertion::Name or http://www.com/d.pod(head1 :todo, para)
      $lcontent =~ /\s*(\w+)\s*\:(?!\:)([^\#]*)(?:\#(.*))?/;
    #set default scheme
    unless ($scheme) {
        $scheme = 'file';
        ( $address, $section ) = $lcontent =~ /([^\#]*)(?:\#(.*))?/;
    }
    $attr->{scheme} = $scheme;
    $address = '' unless defined $address;
    $attr->{is_external} = $address =~ s/^\/\/// || $scheme =~ /mailto|skype/;

    #clean whitespaces
    $address =~ s/^\s+//;
    $address =~ s/\s+$//;
    $attr->{address} = $address;

    #fix L<doc:#Special Features>
    $attr->{section} = defined $section ? $section : '';
    return $attr;
}


1;

__END__


=head1 SEE ALSO

L<http://perlcabal.org/syn/S26.html>

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

