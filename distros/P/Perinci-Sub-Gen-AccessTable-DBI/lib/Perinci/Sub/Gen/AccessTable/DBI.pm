package Perinci::Sub::Gen::AccessTable::DBI;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.18'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use Function::Fallback::CoreOrPP qw(clone);
use Locale::TextDomain::UTF8 'Perinci-Sub-Gen-AccessTable-DBI';
use DBI;
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use Perinci::Sub::Util qw(gen_modified_sub);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(gen_read_dbi_table_func);

my $label = "(gen_read_dbi_table_func)";

sub __parse_schema {
    require Data::Sah::Normalize;
    Data::Sah::Normalize::normalize_schema($_[0]);
}

gen_modified_sub(
    output_name => 'gen_read_dbi_table_func',
    install_sub => 0,
    base_name   => 'Perinci::Sub::Gen::AccessTable::gen_read_table_func',
    summary     => 'Generate function (and its metadata) to read DBI table',
    description => <<'_',

The generated function acts like a simple single table SQL SELECT query,
featuring filtering, ordering, and paging, but using arguments as the 'query
language'. The generated function is suitable for exposing a table data from an
API function. Please see Perinci::Sub::Gen::AccessTable's documentation for more
details on what arguments the generated function will accept.

_
    remove_args => ['table_data'],
    add_args    => {
        table_name => {
            req => 1,
            schema => 'str*',
            summary => 'DBI table name',
        },
        dbh => {
            schema => 'obj*',
            summary => 'DBI database handle',
        },
    },
    modify_args => {
        table_spec => sub {
            my $as = shift;
            $as->{description} = <<'_';

Just like Perinci::Sub::Gen::AccessTable's table_spec, except that each field
specification can have a key called `db_field` to specify the database field (if
different). Currently this is required. Future version will be able to generate
table_spec from table schema if table_spec is not specified.

_
        },
    },
    modify_meta => sub {
        my $meta = shift;
        push @{ $meta->{'x.dynamic_generator_modules'} }, __PACKAGE__;
    },
);
sub gen_read_dbi_table_func {
    my %args = @_;

    # XXX schema
    my $table_name = $args{table_name}; delete $args{table_name};
    $table_name or return [400, "Please specify table_name"];
    my $dbh = $args{dbh}; delete $args{dbh};
    $dbh or return [400, "Please specify dbh"];

    # duplicate and make each field's schema normalized
    my $table_spec = clone($args{table_spec});
    for my $fspec (values %{$table_spec->{fields}}) {
        $fspec->{schema} //= 'any';
        $fspec->{schema} = __parse_schema($fspec->{schema});
    }

    my $table_data = sub {
        my $query = shift;

        my ($db) = $dbh->get_info(17);
        unless ($db =~ /\A(SQLite|mysql|Pg)\z/) {
            log_warn("$label Database is not supported: %s", $db);
        }

        # function to quote identifier, e.g. `col` or "col"
        my $qi = sub {
            if ($db =~ /SQLite|mysql/) { return "`$_[0]`" }
            return qq("$_[0]");
        };

        my $fspecs = $table_spec->{fields};
        my @fields = keys %$fspecs;
        my @searchable_fields = grep {
            !defined($fspecs->{$_}{searchable}) || $fspecs->{$_}{searchable}
        } @fields;

        my $filtered;
        my @wheres;
        # XXX case_insensitive_search & word_search not yet observed
        my $q = $query->{query};
        if (defined($q) && @searchable_fields) {
            push @wheres, "(".
                join(" OR ", map {$qi->($fspecs->{$_}{db_field}//$_)." LIKE ".
                                      $dbh->quote("%$q%")}
                         @searchable_fields).
                    ")";
        }
        if ($args{custom_search}) {
            $filtered = 0; # perigen-acctbl will be doing custom_search
        }
        if ($args{custom_filter}) {
            $filtered = 0; # perigen-acctbl will be doing custom_search
        }
        for my $filter (@{$query->{filters}}) {
            my ($f, $ftype, $op, $opn) = @$filter;
            my $qdbf = $qi->($fspecs->{$f}{db_field} // $f);
            my $qopn = $dbh->quote($opn);
            if ($op eq 'truth')     { push @wheres, $qdbf
            } elsif ($op eq '~~')   { $filtered = 0 # not supported
            } elsif ($op eq '!~~')  { $filtered = 0 # not supported
            } elsif ($op eq 'eq')   { push @wheres, "$qdbf = $qopn"
            } elsif ($op eq '==')   { push @wheres, "$qdbf = $qopn"
            } elsif ($op eq 'ne')   { push @wheres, "$qdbf <> $qopn"
            } elsif ($op eq '!=')   { push @wheres, "$qdbf <> $qopn"
            } elsif ($op eq 'ge')   { push @wheres, "$qdbf >= $qopn"
            } elsif ($op eq '>=')   { push @wheres, "$qdbf >= $qopn"
            } elsif ($op eq 'gt')   { push @wheres, "$qdbf > $qopn"
            } elsif ($op eq '>' )   { push @wheres, "$qdbf > $qopn"
            } elsif ($op eq 'le')   { push @wheres, "$qdbf <= $qopn"
            } elsif ($op eq '<=')   { push @wheres, "$qdbf <= $qopn"
            } elsif ($op eq 'lt')   { push @wheres, "$qdbf < $qopn"
            } elsif ($op eq '<' )   { push @wheres, "$qdbf < $qopn"
            } elsif ($op eq '=~')   { $filtered = 0 # not supported
            } elsif ($op eq '!~')   { $filtered = 0 # not supported
            } elsif ($op eq 'pos')  { $filtered = 0 # different substr funcs
            } elsif ($op eq '!pos') { $filtered = 0 # different substr funcs
            } elsif ($op eq 'call') { $filtered = 0 # not supported
            } else {
                die "BUG: Unknown op $op";
            }
        }
        $filtered //= 1;

        my $sorted;
        my @orders;
        if ($query->{random}) {
            push @orders, "RANDOM()";
        } elsif (@{$query->{sorts}}) {
            for my $s (@{$query->{sorts}}) {
                my ($f, $op, $desc) = @$s;
                push @orders, $qi->($fspecs->{$f}{db_field} // $f).
                    ($desc == -1 ? " DESC" : "");
            }
        }
        $sorted //= 1;

        my $paged;
        my $limit = "";
        my ($ql, $qs) = ($query->{result_limit}, $query->{result_start}-1);
        if (defined($ql) || $qs > 0) {
            $limit = join(
                "",
                "LIMIT ".($ql // ($db eq 'Pg' ? "ALL":"999999999")),
                ($qs > 1 ? ($db eq 'mysql' ? ",$qs" : " OFFSET $qs") : "")
            );
        }
        $paged //= 1;

        my $sql = join(
            "",
            "SELECT ",
            join(",", map {$qi->($fspecs->{$_}{db_field}//$_)." AS ".$qi->($_)}
                     @{$query->{requested_fields}}).
                         " FROM ".$qi->($table_name),
            (@wheres ? " WHERE ".join(" AND ", @wheres) : ""),
            (@orders ? " ORDER BY ".join(",", @orders) : ""),
            $limit,
        );
        log_trace("$label SQL=%s", $sql);

        my $sth = $dbh->prepare($sql);
        $sth->execute or die "Can't query: ".$sth->errstr;
        my @r;
        while (my $row = $sth->fetchrow_hashref) { push @r, $row }

        {data=>\@r, paged=>$paged, filtered=>$filtered, sorted=>$sorted,
             fields_selected=>0, # XXX i'm lazy to handle detail=0
         };
    };

    @_ = (%args, table_data => $table_data);
    goto &gen_read_table_func;
}

1;
# ABSTRACT: Generate function (and its metadata) to read DBI table

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Gen::AccessTable::DBI - Generate function (and its metadata) to read DBI table

=head1 VERSION

This document describes version 0.18 of Perinci::Sub::Gen::AccessTable::DBI (from Perl distribution Perinci-Sub-Gen-AccessTable-DBI), released on 2017-07-10.

=head1 SYNOPSIS

Your database table C<countries>:

 | id | eng_name                 | ind_name        |
 |----+--------------------------+-----------------|
 | cn | China                    | Cina            |
 | id | Indonesia                | Indonesia       |
 | sg | Singapore                | Singapura       |
 | us | United States of America | Amerika Serikat |

In list_countries.pl:

 #!perl
 use strict;
 use warnings;
 use Perinci::CmdLine;
 use Perinci::Sub::Gen::AccessTable::DBI qw(gen_read_dbi_table_func);

 our %SPEC;

 my $res = gen_read_dbi_table_func(
     name        => 'list_countries',
     summary     => 'func summary',     # opt
     description => 'func description', # opt
     dbh         => ...,
     table_name  => 'countries',
     table_spec  => {
         summary => 'List of countries',
         fields => {
             id => {
                 schema => 'str*',
                 summary => 'ISO 2-letter code for the country',
                 index => 0,
                 sortable => 1,
             },
             eng_name => {
                 schema => 'str*',
                 summary => 'English name',
                 index => 1,
                 sortable => 1,
             },
             ind_name => {
                 schema => 'str*',
                 summary => 'Indonesian name',
                 index => 2,
                 sortable => 1,
             },
         },
         pk => 'id',
     },
 );
 die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

 Perinci::CmdLine->new(url=>'/main/list_countries')->run;

Now you can do:

 # list all countries, by default only PK field is shown
 $ list_countries.pl --format=text-simple
 cn
 id
 sg
 us

 # show as json, randomize order
 $ list_countries.pl --format=json --random
 ["id","us","sg","cn"]

 # only list countries which contain 'Sin', show all fields (--detail)
 $ list_countries.pl --q=Sin --detail
 .----------------------------.
 | eng_name  | id | ind_name  |
 +-----------+----+-----------+
 | Singapore | sg | Singapura |
 '-----------+----+-----------+

 # show only certain fields, limit number of records, return in YAML format
 $ list_countries.pl --fields '[id, eng_name]' --result-limit 2 --format=yaml
 - 200
 - OK
 -
   - id: cn
     eng_name: China
   - id: id
     eng_name: Indonesia

=head1 DESCRIPTION

This module is just like L<Perinci::Sub::Gen::AccessTable>, except that table
data source is from DBI. gen_read_dbi_table_func() accept mostly the same
arguments as gen_read_table_func(), except: 'table_name' instead of
'table_data', and 'dbh'.

Supported databases: SQLite, MySQL, PostgreSQL.

Early versions tested on: SQLite.

=head1 CAVEATS

It is often not a good idea to expose your database schema directly as API.

=head1 FUNCTIONS


=head2 gen_read_dbi_table_func

Usage:

 gen_read_dbi_table_func(%args) -> [status, msg, result, meta]

Generate function (and its metadata) to read DBI table.

The generated function acts like a simple single table SQL SELECT query,
featuring filtering, ordering, and paging, but using arguments as the 'query
language'. The generated function is suitable for exposing a table data from an
API function. Please see Perinci::Sub::Gen::AccessTable's documentation for more
details on what arguments the generated function will accept.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<case_insensitive_search> => I<bool> (default: 1)

Decide whether generated function will perform case-insensitive search.

=item * B<custom_filters> => I<hash>

Supply custom filters.

A hash of filter name and definitions. Filter name will be used as generated
function's argument and must not clash with other arguments. Filter definition
is a hash containing these keys: I<meta> (hash, argument metadata), I<code>,
I<fields> (array, list of table fields related to this field).

Code will be called for each record to be filtered and will be supplied ($r, $v,
$opts) where $v is the filter value (from the function argument) and $r the
hashref record value. $opts is currently empty. Code should return true if
record satisfies the filter.

=item * B<custom_search> => I<code>

Supply custom searching for generated function.

Code will be supplied ($r, $q, $opts) where $r is the record (hashref), $q is
the search term (from the function argument 'q'), and $opts is {ci=>0|1}. Code
should return true if record matches search term.

=item * B<dbh> => I<obj>

DBI database handle.

=item * B<default_arg_values> => I<hash>

Specify defaults for generated function's arguments.

Can be used to supply default filters, e.g.

 # limit years for credit card expiration date
 { "year.min" => $curyear, "year.max" => $curyear+10, }

=item * B<default_detail> => I<bool>

Supply default 'detail' value for function arg spec.

=item * B<default_fields> => I<str>

Supply default 'fields' value for function arg spec.

=item * B<default_random> => I<bool>

Supply default 'random' value in generated function's metadata.

=item * B<default_result_limit> => I<int>

Supply default 'result_limit' value in generated function's metadata.

=item * B<default_sort> => I<array[str]>

Supply default 'sort' value in generated function's metadata.

=item * B<default_with_field_names> => I<bool>

Supply default 'with_field_names' value in generated function's metadata.

=item * B<description> => I<str>

Generated function's description.

=item * B<detail_aliases> => I<hash>

=item * B<enable_field_selection> => I<bool> (default: 1)

Decide whether generated function will support field selection (the `fields` argument).

=item * B<enable_filtering> => I<bool> (default: 1)

Decide whether generated function will support filtering (the FIELD, FIELD.is, FIELD.min, etc arguments).

=item * B<enable_ordering> => I<bool> (default: 1)

Decide whether generated function will support ordering (the `sort` & `random` arguments).

=item * B<enable_paging> => I<bool> (default: 1)

Decide whether generated function will support paging (the `result_limit` & `result_start` arguments).

=item * B<enable_random_ordering> => I<bool> (default: 1)

Decide whether generated function will support random ordering (the `random` argument).

Ordering must also be enabled (C<enable_ordering>).

=item * B<enable_search> => I<bool> (default: 1)

Decide whether generated function will support searching (argument q).

Filtering must also be enabled (C<enable_filtering>).

=item * B<extra_args> => I<hash>

Extra arguments for the generated function.

=item * B<fields_aliases> => I<hash>

=item * B<hooks> => I<hash>

Supply hooks.

You can instruct the generated function to execute codes in various stages by
using hooks. Currently available hooks are: C<before_parse_query>,
C<after_parse_query>, C<before_fetch_data>, C<after_fetch_data>, C<before_return>.
Hooks will be passed the function arguments as well as one or more additional
ones. All hooks will get C<_stage> (name of stage) and C<_func_res> (function
arguments, but as hash reference so you can modify it). C<after_parse_query> and
later hooks will also get C<_parse_res> (parse result). C<before_fetch_data> and
later will also get C<_query>. C<after_fetch_data> and later will also get
C<_data>. C<before_return> will also get C<_func_res> (the enveloped response to be
returned to user).

Hook should return nothing or a false value on success. It can abort execution
of the generated function if it returns an envelope response (an array). On that
case, the function will return with this return value.

=item * B<install> => I<bool> (default: 1)

Whether to install generated function (and metadata).

By default, generated function will be installed to the specified (or caller's)
package, as well as its generated metadata into %SPEC. Set this argument to
false to skip installing.

=item * B<langs> => I<array[str]> (default: ["en_US"])

Choose language for function metadata.

This function can generate metadata containing text from one or more languages.
For example if you set 'langs' to ['en_US', 'id_ID'] then the generated function
metadata might look something like this:

 {
     v => 1.1,
     args => {
         random => {
             summary => 'Random order of results', # English
             "summary.alt.lang.id_ID" => "Acak urutan hasil", # Indonesian
             ...
         },
         ...
     },
     ...
 }

=item * B<name> => I<str>

Generated function's name, e.g. `myfunc`.

=item * B<package> => I<str>

Generated function's package, e.g. `My::Package`.

This is needed mostly for installing the function. You usually don't need to
supply this if you set C<install> to false.

If not specified, caller's package will be used by default.

=item * B<query_aliases> => I<hash>

=item * B<random_aliases> => I<hash>

=item * B<result_limit_aliases> => I<hash>

=item * B<result_start_aliases> => I<hash>

=item * B<sort_aliases> => I<hash>

=item * B<summary> => I<str>

Generated function's summary.

=item * B<table_name>* => I<str>

DBI table name.

=item * B<table_spec>* => I<hash>

Table specification.

Just like Perinci::Sub::Gen::AccessTable's table_spec, except that each field
specification can have a key called C<db_field> to specify the database field (if
different). Currently this is required. Future version will be able to generate
table_spec from table schema if table_spec is not specified.

=item * B<with_field_names_aliases> => I<hash>

=item * B<word_search> => I<bool> (default: 0)

Decide whether generated function will perform word searching instead of string searching.

For example, if search term is 'pine' and field value is 'green pineapple',
search will match if word_search=false, but won't match under word_search.

This will not have effect under 'custom_search'.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: A hash containing generated function, metadata (hash)

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Gen-AccessTable-DBI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Gen-AccessTable-DBI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Gen-AccessTable-DBI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Sub::Gen::AccessTable>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
