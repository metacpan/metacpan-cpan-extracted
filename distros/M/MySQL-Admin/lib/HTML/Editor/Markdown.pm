package HTML::Editor::Markdown;
use strict;
use warnings;
use vars qw(@EXPORT @ISA $currentstring @formatString);
use utf8;
require Exporter;
@HTML::Editor::Markdown::EXPORT  = qw(Markdown);
@ISA                             = qw(Exporter);
$HTML::Editor::Markdown::VERSION = '1.09';
use HTML::Entities;
use Text::Markdown::Hoedown;
$currentstring = 0;

=head1 NAME

HTML::Editor::Markdown - Markdown for HTML::Editor

=head1 required Modules

HTML::Entities

=head1 SYNOPSIS

        use HTML::Editor::Markdown;

        my $test = ...

        Markdown(\$test);

        print $test;

=head1 DESCRIPTION

Markdown is out of date. So will not be longer in use. Markdown will replace this.

Italics	*italics*

Bold	**bold** 

Underline	__underline__	

Strikethrough	~~Strikethrough~~

[link](http://dirk-lindner.com)

[i](http://dirk-lindner.com/foo.png)

=head2 EXPORT

Markdown()

=head2 Markdown

=cut

=head1 Public

=head2 Markdown

=cut

sub Markdown {
    my $string = shift;
    utf8::decode($$string) unless utf8::is_utf8($$string);
    $$string = encode_entities( $$string, '<>&' );
    $$string = markdown($$string);
    $$string =~ s/\n/<br>/;
} ## end sub Markdown

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2015 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut
1;
