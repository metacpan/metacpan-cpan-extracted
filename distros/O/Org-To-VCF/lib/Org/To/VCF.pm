package Org::To::VCF;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use Log::Any::IfLOG '$log';

use vars qw($VERSION);

use File::Slurp::Tiny qw(read_file write_file);
use Org::Document;
use Org::Dump qw();
use Scalar::Util qw(blessed);
use Text::vCard::Addressbook;

use Moo;
use experimental 'smartmatch';
extends 'Org::To::Base';

has default_country => (is => 'rw');
has export_notes => (is => 'rw');
has _vcf => (is => 'rw'); # vcf object
has _cccode => (is => 'rw'); # country calling code

require Exporter;
our @ISA;
push @ISA,       qw(Exporter);
our @EXPORT_OK = qw(org_to_vcf);

our %SPEC;
$SPEC{org_to_vcf} = {
    v => 1.1,
    summary => 'Export contacts in Org document to VCF (vCard addressbook)',
    args => {
        source_file => {
            summary => 'Source Org file to export',
            schema  => ['str' => {
            }],
        },
        source_str => {
            summary => 'Alternatively you can specify Org string directly',
            schema  => ['str' => {
            }],
        },
        target_file => {
            summary => 'VCF file to write to',
            schema => ['str' => {}],
            description => <<'_',

If not specified, VCF output string will be returned instead.

_
        },
        include_tags => {
            summary => 'Include trees that carry one of these tags',
            schema => ['array' => {
                of => 'str*',
            }],
            description => <<'_',

Works like Org's 'org-export-select-tags' variable. If the whole document
doesn't have any of these tags, then the whole document will be exported.
Otherwise, trees that do not carry one of these tags will be excluded. If a
selected tree is a subtree, the heading hierarchy above it will also be selected
for export, but not the text below those headings.

_
        },
        exclude_tags => {
            summary => 'Exclude trees that carry one of these tags',
            schema => ['array' => {
                of => 'str*',
            }],
            description => <<'_',

If the whole document doesn't have any of these tags, then the whole document
will be exported. Otherwise, trees that do not carry one of these tags will be
excluded. If a selected tree is a subtree, the heading hierarchy above it will
also be selected for export, but not the text below those headings.

exclude_tags is evaluated after include_tags.

_
        },
        default_country => {
            summary => 'Specify default country code',
            schema  => ['str*'],
            description => <<'_',

Free-form phone numbers on phone fields are formatted by this function, e.g.
`081 123 4567` becomes `0811234567`. If default country is specified (e.g.
"ID"), the number will be formatted as `+62811234567`. Setting this option is
recommended so the phone numbers are nicely formatted as international number.

_
        },
        export_notes => {
            summary => 'Whether to export note fields',
            schema  => ['bool*', default=>1],
        },
    }
};
sub org_to_vcf {
    my %args = @_;

    # XXX schema
    $args{export_notes} //= 1;

    my $doc;
    if ($args{source_file}) {
        $doc = Org::Document->new(from_string =>
                                      scalar read_file($args{source_file}));
    } elsif (defined($args{source_str})) {
        $doc = Org::Document->new(from_string => $args{source_str});
    } else {
        return [400, "Please specify source_file/source_str"];
    }

    my $obj = __PACKAGE__->new(
        include_tags    => $args{include_tags},
        exclude_tags    => $args{exclude_tags},
        default_country => $args{default_country},
        export_notes    => $args{export_notes},
    );

    my $vcf = Text::vCard::Addressbook->new;
    $obj->{_vcf} = $vcf;

    $obj->export($doc);
    #$log->tracef("vcf = %s", $vcf);
    if ($args{target_file}) {
        write_file($args{target_file}, $vcf->export);
        return [200, "OK"];
    } else {
        return [200, "OK", $vcf->export];
    }
}

