package Perinci::Sub::Property::result::table;

our $DATE = '2016-05-12'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Locale::TextDomain::UTF8 'Perinci-Sub-Property-result-table';
use Perinci::Object::Metadata;
use Perinci::Sub::PropertyUtil qw(declare_property);

declare_property(
    name => 'result/table',
    type => 'function',
    schema => ['hash*'],
    wrapper => {
        meta => {
            v       => 2,
            prio    => 50,
        },
        handler => sub {
            my ($self, %args) = @_;
            my $v    = $args{new} // $args{value} // {};
            my $meta = $args{meta};

            # add format_options
            {
                last if $meta->{result_naked};
                $self->select_section('after_call_after_res_validation');
                $self->push_lines('# add format_options from result/table hints');
                $self->push_lines('{');
                $self->indent;
                $self->push_lines(
                    # we are in a local block, so no need to use _w_ prefixes
                    # for vars or even use add_var()
                    'last unless ref($_w_res->[2]) eq "ARRAY";',
                    'my $firstrow = $_w_res->[2][0] or last;', # deduce type from first row
                    'my $tablespec = '.$self->{_args}{meta_name}.'->{result}{table}{spec} or last;',
                    'my $tct = {};',
                    'my $tco;',
                    'if (ref($firstrow) eq "ARRAY" && $_w_res->[3]{"table.fields"}) {',
                    '    my $field_names = $_w_res->[3]{"table.fields"};', # map column\d to field names
                    '    for (0..@$field_names-1) {',
                    '        next if defined($tct->{$_});',
                    '        my $sch = $tablespec->{fields}{$field_names->[$_]}{schema} or next;', # field is unknown in table spec
                    '        my $type = ref($sch) eq "ARRAY" ? $sch->[0] : $sch;',
                    '        $type =~ s/\\*$//;',
                    '        $tct->{"column$_"} = $type;',
                    '    }',
                    '} elsif (ref($firstrow) eq "HASH") {',
                    '    my $fields = [keys %$firstrow];', # XXX should we check from several/all rows to collect more complete keys?
                    '    $tco = [sort {($tablespec->{fields}{$a}{pos} // $tablespec->{fields}{$a}{index} // 9999) <=> ($tablespec->{fields}{$b}{pos} // $tablespec->{fields}{$b}{index} // 9999)} @$fields];',
                    '    for (@$fields) {',
                    '        my $sch = $tablespec->{fields}{$_}{schema} or next;', # field is unknown in table spec
                    '        my $type = ref($sch) eq "ARRAY" ? $sch->[0] : $sch;',
                    '        $type =~ s/\\*$//;',
                    '        $tct->{$_} = $type;',
                    '    }',
                    '} else {',
                    '    last;',
                    '}',
                    'my $rfo = {};',
                    '$rfo->{table_column_types}  = [$tct] if $tct;',
                    '$_w_res->[3]{"table.fields"} = $tco;',
                );
                $self->unindent;
                $self->push_lines('}');
            }

            # TODO validate table data, if requested
        },
    },
    cmdline_help => {
        meta => {
            prio => 50,
        },
        handler => sub {
            my ($self, $r) = @_;
            my $meta = $r->{_help_meta};
            my $table_spec = $meta->{result}{table}{spec}
                or return undef;
            my $text = __("Returns table data. Table fields are as follow:");
            $text .= "\n\n";
            my $ff = $table_spec->{fields};
            # reminder: index property is for older spec, will be removed
            # someday
            for my $fn (sort {($ff->{$a}{pos}//$ff->{$a}{index}//0) <=>
                                  ($ff->{$b}{pos}//$ff->{$b}{index}//0)}
                            keys %$ff) {
                my $f  = $ff->{$fn};
                my $fo = Perinci::Object::Metadata->new($f);
                my $sum = $fo->langprop("summary");
                my $type;
                if ($f->{schema}) {
                    $type = ref($f->{schema}) eq 'ARRAY' ?
                                    $f->{schema}[0] : $f->{schema};
                    $type =~ s/\*$//;
                }
                $text .=
                    join("",
                         "  - *$fn*",
                         ($type ? " ($type)" : ""),
                         $table_spec->{pk} eq $fn ?
                             " (".__x("ID field").")":"",
                         $sum ? ": $sum" : "",
                         "\n\n");
                my $desc = $fo->langprop("description");
                if ($desc) {
                    $desc =~ s/(\r?\n)+\z//;
                    $desc =~ s/^/    /mg;
                    $text .= "$desc\n\n";
                }
            }
            $text;
        },
    }, # cmdline_help
);


1;
# ABSTRACT: Specify table data in result

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::result::table - Specify table data in result

=head1 VERSION

This document describes version 0.09 of Perinci::Sub::Property::result::table (from Perl distribution Perinci-Sub-Property-result-table), released on 2016-05-12.

=head1 SYNOPSIS

In function L<Rinci> metadata:

 result => {
     table => {
         spec => {
             summary => "Employee's' current salary",
             fields  => {
                 name => {
                     summary => "Employee's name",
                     schema  => 'str*',
                     pos     => 0,
                 },
                 position => {
                     summary => "Employee's current position",
                     schema  => 'str*',
                     pos     => 1,
                 },
                 salary => {
                     summary => "Employee's current monthly salary",
                     schema  => 'float*',
                     pos     => 2,
                 },
             },
             pk => 'name',
         },
         # allow_extra_fields => 0,
         # allow_underscore_fields => 0,
     },
     ...
 }

=head1 DESCRIPTION

If your function returns table data, either in the form of array (single-column
rows):

 ["andi", "budi", "cinta", ...]

or array of arrays (CSV-like):

 [
   ["andi" , "manager", 12_000_000],
   ["budi" , "staff", 5_000_000],
   ["cinta", "junior manager", 7_500_000],
   # ...
 ]

or array of hashes (with field names):

 [
   {name=>"andi" , position=>"manager", salary=>12_000_000},
   {name=>"budi" , position=>"staff", salary=> 5_000_000},
   {name=>"cinta", position=>"junior manager", salary=> 7_500_000},
   # ...
 ]

then you might want to add a C<table> property inside your C<result> property of
your function metadata. This module offers several things:

=over

=item *

When your function is run under L<Perinci::CmdLine>, your tables will look
prettier. This is done via adding C<table.fields> attribute to your function
result metadata, giving hints to the L<Data::Format::Pretty> formatter.

Also when you use --help (--verbose), the table structure is described in the
Result section.

=item *

(NOT YET IMPLEMENTED) When you generate documentation, the table specification
is also included in the documentation.

=item *

(NOT YET IMPLEMENTED, IDEA) The user can also perhaps request the table
specification, e.g. C<yourfunc --help=result-table-spec>, C<yourfunc
--result-table-spec>.

=item *

(NOT YET IMPLEMENTED) The wrapper code can optionally validate your function
result, making sure that your resulting table conforms to the table
specification.

=item *

(NOT YET IMPLEMENTED, IDEA) The wrapper code can optionally filter, summarize,
or sort the table on the fly before returning the final result to the user.

(Alternatively, you can pipe the output to another tool like B<jq>, just like a
la Unix toolbox philosophy).

=back

=head1 SPECIFICATION

The value of the C<table> property should be a L<DefHash>. Known properties:

=over

=item * spec => DEFHASH

Required. Table data specification, specified using L<TableDef>.

=item * allow_extra_fields => BOOL (default: 0)

Whether to allow the function to return extra fields other than the ones
specified in C<spec>. This is only relevant when function returns array of
hashes (i.e. when the field names are present). And this is only relevant when
validating the table data.

=item * allow_underscore_fields => BOOL (default: 0)

Like C<allow_extra_fields>, but regulates whether to allow any extra fields
prefixed by an underscore. Underscore-prefixed keys is the DefHash's convention
of extra keys that can be ignored.

=back

=head1 NOTES

If you return an array or array of arrays (i.e. no field names), you might want
to add C<table.fields> result metadata so the wrapper code can know which
element belongs to which field. Example:

 my $table = [];
 push @$table, ["andi", 1];
 push @$table, ["budi", 2];
 return [200, "OK", $table, {"table.fields"=>[qw/name id/]}];

This is not needed if you return array of hashes, since the field names are
present as hash keys:

 my $table = [];
 push @$table, {name=>"andi", id=>1};
 push @$table, {name=>"budi", id=>2};
 return [200, "OK", $table];

=head1 RESULT METADATA

=over

=item * attribute: table.fields => ARRAY OF STR

=back

=head1 FAQ

=head2 Why not use the C<schema> property in the C<result> property?

That is, in your function metadata:

 result => {
     schema => ['array*', of => ['hash*' => keys => {
         name => 'str*',
         position => 'str',
         salary => ['float*', min => 0],
         ...
     }]],
 },

First of all, table data can come in several forms, either a 1-dimensional
array, an array of arrays, or an array of hashes. Moreover, when returning an
array of arrays, the order of fields can sometimes be changed. The above schema
will become more complex if it has to handle all those cases.

With the C<table> property, the intent becomes clearer that we want to return
table data. We can also specify more aspects aside from just the schema.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-result-table>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-result-table>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-result-table>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
