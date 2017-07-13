package Software::Release::Watch;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use Log::ger;
use Moo;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use Software::Catalog;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       list_software
                       list_software_releases
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Watch latest software releases',
};

has mech => (
    is => 'rw',
    default => sub {
        require WWW::Mechanize;

        # to do automatic retry, pass a WWW::Mechanize::Pluggable object with
        # WWW::Mechanize::Plugin::Retry.

        WWW::Mechanize->new(autocheck=>0);
    },
);

sub get_url {
    my ($self, $url) = @_;

    my $resp = $self->mech->get($url);
    unless ($resp->is_success) {
        # 404 is permanent, otherwise we assume temporary error
        die [$resp->code == 404 ? 542 : 541,
             "Failed retrieving URL", undef,
             {
                 network_status  => $resp->code,
                 network_message => $resp->message,
                 url => $url,
             }];
    }
    $resp;
}

my $table_spec = {
    fields => {
        id => {
            index      => 0,
            schema     => ['str*' => {
                match => $Software::Catalog::swid_re,
            }],
            searchable => 1,
        },
    },
    pk => 'id',
};

my $res = gen_read_table_func(
    name => 'list_software',
    table_data => sub {
        require Module::List;

        my $query = shift;
        state $res = do {
            my $mods = Module::List::list_modules(
                "Software::Release::Watch::sw::", {list_modules=>1});
            $mods = [map {[[s/.+:://, $_]->[-1]]} keys %$mods];
            {data=>$mods, paged=>0, filtered=>0, sorted=>0, fields_selected=>0};
        };
        $res;
    },
    table_spec => $table_spec,
    langs => ['en_US'],
);
die "BUG: Can't generate func: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

$SPEC{list_software_releases} = {
    v => 1.1,
    summary => 'List software releases',
    description => <<'_',

Statuses:

* 541 - transient network failure
* 542 - permanent network failure (e.g. server returns 404 page)
* 543 - parsing failure (permanent)

_
    args => {
        software_id => {
            schema => ["str*", {
                match => $Software::Catalog::swid_re,
            }],
            req => 1,
            pos => 0,
        },
    },
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub list_software_releases {
    my %args = @_; no warnings ('void');my $arg_err; if (exists($args{'software_id'})) { ((defined($args{'software_id'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($args{'software_id'})) ? 1 : (($arg_err //= "Not of type text"),0)) && (($args{'software_id'} =~ qr((?:(?-)\A[a-z]([a-z0-9_])*\z))) ? 1 : (($arg_err //= "Must match regex pattern qr(\\A[a-z]([a-z0-9_])*\\z)"),0)); if ($arg_err) { return [400, "Invalid argument value for software_id: $arg_err"] } }if (!exists($args{'software_id'})) { return [400, "Missing argument: software_id"] } # VALIDATE_ARGS
    my $swid = $args{software_id};

    my $res;

    $res = Software::Catalog::get_software_info(id => $swid);
    return $res unless $res->[0] == 200;

    my $mod = __PACKAGE__ . "::SW::$swid";
    my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
    eval { require $mod_pm };
    return [500, "Can't load $mod: $@"] if $@;

    my $obj = $mod->new(watcher => __PACKAGE__->new);

    $res = eval { $obj->list_releases };
    my $err = $@;

    if ($err) {
        if (ref($err) eq 'ARRAY') {
            return $err;
        } else {
            return [500, "Died: $err"];
        }
    } else {
        return [200, "OK", $res];
    }
}

1;
# ABSTRACT: Watch latest software releases

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Release::Watch - Watch latest software releases

=head1 VERSION

This document describes version 0.05 of Software::Release::Watch (from Perl distribution Software-Release-Watch), released on 2017-07-10.

=head1 SYNOPSIS

 use Software::Release::Watch qw(
     list_software
     list_software_releases
 );

 my $res;
 $res = list_software();
 $res = list_software_releases(software_id=>'wordpress');

=for Pod::Coverage get_url mech

=head1 FUNCTIONS


=head2 list_software

Usage:

 list_software(%args) -> [status, msg, result, meta]

REPLACE ME.

REPLACE ME

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<id> => I<str>

Only return records where the 'id' field equals specified value.

=item * B<id.contains> => I<str>

Only return records where the 'id' field contains specified text.

=item * B<id.in> => I<array[str]>

Only return records where the 'id' field is in the specified values.

=item * B<id.is> => I<str>

Only return records where the 'id' field equals specified value.

=item * B<id.isnt> => I<str>

Only return records where the 'id' field does not equal specified value.

=item * B<id.max> => I<str>

Only return records where the 'id' field is less than or equal to specified value.

=item * B<id.min> => I<str>

Only return records where the 'id' field is greater than or equal to specified value.

=item * B<id.not_contains> => I<str>

Only return records where the 'id' field does not contain specified text.

=item * B<id.not_in> => I<array[str]>

Only return records where the 'id' field is not in the specified values.

=item * B<id.xmax> => I<str>

Only return records where the 'id' field is less than specified value.

=item * B<id.xmin> => I<str>

Only return records where the 'id' field is greater than specified value.

=item * B<query> => I<str>

Search.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_software_releases

Usage:

 list_software_releases(%args) -> [status, msg, result, meta]

List software releases.

Statuses:

=over

=item * 541 - transient network failure

=item * 542 - permanent network failure (e.g. server returns 404 page)

=item * 543 - parsing failure (permanent)

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<software_id>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Release-Watch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Release-Watch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Release-Watch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Software::Catalog>

C<Software::Release::Watch::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
