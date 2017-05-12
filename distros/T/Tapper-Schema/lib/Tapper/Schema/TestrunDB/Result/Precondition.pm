package Tapper::Schema::TestrunDB::Result::Precondition;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::Precondition::VERSION = '5.0.9';
# ABSTRACT: Tapper - Containing Preconditions for Testruns

use strict;
use warnings;

use parent 'DBIx::Class';
use YAML::Syck;

__PACKAGE__->load_components("Core");
__PACKAGE__->table("precondition");
__PACKAGE__->add_columns
    (
     "id",                              { data_type => "INT",      default_value => undef, is_nullable => 0, size => 11, is_auto_increment => 1, },
     "shortname",                       { data_type => "VARCHAR",  default_value => "",    is_nullable => 0, size => 255,                        },
     "precondition",                    { data_type => "TEXT",     default_value => undef, is_nullable => 1,                                     },
     "timeout",                         { data_type => "INT",      default_value => undef, is_nullable => 1, size => 10,                         },
    );

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many     ( child_pre_precondition      => 'Tapper::Schema::TestrunDB::Result::PrePrecondition',     { 'foreign.parent_precondition_id' => 'self.id' });
__PACKAGE__->many_to_many ( child_preconditions         => 'child_pre_precondition',                                  'child' );

__PACKAGE__->has_many     ( parent_pre_precondition     => 'Tapper::Schema::TestrunDB::Result::PrePrecondition',     { 'foreign.child_precondition_id' => 'self.id' });
__PACKAGE__->many_to_many ( parent_preconditions        => 'parent_pre_precondition',                                 'parent' );

__PACKAGE__->has_many     ( testrun_precondition        => 'Tapper::Schema::TestrunDB::Result::TestrunPrecondition', { 'foreign.precondition_id'       => 'self.id' },  { 'join_type' => 'INNER' });
__PACKAGE__->many_to_many ( parent_testruns             => 'testrun_precondition',                                    'testrun' );

1;

# -------------------- methods in results --------------------


sub one_line {
        my ($str) = @_;

        $str =~ s/\\/\\\\/msg;
        $str =~ s/\n/\\n/msg;
        $str;
}


sub quote {
        my ($str) = @_;

        my $d = Data::Dumper->new([$str])->Terse(1)->Indent(0);
        $d->Dump;
}


sub quote_and_one_line {
        my ($str) = @_;

        $str = quote($str);
        $str =~ s/\n/\\n/msg;
        $str;
}


sub to_string
{
        my ($self, $opt) = @_;

        my $str = '';
        foreach (@{$self->result_source->{_ordered_columns} })
        {
                my $val = $self->$_;
                if (defined $val)
                {
                        if ( $opt->{quotevalues} && $opt->{nonewlines} ) {
                                $val = quote_and_one_line($val);
                        } else {
                                $val    = quote($val)    if $opt->{quotevalues};
                                $val    = one_line($val) if $opt->{nonewlines};
                        }
                } else
                {
                        $val = $Tapper::Schema::TestrunDB::NULL;
                }
                $str   .= $val . $Tapper::Schema::TestrunDB::DELIM;
        }
        return $str;
}


sub precondition_as_hash {
        Load(shift->precondition);
}


sub update_content {
        my ($self, $condition) = @_;

        my $yaml_error = Tapper::Schema::TestrunDB::_yaml_ok($condition);
        die Tapper::Exception::Param->new($yaml_error) if $yaml_error;

        my @a_conditions = Load($condition);
        if ( scalar @a_conditions > 1 ) {
            say {*STDERR} 'cannot update a single precondition with a set of preconditions';
            return;
        }

        my $cond_hash = $a_conditions[0];
        $self->shortname( $cond_hash->{shortname} ) if $cond_hash->{shortname};
        $self->precondition( $condition );
        $self->timeout( $cond_hash->{timeout} ) if $cond_hash->{timeout};

        if ( $self->update ) {
            return $self->id;
        }
        else {
            say {*STDERR} 'update precondition failed: ' . $self->id;
            return;
        }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::Precondition - Tapper - Containing Preconditions for Testruns

=head2 one_line

Make a string with newlines to one line inserting C<\n>.

=head2 quote

Quote a string according to Perl eval rules.

=head2 quote_and_one_line

Combine C<quote> and C<one_line>.

=head2 to_string

Return printable representation.

=head2 precondition_as_hash

Provide the precondition YAML as actual data structure.

=head2 update_content

Update precondition from given params.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
