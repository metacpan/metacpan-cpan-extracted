package Perldoc;
use Perldoc::Base -base;
use 5.006001;
our $VERSION = '0.20';

sub kwid_to_html {
    my $class = shift;

    require Perldoc::Parser::Kwid;
    require Perldoc::Emitter::HTML;

    my $html = '';
    my $receiver = Perldoc::Emitter::HTML->new->init(
        stringref => \$html,
    );
    my $parser = Perldoc::Parser::Kwid->new(
        receiver => $receiver,
    )->init(@_);
    $parser->parse;
    return $html;
}


=head1 NAME

Perldoc - Documentation Framework for Perl

=head1 SYNOPSIS

    > perl-doc --kwid-to-html Doc.kwid > Doc.html

=head1 DESCRIPTION

Perldoc is meant to be a full featured documentation framework for Perl.

This release just contains enough functionality to convert Kwid to HTML.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>
Audrey Tang <autrijus@cpan.org>

Audrey wrote the original code for this parser.

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
