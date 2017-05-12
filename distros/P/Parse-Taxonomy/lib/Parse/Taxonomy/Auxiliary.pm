package Parse::Taxonomy::Auxiliary;
use strict;
use Carp;
our ($VERSION, @ISA, @EXPORT_OK);
$VERSION = '0.24';
@ISA = qw( Exporter );
@EXPORT_OK = qw(
    path_check_fields
    components_check_fields
);

=head1 NAME

Parse::Taxonomy::Auxiliary - Utility subroutines for Parse::Taxonomy

=head1 SYNOPSIS

    use Parse::Taxonomy::Auxiliary qw(
        path_check_fields
        components_check_fields
    );

=cut

=head1 SUBROUTINES

=cut

sub path_check_fields {
    my ($data, $fields_ref) = @_;
    _check_fields($data, $fields_ref, 0);
}

sub components_check_fields {
    my ($data, $fields_ref) = @_;
    _check_fields($data, $fields_ref, 1);
}

sub _check_fields {
    my ($data, $fields_ref, $components) = @_;
    my %header_fields_seen;
    for my $f (@{$fields_ref}) {
        if (exists $header_fields_seen{$f}) {
            my $error_msg = '';
            if ($components) {
                $error_msg = "Duplicate field '$f' observed in 'fields' array ref";
            }
            else {
                $error_msg = "Duplicate field '$f' observed in '$data->{file}'";
            }
            croak $error_msg;
        }
        else {
            $header_fields_seen{$f}++;
        }
    }
}

1;

# vim: formatoptions=crqot
