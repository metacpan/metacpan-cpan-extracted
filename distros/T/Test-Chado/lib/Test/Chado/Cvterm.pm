package Test::Chado::Cvterm;
{
  $Test::Chado::Cvterm::VERSION = 'v4.1.1';
}
use Moo;
use MooX::ClassAttribute;
use Test::Chado::Types qw/TB/;
use Test::Builder;
use Sub::Exporter -setup => {
    exports => {
        'count_cvterm_ok'              => \&_count_cvterm,
        'count_obsolete_cvterm_ok'     => \&_count_obsolete_cvterm,
        'count_relationship_cvterm_ok' => \&_count_relationship_cvterm,
        'count_synonym_ok'             => \&_count_synonym,
        'count_alt_id_ok'              => \&_count_alt_id,
        'count_subject_ok'             => \&_count_subject,
        'count_object_ok'              => \&_count_object,
        'count_comment_ok'             => \&_count_comment,
        'has_synonym'                  => \&_has_synonym,
        'has_alt_id'                   => \&_has_alt_id,
        'has_comment'                  => \&_has_comment,
        'has_relationship'             => \&_has_relationship,
        'has_xref'                     => \&_has_xref,
        'is_obsolete_cvterm'           => \&_is_obsolete_cvterm
    },
    groups => {
        'count' => [
            qw/count_alt_id_ok count_cvterm_ok count_synonym_ok count_subject_ok count_object_ok
                count_comment_ok count_obsolete_cvterm_ok count_relationship_cvterm_ok/
        ],
        'check' => [
            qw/has_synonym has_alt_id has_comment has_relationship is_related has_xref is_obsolete_term/
        ],
        'relationship' => [
            qw/count_object_ok count_subject_ok has_relationship is_related count_relationship_cvterm_ok/
        ]
    }
};

class_has 'test_builder' => (
    is      => 'ro',
    lazy    => 1,
    isa     => TB,
    default => sub { Test::Builder->new }
);

sub _check_params_or_die {
    my ( $class, $args, $param ) = @_;
    my $test_builder = $class->test_builder;
    for my $key (@$args) {
        if ( not defined $param->{$key} ) {
            $test_builder->croak("need $key parameter");
        }
    }
}

sub _is_obsolete_cvterm {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv term/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }
        my $count = $schema->resultset($result_class)->count(
            {   'cv.name'     => $param->{cv},
                'is_obsolete' => 1,
                'me.name'     => $param->{term}
            },
            { join => 'cv' }
        );
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _count_cvterm {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv count/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }
        my $count = $schema->resultset($result_class)->count(
            {   'cv.name'             => $param->{cv},
                'is_obsolete'         => 0,
                'is_relationshiptype' => 0
            },
            { join => 'cv' }
        );
        return $test_builder->is_num( $count, $param->{count}, $msg );
    };
}

sub _count_obsolete_cvterm {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv count/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }
        my $count = $schema->resultset($result_class)->count(
            {   'cv.name'     => $param->{cv},
                'is_obsolete' => 1,
            },
            { join => 'cv' }
        );
        return $test_builder->is_num( $count, $param->{count}, $msg );
    };
}

sub _count_relationship_cvterm {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv count/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }
        my $count = $schema->resultset($result_class)->count(
            {   'cv.name'             => $param->{cv},
                'is_relationshiptype' => 1,
                'is_obsolete'         => 0,
                'me.name'             => { -not_in => 'is_a' }
            },
            { join => 'cv' }
        );
        return $test_builder->is_num( $count, $param->{count}, $msg );
    };
}

sub _count_comment {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv count/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvtermprop';
        }
        else {
            $result_class = 'Cvtermprop';
        }
        my $count = $schema->resultset($result_class)->count(
            {   'cv.name'   => $param->{cv},
                'cv_2.name' => 'cvterm_property_type',
                'type.name' => 'comment'
            },
            { join => [ { 'cvterm' => 'cv' }, { 'type' => 'cv' } ] }
        );
        return $test_builder->is_num( $count, $param->{count}, $msg );
    };
}