sub BUILD {
    my ($self, $args) = @_;

    if ($args->{default_country}) {
        require Number::Phone::CountryCode;
        my $pc = Number::Phone::CountryCode->new($args->{default_country});
        die "Can't find country calling code for country ".
            "'$args->{default_country}'" unless $pc;
        $self->{_cccode} = $pc->country_code;
    }
}

sub _clean_field {
    my ($self, $str) = @_;
    $str =~ s/\s*#.+//g; # strip comments
    $str =~ s/\[\d+-\d+-\d+.*?\]//g; # strip timestamps
    $str =~ s/\A\s+//s; $str =~ s/\s+\z//s; # trim
    $str;
}

# XXX don't lose extension information, e.g. +62 22 1234567 ext 10
sub _format_phone {
    my ($self, $str) = @_;
    if ($str =~ /^\+/) {
        $str =~ s/[^0-9]//g;
        return "+$str";
    } else {
        $str =~ s/[^0-9]//g;
        if ($self->{_cccode}) {
            $str =~ s/^0//;
            return "+$self->{_cccode}$str";
        } else {
            return $str;
        }
    }
}

sub _parse_field {
    my ($self, $fields, $key, $textval, $vals) = @_;
    $vals = [$vals] unless ref($vals) eq 'ARRAY';
    if ($log->is_trace) {
        $log->tracef("parsing field: key=%s, textval=%s, vals=%s",
                     $key, $textval,
                     [map {blessed($_) && $_->isa('Org::Element') ?
                               Org::Dump::dump_element($_) : $_} @$vals]);
    }
    $key = $self->_clean_field($key);
    $textval = $self->_clean_field($textval);
    if ($key =~ /^((?:full\s?)?name |
                     nama(?:\slengkap)?)$/ix) {
        $fields->{FN} = $textval;
        $log->tracef("found FN field: %s", $textval);
    } elsif ($key =~ /^(birthday |
                          ultah|ulang\stahun|(?:tanggal\s|tgg?l\s)?lahir)$/ix) {
        # find the first timestamp field
        my @ts;
        for (@$vals) {
            $_->walk(sub {
                         push @ts, $_
                             if $_->isa('Org::Element::Timestamp');
                     });
        }
        if (@ts) {
            $fields->{BDAY} = $ts[0]->datetime->ymd;
            $log->tracef("found BDAY field: %s", $fields->{BDAY});
            $fields->{_has_contact} = 1;
        } else {
            # or from a regex match
            if ($textval =~ /(\d{4}-\d{2}-\d{2})/) {
                $fields->{BDAY} = $1;
                $log->tracef("found BDAY field: %s", $fields->{BDAY});
                $fields->{_has_contact} = 1;
            }
        }
    } elsif ($key =~ /(?:phone|cell|portable|mobile|mob|\bph\b|\bf\b|fax) |
                      (?:te?l[pf](on)|selul[ae]r|\bfaks|\bhp\b|\bhape\b)
                     /ix) {
        $fields->{TEL} //= {};
        my $type;
        if ($key =~ /fax |
                     faks/ix) {
            $type = "fax";
        } elsif ($key =~ /(?:cell|hand|portable|mob) |
                          (?:sel|hp|hape)
                         /ix) {
            $type = "mobile";
        } elsif ($key =~ /(?:wo?rk|office|ofc) |
                          (?:kerja|krj|kantor|ktr)
                         /ix) {
            $type = "work";
        } elsif ($key =~ /(?:home) |
                          (?:rumah|rmh)
                         /ix) {
            $type = "home";
        } else {
            # XXX use Number::Phone to parse phone number (is_mobile() etc)
            $type = "mobile";
        }
        $fields->{TEL}{$type} = $self->_format_phone($textval);
        $log->tracef("found TEL ($type) field: %s", $fields->{TEL}{$type});
        $fields->{_has_contact} = 1;
    } elsif ($key =~ /^((?:e[-]?mail|mail) |
                          (?:i[ -]?mel|surel))$/ix) {
        $fields->{EMAIL} = $textval;
        $log->tracef("found EMAIL field: %s", $fields->{EMAIL});
        $fields->{_has_contact} = 1;
    } else {
        # note is from note fields or everything that does not have field names
        # or any field that is not parsed (but limit it to 3 for now)
        $fields->{_num_notes} //= 0;
        if ($self->export_notes && $fields->{_num_notes}++ < 3) {
            $fields->{NOTE} .= ( $fields->{NOTE} ? "\n" : "" ) .
                ($key ? "$key: " : "") . $textval;
            $log->tracef("%s NOTE field: %s",
                         $fields->{_num_notes} == 1 ? "found" : "add",
                         $fields->{NOTE});
        }
    }
    # complex (but depreciated): N (name: family, given, middle, prefixes,
    # suffixes)

    # complex: ADR/addresses (po_box, extended, street, city, region, post_code,
    # country, lat, long)

    # complex: ORG (name, unit)

    # TITLE, ROLE, URL,NICKNAME
    # LABELS, PHOTO, TZ, MAILER?, PRODID?, REV?, SORT-STRING?, UID?, CLASS?
}

