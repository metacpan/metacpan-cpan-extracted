package TLV::EMV::Parser;
use base 'TLV::Parser';
use TLV::EMV::Tags 'EMV_TAGS';
use strict;
use warnings;

our ( $VERSION );
BEGIN {
    $VERSION = '1.01';
}

sub new {
    my $class = shift;
    my $href  = {
        tag_aref => EMV_TAGS,
        l_len    => 2,
    };

    my $self  = $class->SUPER::new($href);
    bless $self, $class;

    return $self;
}

1;

__END__

=head1 NAME

TLV::EMV::Parser - A module for parsing EMV TLV strings

=head1 SYNOPSIS

use TLV::EMV::Parser;

my $parser = TLV::EMV::Parser->new();
$parser->parse($emv_string);

=head1 DESCRIPTION

The TLV::EMV::Parser module provides a simple interface for parsing EMV strings. 
It uses TLV::Parser as its base module and pass all EMV Tags to it so the users can use it directly to parse EMV strings.

=head1 METHODS

=over 4

=item new()

Creates a new TLV::EMV::Parser object.

=item parse($emv_string)

Parses the specified EMV TLV string.

=back

=head1 AUTHOR

Guangsheng He <heguangsheng@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Guangsheng He

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
        