sub _count_synonym {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv count/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvtermsynonym';
        }
        else {
            $result_class = 'Cvtermsynonym';
        }
        my $count = $schema->resultset($result_class)->count(
            { 'cv.name' => $param->{cv} },
            { join      => { 'cvterm' => 'cv' } }
        );
        return $test_builder->is_num( $count, $param->{count}, $msg );
    };
}

sub _count_alt_id {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/count db/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::CvtermDbxref';
        }
        else {
            $result_class = 'CvtermDbxref';
        }
        my $count
            = $schema->resultset($result_class)
            ->count( { 'db.name' => [ $param->{db}, $param->{cv} ] },
            { join => [ { 'dbxref' => 'db' } ] } );
        return $test_builder->is_num( $count, $param->{count}, $msg );
    };
}

sub _count_subject {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv object count/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::CvtermRelationship';
        }
        else {
            $result_class = 'CvtermRelationship';
        }

        my $query
            = $param->{relationship}
            ? {
            'cv.name'     => $param->{cv},
            'object.name' => $param->{object},
            'type.name'   => $param->{relationship}
            }
            : {
            'object.name' => $param->{object},
            'cv.name'     => $param->{cv}
            };
        my $count
            = $schema->resultset($result_class)
            ->count( $query, { join => [ { 'object' => 'cv' }, 'type' ] } );
        return $test_builder->is_num( $count, $param->{count}, $msg );
    };
}

sub _count_object {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv subject count/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::CvtermRelationship';
        }
        else {
            $result_class = 'CvtermRelationship';
        }

        my $query
            = $param->{relationship}
            ? {
            'cv.name'      => $param->{cv},
            'subject.name' => $param->{subject},
            'type.name'    => $param->{relationship}
            }
            : {
            'cv.name'      => $param->{cv},
            'subject.name' => $param->{subject}
            };
        my $count
            = $schema->resultset($result_class)
            ->count( $query, { join => [ { 'subject' => 'cv' }, 'type' ] } );
        return $test_builder->is_num( $count, $param->{count}, $msg );
    };
}