sub _add_vcard {
    no strict 'refs';

    my ($self, $fields) = @_;

    #$log->tracef("adding vcard");
    my $vc = $self->{_vcf}->add_vcard;
    for my $k (keys %$fields) {
        next if $k =~ /^_/;
        my $v = $fields->{$k};
        if (!ref($v)) {
            #$log->tracef("  adding simple vcard node: %s => %s", $k, $v);
            $vc->$k($v);
        } else {
            my @tt = keys %$v;
            for my $t (@tt) {
                #$log->tracef("  adding complex vcard node: %s, types=%s", $k, $t);
                my $node = $vc->add_node({
                    node_type=>$k,
                    types => $t, # doesn't work? must use add_types()
                });
                $node->add_types($t);
                $node->value($v->{$t});
            }
        }
    }
}

sub export_headline {
    my ($self, $elem) = @_;

    if ($log->is_trace) {
        require String::Escape;
        $log->tracef("exporting headline %s (%s) ...", ref($elem),
                     String::Escape::elide(
                         String::Escape::printable($elem->as_string), 30));
    }

    my $vcf = $self->{_vcf};
    my @subhl = grep {
        $_->isa('Org::Element::Headline') && !$_->is_todo }
        $self->_included_children($elem);

    my $fields = {}; # fields
    $fields->{FN} = $self->_clean_field($elem->title->as_string);

    for my $c (@{ $elem->children // [] }) {
        if ($c->isa('Org::Element::Drawer') && $c->name eq 'PROPERTIES') {
            # search fields in properties drawer
            my $props = $c->properties;
            $self->_parse_field($fields, $_, $props->{$_}) for keys %$props;
        } elsif ($c->isa('Org::Element::List')) {
            # search fields in list items
            for my $c2 (grep {$_->isa('Org::Element::ListItem')}
                            @{ $c->children // [] }) {
                if ($c2->desc_term) {
                    $self->_parse_field($fields,
                                        $c2->desc_term->as_string, # key
                                        $c2->children->[0]->as_string, # textval
                                        $c2->children); # val
                } else {
                    my $val = $c2->as_string;
                    my $key = $1 if $val =~ s/\A\s*[+-]\s+(\S+?):(.+)/$2/;
                    if ($key) {
                        $self->_parse_field($fields,
                                            $key,
                                            $val,
                                            $c2);
                    } else {
                        $self->_parse_field($fields, "note", $val, $c2);
                    }
                }
             }
        }
    }

    $log->tracef("fields: %s", $fields);
    $self->_add_vcard($fields) if $fields->{_has_contact};

    $self->export_headline($_) for @subhl;
}

sub export_elements {
    my ($self, @elems) = @_;

    $self->{_vcards} //= [];

  ELEM:
    for my $elem (@elems) {
        if ($elem->isa('Org::Element::Headline')) {
            $self->export_headline($elem);
        } elsif ($elem->isa('Org::Document')) {
            $self->export_elements(@{ $elem->children });
        } else {
            # ignore other elements
        }
    }
}

1;
# ABSTRACT: Export contacts in Org document to VCF (vCard addressbook)

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::To::VCF - Export contacts in Org document to VCF (vCard addressbook)

=head1 VERSION

This document describes version 0.08 of Org::To::VCF (from Perl distribution Org-To-VCF), released on 2015-09-03.

=head1 SYNOPSIS

 use Org::To::VCF qw(org_to_vcf);

 my $res = org_to_vcf(
     source_file   => 'addressbook.org', # or source_str
     #target_file  => 'addressbook.vcf', # defaults return the VCF in $res->[2]
     #include_tags => [...], # default exports all tags
     #exclude_tags => [...], # behavior mimics emacs's include/exclude rule
 );
 die "Failed" unless $res->[0] == 200;

=head1 DESCRIPTION

Export contacts in Org document to VCF (vCard addressbook).

My use case: I maintain my addressbook in an Org document C<addressbook.org>
which I regularly export to VCF and then import to Android phones.

How contacts are found in an Org document: each contact is written in an Org
headline (of whatever level) in a rather free-form format, e.g.:

 ** dad # [2014-01-25 Sat]  :remind_anniv:
 - fullname :: frasier crane
 - birthday :: [1900-01-02 ]
 - cell :: 0811 000 0001
 - some note
 *** TODO get dad's jakarta office number

Todo items (headline with todo labels) are currently excluded.

Contact fields are searched in list items. Currently Indonesian and English
phrases are supported. If name field is not found, the title of the headline is
used. I use timestamps a lot, so currently timestamps are stripped from headline
titles.

Perl-style comments (with C<#> to the end of the line) are allowed.

Org-contacts format is also supported, where fields are stored in a properties
drawer:

 * Friends
 ** Dave Null
 :PROPERTIES:
 :EMAIL: dave@null.com
 :END:
 This is one of my friend.
 *** TODO Call him for the party

=head1 FUNCTIONS


=head2 org_to_vcf(%args) -> [status, msg, result, meta]

Export contacts in Org document to VCF (vCard addressbook).

Arguments ('*' denotes required arguments):

=over 4

=item * B<default_country> => I<str>

Specify default country code.

Free-form phone numbers on phone fields are formatted by this function, e.g.
C<081 123 4567> becomes C<0811234567>. If default country is specified (e.g.
"ID"), the number will be formatted as C<+62811234567>. Setting this option is
recommended so the phone numbers are nicely formatted as international number.

=item * B<exclude_tags> => I<array[str]>

Exclude trees that carry one of these tags.

If the whole document doesn't have any of these tags, then the whole document
will be exported. Otherwise, trees that do not carry one of these tags will be
excluded. If a selected tree is a subtree, the heading hierarchy above it will
also be selected for export, but not the text below those headings.

exclude_tags is evaluated after include_tags.

=item * B<export_notes> => I<bool> (default: 1)

Whether to export note fields.

=item * B<include_tags> => I<array[str]>

Include trees that carry one of these tags.

Works like Org's 'org-export-select-tags' variable. If the whole document
doesn't have any of these tags, then the whole document will be exported.
Otherwise, trees that do not carry one of these tags will be excluded. If a
selected tree is a subtree, the heading hierarchy above it will also be selected
for export, but not the text below those headings.

=item * B<source_file> => I<str>

Source Org file to export.

=item * B<source_str> => I<str>

Alternatively you can specify Org string directly.

=item * B<target_file> => I<str>

VCF file to write to.

If not specified, VCF output string will be returned instead.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(default_country|export|export_.+)$

=head1 SEE ALSO

For more information about Org document format, visit http://orgmode.org/

L<Org::Parser>

L<Text::vCard>

Org-contacts: http://julien.danjou.info/projects/emacs-packages#org-contacts

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-To-VCF>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-To-VCF>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-To-VCF>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
