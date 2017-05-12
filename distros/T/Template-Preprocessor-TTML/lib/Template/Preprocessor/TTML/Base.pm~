package Template::Preprocessor::TTML::Base;

use strict;
use warnings;

=head1 NAME

Template::Preprocessor::TTML::Base - Base class for Template::Preprocessor::TTML classes

=cut

use base 'Class::Accessor';

=head2 Template::Preprocessor::TTML::Base->new(@args)

What this does is create an object that inherits from Class::Accessor, and
also has a default constructor that is initialized using the initialize()
function.

=cut
sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@iglu.org.il> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11

=cut

1;