sub _has_synonym {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv term synonym/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }

        my $count;
        if ( defined $param->{cv} ) {
            $count = $schema->resultset($result_class)->count(
                {   'cv.name'                => $param->{cv},
                    'me.name'                => $param->{term},
                    'cvtermsynonyms.synonym' => $param->{synonym},
                    'type.name' => { -in => [qw/BROAD EXACT NARROW RELATED/] }
                },
                { join => [ 'cv', { 'cvtermsynonyms' => 'type' } ] }
            );
        }
        else {
            $count = $schema->resultset($result_class)->count(
                {   'me.name'                => $param->{term},
                    'cvtermsynonyms.synonym' => $param->{synonym},
                    'type.name' => { -in => [qw/BROAD EXACT NARROW RELATED/] }
                },
                { join => [ { 'cvtermsynonyms' => 'type' } ] }
            );
        }
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _has_alt_id {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv term alt_id/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }
        my ( $db, $id );
        if ( $param->{alt_id} =~ /:/ ) {
            ( $db, $id ) = split /:/, $param->{alt_id}, 2;
        }
        else {
            $db = $param->{cv};
            $id = $param->{alt_id};
        }

        my $count;
        if ( defined $param->{cv} ) {
            $count = $schema->resultset($result_class)->search(
                {   'cv.name' => $param->{cv},
                    'me.name' => $param->{term},
                },
                { join => 'cv' }
                )->search_related( 'cvterm_dbxrefs', {} )->search_related(
                'dbxref',
                { 'accession' => $id, 'db.name' => $db },
                { join        => 'db' }
                )->count;
        }
        else {
            $count
                = $schema->resultset($result_class)
                ->search( { 'name' => $param->{term} } )
                ->search_related( 'cvterm_dbxrefs', {} )->search_related(
                'dbxref',
                { 'accession' => $id, 'db.name' => $db },
                { join        => 'db' }
                )->count;

        }
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _has_xref {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv term xref/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }
        my ( $db, $id );
        if ( $param->{xref} =~ /:/ ) {
            ( $db, $id ) = split /:/, $param->{xref}, 2;
        }
        else {
            $db = '_global';
            $id = $param->{xref};
        }

        my $count;
        if ( defined $param->{cv} ) {
            $count = $schema->resultset($result_class)->search(
                {   'cv.name' => $param->{cv},
                    'me.name' => $param->{term},
                },
                { join => 'cv' }
                )->search_related( 'cvterm_dbxrefs', {} )->search_related(
                'dbxref',
                { 'accession' => $id, 'db.name' => $db },
                { join        => 'db' }
                )->count;
        }
        else {
            $count
                = $schema->resultset($result_class)
                ->search( { 'name' => $param->{term} } )
                ->search_related( 'cvterm_dbxrefs', {} )->search_related(
                'dbxref',
                { 'accession' => $id, 'db.name' => $db },
                { join        => 'db' }
                )->count;

        }
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _has_comment {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/cv term comment/], $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::Cvterm';
        }
        else {
            $result_class = 'Cvterm';
        }

        my $count;
        if ( $param->{cv} ) {
            $count = $schema->resultset($result_class)->search(
                {   'cv.name' => $param->{cv},
                    'me.name' => $param->{term},
                },
                { join => 'cv' }
                )->search_related(
                'cvtermprops',
                {   'value'     => $param->{comment},
                    'type.name' => 'comment',
                    'cv_2.name' => 'cvterm_property_type'
                },
                { join => { 'type' => 'cv' } }
                )->count;
        }
        else {
            $count
                = $schema->resultset($result_class)
                ->search( { 'name' => $param->{term}, }, )->search_related(
                'cvtermprops',
                {   'value'     => $param->{comment},
                    'type.name' => 'comment',
                    'cv_2.name' => 'cvterm_property_type'
                },
                { join => { 'type' => 'cv' } }
                )->count;

        }
        $test_builder->ok( $count, $msg );
        return $count;
    };
}

sub _has_relationship {
    my ($class) = @_;
    return sub {
        my ( $schema, $param, $msg ) = @_;
        my $test_builder = $class->test_builder;
        $test_builder->croak('need a schema') if !$schema;
        $test_builder->croak('need options')  if !$param;
        $class->_check_params_or_die( [qw/object subject relationship/],
            $param );

        my $result_class;
        if ( $schema->isa('Bio::Chado::Schema') ) {
            $result_class = 'Cv::CvtermRelationship';
        }
        else {
            $result_class = 'CvtermRelationship';
        }

        my $count = $schema->resultset($result_class)->count(
            {   'object.name'  => $param->{object},
                'subject.name' => $param->{subject},
                'type.name'    => $param->{relationship}
            },
            { join => [ 'subject', 'object', 'type' ] }
        );
        $test_builder->ok( $count, $msg );
        return $count;
        }
}

1;

__END__

=pod

=head1 NAME

Test::Chado::Cvterm

=head1 VERSION

version v4.1.1

=head1 NAME

API for testing cvterm.

=head1 API

=head2 Exported method groups

There are three exported groups.  As usual, all methods could be exported by the special B<all> export group.

=over

=item B<count>

=over

=item count_cvterm_ok

=item count_obsolete_cvterm_ok

=item count_relationship_cvterm_ok

=item count_alt_id_ok

=item count_comment_ok 

=item count_object_ok

=item count_subject_ok

=item count_synonym_ok

=back

=item B<check>

=over

=item has_synonym

=item has_alt_id

=item has_comment

=item has_relationship

