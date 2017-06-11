package Test::DBIx::Class::Schema;

{
  $Test::DBIx::Class::Schema::DIST = 'Test-DBIx-Class-Schema';
}
$Test::DBIx::Class::Schema::VERSION = '1.0.11';
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

# ensure we have "done_testing"
# we also want to be sure we're using the recent enough version to fix a bug
# in the output (https://github.com/chiselwright/test-dbix-class-schema/issues/12)
use Test::More 1.302015;

sub new {
    my ($proto, $options) = @_;
    my $self = (defined $options) ? $options : {};
    bless $self, ref($proto) || $proto;
    return $self;
}

# for populating the correct part of $self
sub methods {
    my ($self, $hashref) = @_;

    $self->{methods} = $hashref;

    return;
}

sub run_tests {
    my ($self) = @_;
    my ($schema, $rs, $record);

    # make sure we can use the schema (namespace) module
    use_ok( $self->{namespace} );

    # let users pass in an existing $schema if they (somehow) have one
    if (defined $self->{schema}) {
        $schema = $self->{schema};
    }
    else {
        # get a schema to query
        $schema = $self->{namespace}->connect(
            $self->{dsn},
            $self->{username},
            $self->{password},
        );
    }
    isa_ok($schema, $self->{namespace});

    # create a new resultset object and perform tests on it
    # - this allows us to test ->my_column() without requiring data
    $rs = $schema->resultset( $self->{moniker} );
    $record = $schema->resultset( $self->{moniker} )->new_result({});

    # make sure our record presents itself as the correct object type
    if (defined $self->{glue}) {
        isa_ok(
            $record,
                $self->{namespace}
            . '::' . $self->{glue}
            . '::' . $self->{moniker}
        );
    }
    else {
        # It looks like the namespace has changed with newer record objects so
        # that they don't get ::Schema in their name.
        # So that wew can work with either we now want our record to be the
        # namespace+moniker with an option '::Schema' in the name.
        # This means moving away from isa_ok() to like() on a ref()
        my $expected_type_re = $self->{namespace} . '::' . $self->{moniker};
           $expected_type_re =~ s{::Schema}{(?:::Schema)?};
        my $regexp = qr{$expected_type_re};
        like(ref($record), $regexp, "The record object is a ::$self->{moniker}");
    }

    $self->_test_normal_methods($rs);
    $self->_test_special_methods($record);
    $self->_test_resultset_methods($rs);
    $self->_test_unexpected_normal_methods($rs);

    # TODO: test custom, resultsets

    my $ctx = Test::More->builder->ctx;
    my $tb2_already_done_testing =
        defined $ctx->snapshot->hub->meta('Test::Builder')->{Done_Testing};
    $ctx->release;
    done_testing
        unless ($tb2_already_done_testing || $ENV{TEST_AGGREGATE});
}

