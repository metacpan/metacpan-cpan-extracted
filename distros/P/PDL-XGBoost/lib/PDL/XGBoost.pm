package PDL::XGBoost;

use strict;
use warnings;
use Exporter 'import';
use Carp qw(croak);
use XSLoader;

use PDL::Core;
use PDL::Types;
use PDL::Slices;

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    dmatrix
    train
    load_model
    xgboost_version
);

XSLoader::load('PDL::XGBoost', $VERSION);

sub dmatrix {
    my ($x, $y, %opts) = @_;
    croak 'dmatrix requires a 2D PDL ndarray' unless defined $x;
    my $missing = exists $opts{missing} ? $opts{missing} : 'NaN' + 0;
    my $xf = $x->float();
    my $dm = PDL::XGBoost::DMatrix::_xs_from_pdl($xf, $missing);
    if (defined $y) {
        $dm->set_label($y->float());
    }
    return $dm;
}

sub train {
    my ($x, $y, %opts) = @_;
    my $rounds = delete $opts{num_boost_round} || 20;
    my $params = delete $opts{params}          || {};

    my $dm = (ref($x) && $x->isa('PDL::XGBoost::DMatrix'))
        ? $x
        : dmatrix($x, $y);

    my $booster = PDL::XGBoost::Booster::_xs_create($dm);
    for my $k (sort keys %{$params}) {
        $booster->set_param($k, '' . $params->{$k});
    }
    for my $i (0 .. $rounds - 1) {
        $booster->update($dm, $i);
    }
    return $booster;
}

sub load_model {
    my ($path) = @_;
    croak 'load_model requires a file path' unless defined $path && length $path;
    my $booster = PDL::XGBoost::Booster::_xs_create(undef);
    $booster->load_model($path);
    return $booster;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDL::XGBoost - XGBoost gradient boosting C API bindings for PDL

=head1 SYNOPSIS

    use PDL;
    use PDL::XGBoost qw(dmatrix train load_model xgboost_version);

    my $X = float([[1, 2], [2, 3], [3, 4], [4, 5]]);
    my $y = float([3, 5, 7, 9]);

    my $booster = train(
        $X, $y,
        num_boost_round => 50,
        params          => {
            objective => 'reg:squarederror',
            max_depth => 3,
            eta       => 0.2,
        },
    );

    my $preds = $booster->predict(dmatrix($X));
    $booster->save_model('model.ubj');

=head1 DESCRIPTION

C<PDL::XGBoost> binds L<PDL> ndarrays directly to XGBoost's pure-C API
(C<xgboost/c_api.h>) via C99 XS, enabling fast gradient-boosted decision tree
training, inference, and model persistence directly from Perl.

=head1 FUNCTIONS

=head2 dmatrix

=for ref

Create a C<PDL::XGBoost::DMatrix> from a 2D L<PDL> feature matrix (and optional
1D label ndarray).

=for usage

    $dm = dmatrix($X);
    $dm = dmatrix($X, $y);

=head2 train

=for ref

Train a C<PDL::XGBoost::Booster> for C<num_boost_round> iterations with the
given XGBoost parameter hashref.

=for usage

    $booster = train($X, $y, num_boost_round => 50, params => \%params);

=head2 load_model

=for ref

Load a saved XGBoost model (JSON/UBJ) from disk into a C<PDL::XGBoost::Booster>.

=for usage

    $booster = load_model($path);

=head2 xgboost_version

=for ref

Return the linked C<libxgboost> version string (e.g. C<3.0.4>).

=for usage

    $ver = xgboost_version();

=head1 SEE ALSO

L<PDL>, L<PDL::Torch>, L<PDL::IO::Arrow>, L<PDL::IO::Protobuf>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
