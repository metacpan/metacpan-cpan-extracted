package Pistachio::Css::Github;
# ABSTRACT: provides methods which return CSS definitions, for a Github-like styling

use strict;
use warnings;
our $VERSION = '0.10'; # VERSION


# @param string $type Object type.
# @return Pistachio::Css::Github
sub new { 
    my $type = shift;
    bless \$type, $type;
}

# @param Pistachio::Css::Github
# @return string    css for the line count div
sub number_strip {
    my @style = (
        "font-family:Consolas,'Liberation Mono',Courier,monospace",
        'float:left',
        'background-color:#eee',
        'border-right:1px #999988 solid'
        );
    join ';', @style;
}

# @param Pistachio::Css::Github
# @return string    css for a single line count number cell
sub number_cell {
    my @style = (
        'font-size:13px',
        'color:#999988',
        'display:block',
        'line-height:18px',
        'padding:0 8px',
        'margin:0',
        'border:0',
        'text-align:right',
        'border-spacing:2px'
        );
    join ';', @style;
}

# @param Pistachio::Css::Github
# @return string    css for the div containing source code token spans
sub code_div {
    my @style = (
        "font-family:Consolas,'Liberation Mono',Courier,monospace",
        'padding:0 8px 0 11px',
        'white-space:pre',
        'font-size:13px',
        'line-height:18px',
        'float:left'
        );
    join ';', @style;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pistachio::Css::Github - provides methods which return CSS definitions, for a Github-like styling

=head1 VERSION

version 0.10

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
