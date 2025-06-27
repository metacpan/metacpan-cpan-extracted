package Paws::DynamoDB::Response::Parser;

$Paws::DynamoDB::Response::Parser::VERSION   = '0.06';
$Paws::DynamoDB::Response::Parser::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;
use Data::Dumper;
use Carp qw(croak);
use Scalar::Util qw(blessed);

=head1 NAME

Paws::DynamoDB::Response::Parser - Convert Paws DynamoDB response objects to Perl data structures.

=head1 SYNOPSIS

  use Paws;
  use Paws::DynamoDB::Response::Parser;

  my $parser   = Paws::DynamoDB::Response::Parser->new;
  my $dynamodb = Paws->service('DynamoDB',
     region    => 'eu-west-1',
     endpoint  => 'http://localhost:4566'
  );
  my $response = $dynamodb->Scan(TableName => "Users");
  my $result   = $parser->to_perl($response);

=head1 DESCRIPTION

While working on the blog post for L<AWS DynamoDB|https://theweeklychallenge.org/blog/aws-dynamodb>, I had trouble
decoding the response. This is the solution to the trouble I was facing.

This module converts the following response objects into native Perl data structures,
handling all C<DynamoDB> attribute types (S, N, B, M, L etc.).

=over 4

=item Paws::DynamoDB::GetItemOutput

=item Paws::DynamoDB::ScanOutput

=item Paws::DynamoDB::QueryOutput

=item Paws::DynamoDB::BatchGetItemOutput

=back

=cut

=head1 METHODS

=head2 new()

Creates a new parser instance.

=cut

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

=head2 to_perl($response)

Converts Paws DynamoDB response object to a Perl data structure.

Supported response types:

=over 4

=item - GetItemOutput

=item - ScanOutput

=item - QueryOutput

=item - BatchGetItemOutput

=back

=cut

sub to_perl {
    my ($self, $response) = @_;

    unless (blessed($response)) {
        croak "Invalid response object";
    }

    if ($response->isa('Paws::DynamoDB::GetItemOutput')) {
        return $response->Item ? $self->_unwrap_item($response->Item) : undef;
    }
    elsif ($response->isa('Paws::DynamoDB::ScanOutput') ||
           $response->isa('Paws::DynamoDB::QueryOutput')) {
        my $items = $response->Items || [];
        return [ map { $self->_unwrap_item($_) } @$items ];
    }
    elsif ($response->isa('Paws::DynamoDB::BatchGetItemOutput')) {
        return $self->_process_batch_response($response);
    }

    croak "Unsupported response type: " . ref($response);
}

#
#
# PRIVATE SUBROUTINES

sub _process_batch_response {
    my ($self, $response) = @_;

    my @all_items;

    if ($response->Responses && blessed($response->Responses)) {
        my $responses_map = $response->Responses->Map;
        foreach my $table_name (keys %$responses_map) {
            my $table_items = $responses_map->{$table_name};
            if (ref $table_items eq 'ARRAY') {
                push @all_items, map { $self->_unwrap_item($_) } @$table_items;
            }
        }
    }

    return \@all_items;
}

sub _unwrap_item {
    my ($self, $item) = @_;
    return undef unless defined $item
                        && blessed($item)
                        && $item->isa('Paws::DynamoDB::AttributeMap');

    my %unwrapped;
    my $item_map = $item->Map;
    foreach my $key (keys %$item_map) {
        $unwrapped{$key} = $self->_unwrap_attribute($item_map->{$key});
    }
    return \%unwrapped;
}

sub _unwrap_attribute {
    my ($self, $attr) = @_;

    return undef unless defined $attr
                        && blessed($attr)
                        && $attr->isa('Paws::DynamoDB::AttributeValue');

    if    (defined $attr->S)      { return $attr->S;     }
    elsif (defined $attr->N)      { return $attr->N + 0; }
    elsif (defined $attr->BOOL)   { return $attr->BOOL;  }
    elsif (defined $attr->NULL)   { return undef;        }
    elsif (defined $attr->B)      { return $attr->B;     }
    elsif (defined $attr->M)      {
        my %map;
        foreach my $key (keys %{$attr->M}) {
            $map{$key} = $self->_unwrap_attribute($attr->M->{$key});
        }
        return \%map;
    }
    elsif (defined $attr->L)      {
        return [ map { $self->_unwrap_attribute($_) } @{$attr->L} ];
    }
    elsif (defined $attr->SS)     { return $attr->SS; }
    elsif (defined $attr->NS)     { return [ map { $_ + 0 } @{$attr->NS} ]; }
    elsif (defined $attr->BS)     { return $attr->BS; }

    croak "Unsupported attribute type: " . Dumper($attr);
}

=head1 AUTHOR

Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>

=head1 REPOSITORY

L<https://github.com/manwar/Paws-DynamoDB-Response-Parser>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Paws-DynamoDB-Response-Parser/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Paws::DynamoDB::Response::Parser

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Paws-DynamoDB-Response-Parser/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Paws-DynamoDB-Response-Parser>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Paws-DynamoDB-Response-Parser/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=head1 LICENSE

=cut

1; # End of Paws::DynamoDB::Response::Parser

