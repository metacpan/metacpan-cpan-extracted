package Perinci::Sub::Property::result::object;

our $DATE = '2016-05-11'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Locale::TextDomain::UTF8 'Perinci-Sub-Property-result-object';
use Perinci::Object::Metadata;
use Perinci::Sub::PropertyUtil qw(declare_property);

declare_property(
    name => 'result/object',
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

            # TODO validate object/hash data, if requested
        },
    },
    cmdline_help => {
        meta => {
            prio => 50,
        },
        handler => sub {
            my ($self, $r) = @_;
            my $meta = $r->{_help_meta};
            my $obj_spec = $meta->{result}{object}{spec}
                or return undef;
            my $text = __("Returns object/hash. Fields are as follow:");
            $text .= "\n\n";
            my $ff = $obj_spec->{fields};
            for my $fn (sort keys %$ff) {
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
# ABSTRACT: Specify object data in result

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Property::result::object - Specify object data in result

=head1 VERSION

This document describes version 0.05 of Perinci::Sub::Property::result::object (from Perl distribution Perinci-Sub-Property-result-object), released on 2016-05-11.

=head1 SYNOPSIS

In function L<Rinci> metadata:

 result => {
     object => {
         spec => {
             summary => "Account information",
             fields  => {
                 id => {
                     summary => "Account ID",
                     schema  => ['int*', {min=>1000}],
                     req     => 1,
                 },
                 name => {
                     summary => "Account name",
                     schema  => 'str*',
                     req     => 1,
                 },
                 account => {
                     summary => "Alias for name, for backward-compat",
                     schema  => "str*",
                 },
                 plan => {
                     summary => "Account's plan name",
                     schema  => 'str*',
                 },
                 is_disabled => {
                     summary => "Whether the account is disabled",
                     schema  => 'bool*',
                 },
                 disk_usage => {
                     summary => "Current disk usage, in MB",
                     schema  => 'float',
                 },
                 bw_usage => {
                     summary => "Current month's data transfer, in GB",
                     schema  => 'float',
                 },
             },
         },
         # allow_extra_fields => 0,
         # allow_underscore_fields => 0,
     },
     ...
 }

=head1 DESCRIPTION

This property is similar to L<Perinci::Sub::Property::result::table> except that
it describes a single row (or object a la JavaScript object, or a hash):

 {
     id          => 1001,
     name        => "steven",
     account     => "steven",
     plan        => "BIZ A",
     is_disabled => 0,
     disk_usage  => 3788,
     bw_usage    => 120,
 }

This module offers several things:

=over

=item *

(NOT YET IMPLEMENTED) When you generate documentation, the object specification
is also included in the documentation.

(NOT YET IMPLEMENTED, IDEA) The user can also perhaps request the object
specification, e.g. C<yourfunc --help=result-object-spec>, C<yourfunc
--result-object-spec>.

=item *

(NOT YET IMPLEMENTED) The wrapper code can optionally validate your function
result, making sure that your resulting object/hash conforms to the
specification.

=back

=head1 SPECIFICATION

The value of the C<object> property should be a L<DefHash>. Known properties:

=over

=item * spec => DEFHASH

Required. Object data specification, currently follows L<TableDef> except that
the <pos> property is not used.

=item * allow_extra_fields => BOOL (default: 0)

Whether to allow the function to return extra fields other than the ones
specified in C<spec>.

=item * allow_underscore_fields => BOOL (default: 0)

Like C<allow_extra_fields>, but regulates whether to allow any extra fields
prefixed by an underscore. Underscore-prefixed keys

=back

=head1 FAQ

=head2 Why not use the C<schema> property in the C<result> property?

That is, in your function metadata:

 result => {
     schema => ['hash*', keys => {
         id          => 'int*',
         name        => 'str*',
         account     => 'str*',
         plan        => 'str*',
         id_disabled => 'bool*',
         disk_usage  => 'float',
         bw_usage    => 'float',
     },
     req_keys => [qw/id name plan/]],
 },

Actually you can. But with the C<object> result property, the intent becomes
clearer that we want to return object/hash. And this module provides the hooks
for generating documentation.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Property-result-object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Property-result-object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Property-result-object>

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
