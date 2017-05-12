package OpenDocument::Template;
{
  $OpenDocument::Template::VERSION = '0.002';
}
# ABSTRACT: generate OpenDocument from template

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use namespace::autoclean;
use autodie;

with qw(
    OpenDocument::Template::Role::Config
    OpenDocument::Template::Role::Generate
);

has 'template_dir' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => q{.},
);

has 'src' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'dest' => (
    is       => 'rw',
    isa      => 'Str',
);

has 'encoding' => (
    is       => 'rw',
    isa      => 'Str',
    default  => q{utf8},
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;


=pod

=encoding utf-8

=head1 NAME

OpenDocument::Template - generate OpenDocument from template

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use OpenDocument::Template;
    
    my $ot = OpenDocument::Template->new(
        config       => 'dcf.yml',
        template_dir => 'templates',
        src          => 'dcf-template.odt',
        dest         => 'dcf.odt',
    );
    $ot->generate;

=head1 DESCRIPTION

This module needs two files, template ODT file and config file.
C<OpenDocument::Template> supports L<Config::Any> configuration file types.
The config file describes which files in ODT have to updated.
Following YAML file is a sample configuration.

    ---
    templates:
      styles.xml:
        meta:
          title: SILEX Contacts
      content.xml:
        people:
          - nick:  yongbin
            name:  Yongbin Yu
            tel:   010-W2W1-0256
            email: yongbinxxx@gmail.com
            memo:  SILEX CEO.
          - nick:  keedi
            name:  Keedi Kim
            tel:   010-2511-6XY3
            email: keedyyy@gmail.com
            memo:  Perl Manua
          - nick:  mintegrals
            name:  Minsun Lee
            tel:   010-YZZ3-5XY6
            email: mintegrzzz@gmail.com
            memo:  MC.Miniper
          - nick:  aanoaa
            name:  홍형석
            tel:   010-31X2-0X00
            email: aanoxxx@gmail.com
            memo:  Mustache Mania
          - nick:  JEEN
            name:  이종진
            tel:   010-6W3Z-WX1Y
            email: aiateyyy@gmail.com
            memo:  Keyboard Warrior
          - nick:  rumidier
            name:  조한영
            tel:   010-6X66-2Y0X
            email: rumidzzz@gmail.com
            memo:  Wild Horse

With above configuration, you must have two template files,
C<styles.xml> and C<content.xml>.
And each additional data will be used when template
files is processed.

You can extract C<styles.xml> and C<content.xml>
from your OpenDocument file by hand.
Or use C<od-update.pl> tools which is a part of OpenDocument::Template.
First make your own ODT file, then make table for address book.
Then fill contents with C<meta.> or C<person.> prefix like
C<meta.title>, C<person.nick>, C<person.email>, ... etc.

Then run following command.

    od-update.pl -c addressbook.yml -s addressbook-template.odt  -t template/ -p '(meta|person)\.'

After that, you got two xml files which are formatted
using L<XML::Tidy> under C<template> directory.
And C<meta.title> will be turned into C<[% meta.title | xml %]> and
C<person.email> will be turned into C<[% person.email | xml %]>.
It uses L<Template> module so, check it to see specific syntax.
Maybe you need to edit and add more Template Toolkit syntax,
like loop or control statements.
In this case, you need loop statement in C<content.xml>
to display each person's information.

        ...
        [% FOR person IN people %]
        <table:table-row>
          <table:table-cell table:style-name="표1.A2" office:value-type="string">
            <text:p text:style-name="P4">[% person.nick | xml %]</text:p>
          </table:table-cell>
          <table:table-cell table:style-name="표1.A2" office:value-type="string">
            <text:p text:style-name="P4">[% person.name | xml %]</text:p>
          </table:table-cell>
          <table:table-cell table:style-name="표1.A2" office:value-type="string">
            <text:p text:style-name="P4">[% person.tel | xml %]</text:p>
          </table:table-cell>
          <table:table-cell table:style-name="표1.A2" office:value-type="string">
            <text:p text:style-name="P4">[% person.email | xml %]</text:p>
          </table:table-cell>
          <table:table-cell table:style-name="표1.E2" office:value-type="string">
            <text:p text:style-name="P4">[% person.memo | xml %]</text:p>
          </table:table-cell>
        </table:table-row>
        [% END %]
        ...

After editing template xml file then run following command,
then you can get result ODT file.

    od-gen.pl -c addressbook.yml -t template/ -s addressbook-template.odt -d addressbook-result.odt

=head1 ATTRIBUTES

=head2 config

Config file path or hash reference.
Support various config files, check L<Config::Any> for detail.

=head2 template_dir

Template directory which contains template file
to replace from source OpenDocument.
Default path is a current directory.

=head2 src

Source open document file path

=head2 dest

Destination open document file path

=head2 encoding

Encoding to apply template.
Default encoding is 'utf8'.

=head1 METHODS

=head2 new

Create new OpenDocument::Template object.

=head2 generate

Generate new OpenDocument from source document, template and data.

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

