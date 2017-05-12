package Test::Chado::Common;
{
  $Test::Chado::Common::VERSION = 'v4.1.1';
}
use Moo;
use MooX::ClassAttribute;
use Test::Chado::Types qw/TB/;
use Test::Builder;
use Sub::Exporter -setup => {
    exports => {
        'has_cv'         => \&_has_cv,
        'has_feature'    => \&_has_feature,
        'has_cvterm'     => \&_has_cvterm,
        'has_dbxref'     => \&_has_dbxref,
        'has_featureloc' => \&_has_featureloc,
    },
    groups => {
        'default' =>
            [qw/has_cv has_dbxref has_cvterm has_feature has_featureloc/]
    }
};

class_has 'test_builder' => (
    is      => 'ro',
    lazy    => 1,
    isa     => TB,
    default => sub { Test::Builder->new }
);

sub _has_cv {
    my ($class) = @_;
    return sub {
        my ( $schema, $cv, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema')  if !$schema;
        $test_builder->croak('need a cv name') if !$cv;

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cv';
        }
        else {
            $result_class = 'Cv';
        }
        my $count
            = $schema->resultset($result_class)->count( { name => $cv } );
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _has_feature {
    my ($class) = @_;
    return sub {
        my ( $schema, $name, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema')  if !$schema;
        $test_builder->croak('need a cv name') if !$name;

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Sequence::Feature';
        }
        else {
            $result_class = 'Feature';
        }
        my $count = $schema->resultset($result_class)
            ->count( { uniquename => $name } );
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _has_dbxref {
    my ($class) = @_;
    return sub {
        my ( $schema, $xref, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema')      if !$schema;
        $test_builder->croak('need a dbxref name') if !$xref;

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'General::Dbxref';
        }
        else {
            $result_class = 'Dbxref';
        }

        my $count
            = $schema->resultset($result_class)
            ->count( { accession => $xref } );
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _has_cvterm {
    my ($class) = @_;
    return sub {
        my ( $schema, $cvterm, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema')       if !$schema;
        $test_builder->croak('need a feature name') if !$cvterm;

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }

        my $count
            = $schema->resultset($result_class)->count( { name => $cvterm } );
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _has_featureloc {
    my ($class) = @_;
    return sub {
        my ( $schema, $name, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema')       if !$schema;
        $test_builder->croak('need a feature name') if !$name;

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Sequence::Feature';
        }
        else {
            $result_class = 'Feature';
        }

        my $count
            = $schema->resultset($result_class)
            ->search( { uniquename => $name } )
            ->search_related( 'featureloc_features', {} )->count;
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

1;

__END__

=pod

=head1 NAME

Test::Chado::Common

=head1 VERSION

version v4.1.1

=head1 API

=head2 Methods

=over

=item

All methods are available as exported subroutines by default

=item

All methods accept the same parameter pattern. The first two are required.

=back

=over

=item has_cv(L<DBIx::Class::Schema>, cv name, [description])

=item has_feature(L<DBIx::Class::Schema>, feature name, [description])

=item has_dbxref(L<DBIx::Class::Schema>, dbxref, [description])

=item has_cvterm(L<DBIx::Class::Schema>, cvterm name, [description])

=item has_featureloc(L<DBIx::Class::Schema>, feature name, [description])

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
