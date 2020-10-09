package Spreadsheet::ParseODS::Settings;
use Moo 2;
use Carp qw(croak);
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use PerlX::Maybe;

our $VERSION = '0.32';

=head1 NAME

Spreadsheet::ParseODS::Settings - settings of a workbook

=cut

has 'active_sheet_name' => (
    is => 'rw'
);

1;