sub _test_normal_methods {
    my $self    = shift;
    my $rs  = shift;

    my @std_method_types        = qw(columns relations);

    # 'normal' methods; row & relation
    # we can try calling these as they gave no side-effects
    my @proxied;
    foreach my $method_type (@std_method_types) {
        SKIP: {
            if (not @{ $self->{methods}{$method_type} }) {
                skip qq{no $method_type methods}, 1;
            }

            # try calling each method
            METHOD: foreach my $method ( @{ $self->{methods}{$method_type} } ) {
                # make sure we can call the method
                my $source = $rs->result_source;
                my $related_source;

                # 'normal' relationship
                if ($source->has_relationship($method)) {
                    eval {
                        $related_source = $source->related_source($method);
                    };
                    is($@, q{}, qq{related source for '$method' exists});

                    # test self.* and foreign.* columns are valid
                    my $cond_ref = $source->relationship_info($method)->{cond};
                    $cond_ref = ref $cond_ref eq 'ARRAY' ? $cond_ref : [ $cond_ref ];
                    COND: foreach my $cond ( @$cond_ref ) {
                        # you can have CODE as the cond_ref - that's unexpected!
                        TODO: {
                            if ('CODE' eq ref($cond)) {
                                local $TODO = qq{skipping column tests for CODE defined condition};
                                fail(qq{test '$method' with CODE definition});
                                next COND;
                            }
                        }
                        foreach my $foreign_col (keys %{$cond} ) {
                            my $self_col = $cond->{$foreign_col};
                            s{^\w+\.}{} for ( $self_col, $foreign_col );
                            eval {
                                $source->resultset->slice(0,0)->get_column($self_col)->all;
                            };
                            is($@, q{}, qq{self.$self_col valid for '$method' relationship});
                            eval {
                                $related_source->resultset->slice(0,0)->get_column($foreign_col)->all;
                            };
                            is($@, q{}, qq{foreign.$foreign_col valid for '$method' relationship});
                        }
                    }
                }

                # many_to_many and proxy
                elsif ( $method_type eq 'relations' ) {
                    # TODO: Factor this out with the same code under proxied
                    # 'columns' accessors
                    RELATIONSHIP:
                    for my $relationship ( $source->relationships ) {
                        my $proxy = $source->relationship_info($relationship)->{attrs}{proxy};
                        next RELATIONSHIP if not $proxy;
                        if ( grep m{$method}, @$proxy ) {
                            pass qq{'$method' relationship exists via proxied relationship '$relationship'};
                            next METHOD;
                        }
                    }
                    my $result = $rs->new({});
                    # many_to_many
                    if ( $result->can($method)
                     and $result->$method->isa('DBIx::Class::ResultSet') ) {
                        pass("'$method' relation is a many-to-many");
                    }
                    else {
                        fail("'$method' is not a valid relationship" );
                    }
                }

                # column accessor
                elsif ( $method_type eq 'columns' ) {
                    if ( $source->has_column($method) ) {
                        pass qq{'$method' column defined in result_source};
                        eval {
                            # https://rt.cpan.org/Ticket/Display.html?id=65521
                            my $col = $rs->slice(0,0)->get_column($method)->all;
                        };
                        is($@, q{}, qq{'$method' column exists in database});
                        next METHOD;
                    }
                    # Proxied columns
                    RELATIONSHIP:
                    for my $relationship ( $source->relationships ) {
                        my $proxy = $source->relationship_info($relationship)->{attrs}{proxy};
                        next RELATIONSHIP if not $proxy;
                        if ( grep m{$method}, @$proxy ) {
                            pass(qq{'$method' column exists via proxied relationship '$relationship'});
                            next METHOD;
                        }
                    }
                    fail qq{'$method' column does not exist and is not proxied};
                }
                # ... erm ... what's this?
                else {
                    die qq{unknown method type: $method_type};
                }
            }
        }
    } # foreach
    return;
}

sub _test_special_methods {
    shift->_test_methods(shift, [qw/custom/]);
}

sub _test_resultset_methods {
    shift->_test_methods(shift, [qw/resultsets/]);
}

sub _test_methods {
    my $self            = shift;
    my $thingy          = shift;
    my $method_types    = shift;

    # 'special' methods; custom
    # we can't call these as they may have unknown parameters,
    # side effects, etc
    foreach my $method_type (@{ $method_types} ) {
        SKIP: {
            skip qq{no $method_type methods}, 1
                    unless 
                        exists     $self->{methods}{$method_type}
                           and  @{ $self->{methods}{$method_type} };
            ok(
                @{ $self->{methods}{$method_type} },
                qq{$method_type list found for testing}
            );
        }

        # call can on each method to make it obvious what's being tested
        foreach my $method (@{ $self->{methods}{$method_type} } ) {
            can_ok( $thingy, $method );
        }
    } # foreach
    return;
}

sub _test_unexpected_normal_methods {
    my($self,$rs) = @_;
    my $source    = $rs->result_source;

    my $set = {
        'columns'   => [ $source->columns ],
        'relations' => [ $source->relationships ],
    };

    foreach my $method_type (sort keys %{$set}) {
        my @diff = $self->_diff_arrays(
            $self->{methods}->{$method_type},
            $set->{$method_type},
        );

        my $plural = (scalar @diff == 1) ? '' : 's';
        my $message =
            qq{'$method_type' method${plural} defined in }
            . $self->{moniker}
            . ' but untested: '
            . join(', ',@diff);

        if ($self->{test_missing}) {
            is_deeply(
                \@diff,
                [],
                "All known $method_type method${plural} defined in test"
            ) || diag $message;
        }
        else {
            if (scalar @diff) {
               diag $message;
            }
        }
    }
}