=item is_obsolete_cvterm

=item has_xref

=item has_synonym

=back

=item B<relationship>

=over

=item count_object_ok

=item count_subject_ok

=item has_relationship

=item count_relationship_cvterm_ok

=back

=back

=head2 Methods

Unless specified, all parameters are mandatory.

=over

=item count_cvterm_ok(L<DBIx::Class::Schema>, \%expected, [description])

Tests for numbers of cvterms in an ontology excluding obsolete and relationship terms.

=over

=item B<parameters>

B<cv>: Name of the cv.

B<count>: Expected number of cvterms in that cv

=back

=item count_obsolete_cvterm_ok(L<DBIx::Class::Schema>, \%expected, [description])

Tests for numbers of obsolete cvterms.
Identical parameters as B<count_cvterm_ok>

=item count_relationship_cvterm_ok(L<DBIx::Class::Schema>, \%expected, [description])

Tests for numbers of relationship cvterms excluding the built-ins and obsoletes.
Identical parameters as B<count_cvterm_ok>

=item count_synonym_ok(L<DBIx::Class::Schema>, \%expected, [description])

Identical parameters as B<count_cvterm_ok>

=item count_comment_ok(L<DBIx::Class::Schema>, \%expected, [description])

Identical parameters as B<count_cvterm_ok>

=item count_alt_id_ok(L<DBIx::Class::Schema>, \%expected, [description])

=over

=item B<parameters>

B<cv>: Name of the cv.

B<count>: Expected number of alt_ids

B<db>: Database namespace in which the alternate ids belongs to. Both cv and db namespaces will be used for counting.

=back

=item count_subject_ok(L<DBIx::Class::Schema>, \%expected, [description])

Tests the number of children terms for a parent.

=over

=item B<parameters>

B<cv>: Name of the cv.

B<object>: Name of parent cvterm

B<count>: Expected number of children 

B<relationship>: Name of relationship, optional

=back

=item count_object_ok(L<DBIx::Class::Schema>, \%expected, [description])

Tests the number of parent terms for a child.

=over

=item B<parameters>

B<cv>: Name of the cv.

B<subject>: Name of child cvterm

B<expected>: Expected number of parent(s) 

B<relationship>: Name of relationship, optional

=back

=item has_cvterm_synonym(L<DBIx::Class::Schema>, \%expected, [description])

Tests if a cvterm has particular synonym.

=over

=item B<parameters>

B<cv>: Name of the cv, optional.

B<term>: Name of cvterm.

B<synonym>: Name of synonym.

=back

=item has_alt_id(L<DBIx::Class::Schema>, \%expected, [description])

Tests if a cvterm has particular alternate id.

=over

=item B<parameters>

B<cv>: Name of the cv, optional.

B<term>: Name of cvterm.

B<alt_id>: Name of alternate id.

=back

=item has_xref(L<DBIx::Class::Schema>, \%expected, [description])

Tests if a cvterm has a particular xref.

=over

=item B<parameters>

B<cv>: Name of the cv, optional.

B<term>: Name of cvterm.

B<xref>: Name of alternate id.

=back

=item has_comment(L<DBIx::Class::Schema>, \%expected, [description])

Tests if a cvterm has particular comment.

=over

=item B<parameters>

B<cv>: Name of the cv, optional.

B<term>: Name of cvterm.

B<comment>: Comment text.

=back

=item has_relationship(L<DBIx::Class::Schema>, \%expected, [description])

Tests if parent and child has a particular relationship

=over

=item B<parameters>

B<object>: Name of the parent term.

B<subject>: Name of the child term.

B<relationship>: Name of the relationship term.

=back

=item is_obsolete_cvterm(L<DBIx::Class::Schema>, \%expected, [description])

Tests if an existing cvterm is obsolete

=over

=item B<parameters>

B<cv>: Name of the cv.

B<term>: Name of the obsolete term.

=back

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
