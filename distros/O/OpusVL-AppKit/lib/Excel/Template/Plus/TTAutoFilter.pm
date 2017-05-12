package Excel::Template::Plus::TTAutoFilter;

use Moose;
extends 'Excel::Template::Plus::TT';

# theoretically all we need to do is set this on the constructor
# but there's no easy way to get at it from the catalyst view.
has '+template_class' => ( default => 'Template::AutoFilter' );

no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Excel::Template::Plus::TTAutoFilter

=head1 VERSION

version 2.29

=head1 SYNOPSIS

See L<Excel::Template::Plus::TTAutoFilter> for more information on the use of this module.

=head1 DESCRIPTION

This is an engine for Excel::Template::Plus which replaces the 
standard Excel::Template template features with Template::AutoFilter,
essentially TT with an HTML filter applied to all the output by default. See the 
L<Excel::Template::Plus> docs for more information.

=head1 NAME 

Excel::Template::Plus::TTAutoFilter - Extension of Excel::Template::Plus::TT using Template::AutoFilter

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