sub _diff_arrays {
    my($self,$min,$full) = @_;
    my @min = @{$min};
    my @full = @{$full};

    my %mapped = map{ $_ => 1 } @min;
    my @diff = grep (!defined $mapped{$_}, @full);

    if (wantarray) {
        return @diff;
    }
    return \@diff;
}


1;
# ABSTRACT: DBIx::Class schema sanity checking tests

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBIx::Class::Schema - DBIx::Class schema sanity checking tests

=head1 VERSION

version 1.0.11

=head1 SYNOPSIS

Create a test script that looks like this:

    #!/usr/bin/perl
    # vim: ts=8 sts=4 et sw=4 sr sta
    use strict;
    use warnings;

    # load the module that provides all of the common test functionality
    use Test::DBIx::Class::Schema;

    # create a new test object
    my $schematest = Test::DBIx::Class::Schema->new(
        {
            # required
            dsn       => 'dbi:Pg:dbname=mydb', # or use schema option
            namespace => 'MyDB::Schema',
            moniker   => 'SomeTable',
            # optional
            username  => 'some_user',
            password  => 'opensesame',
            glue      => 'Result',             # fix class name if needed
            # rather than calling diag will test that all columns/relationships
            # are accounted for in your test and fail the test if not
            test_missing => 1,
        }
    );

    # tell it what to test
    $schematest->methods(
        {
            columns => [
                qw[
                    id
                    column1
                    column2
                    columnX
                    foo_id
                ]
            ],

            relations => [
                qw[
                    foo
                ]
            ],

            custom => [
                qw[
                    some_method
                ]
            ],

            resultsets => [
                qw[
                ]
            ],
        }
    );

    # run the tests
    $schematest->run_tests();

Run the test script:

  prove -l t/schematest/xx.mydb.t

=head2 Options

Either C<dsn> (eg C<dbi:Pg:dbname=mydb>) or C<schema> (an already
created schema object) must be set.

If the database requires credentials, set C<username> and C<password>.

C<namespace>, C<glue> and C<moniker> define the class being tested.
For example, if your class is C<MyDB::Schema::Result::SomeTable> then use:

  namespace => 'MyDB::Schema',
  glue      => 'Result,
  moniker   => 'SomeTable',

C<glue> is not required if the combination of C<namespace> and C<moniker>
is enough to define the class, e.g. C<MyDB::Schema::SomeTable>.

=head2 done_testing

Under normal circumstances there is no need to add C<done_testing> to your
test script; it's automatically called at the end of C<run_tests()> I<unless>
you are running tests under L<Test::Aggregate>.

If you are running aggregated tests you will need to add

  done_testing;

to your top-level script.

=head1 DESCRIPTION

It's really useful to be able to test and confirm that DBIC classes have and
support a known set of methods.

Testing these one-by-one is more than tedious and likely to discourage you
from writing the relevant test scripts.

As a lazy person myself I don't want to write numerous near-identical scripts.

Test::DBIx::Class::Schema takes the copy-and-paste out of DBIC schema class testing.

=head1 SEE ALSO

L<DBIx::Class>,
L<Test::More>,
L<Test::Aggregate>

=begin markdown

## BUILD STATUS

### master

[![Build status](https://badge.buildkite.com/c8793ab59e31d982dd759cadfb66a308d5278f21cb707d8822.svg?branch=master)](https://buildkite.com/chizography/test-dbix-class-schema)

=end markdown

=head1 AUTHOR

Chisel Wright <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Darius Jokilehto Dave Cross Jason Tang Rupert Lane simbabque

=over 4

=item *

Darius Jokilehto <darius.jokilehto@net-a-porter.com>

=item *

Dave Cross <davidc@broadbean.com>

=item *

Jason Tang <tang.jason.ch@gmail.com>

=item *

Rupert Lane <rupert@rupert-lane.org>

=item *

simbabque <simbabque@cpan.org>

=back

=cut
