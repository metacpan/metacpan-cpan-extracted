package Template::Caribou::Tags::HTML;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Basic HTML tag library
$Template::Caribou::Tags::HTML::VERSION = '1.2.2';

use strict;
use warnings;

use parent 'Exporter::Tiny';

our @EXPORT;
our @UNFORMATED_TAGS;
our @FORMATED_TAGS;

BEGIN {
@UNFORMATED_TAGS = qw/ i emphasis b strong span small sup /;
@FORMATED_TAGS = qw/
        p html head h1 h2 h3 h4 h5 h6 body div
        style title li ol ul a 
        label link img section article
        table thead tbody th td
        fieldset legend form input select option button
        textarea
/;
}

BEGIN {

    @EXPORT = @Template::Caribou::Tags::HTML::TAGS =  ( @UNFORMATED_TAGS, @FORMATED_TAGS );
    push @EXPORT, 'table_row';
}

use Template::Caribou::Tags
    mytag => { -as => 'table_row', tag => 'tr' },
    ( map { ( mytag => { -as => $_, tag => $_ } ) } @FORMATED_TAGS ),
    ( map { ( mytag => { -as => $_, tag => $_, indent => 0 } ) } @UNFORMATED_TAGS );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Caribou::Tags::HTML - Basic HTML tag library

=head1 VERSION

version 1.2.2

=head1 SYNOPSIS

    package MyTemplate;

    use Template::Caribou;

    use Template::Caribou::Tags::HTML;

    template main => sub {
        html {
            head { title { "Website X" } };
            body {
                h1 { "Some Title" };
                div {
                    "Blah blah";
                };
            };
        };
    };

=head1 DESCRIPTION

Exports tag blocks for regular HTML tags. 

=head1 TAG FUNCTIONS EXPORTED

p html head h1 h2 h3 h4 h5 h6 body emphasis div sup style title span li ol ul i b strong a label link img section article table thead tbody th td table_row fieldset legend form input select option button small textarea 

All function names are the same than their tag name, except for C<table_row>, which is for C<tr> (which is an already taken Perl keyword).

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
