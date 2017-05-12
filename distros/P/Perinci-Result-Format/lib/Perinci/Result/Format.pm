package Perinci::Result::Format;

our $DATE = '2015-11-29'; # DATE
our $VERSION = '0.45'; # VERSION

use 5.010001;
use strict;
use warnings;

our $Enable_Decoration = 1;
our $Enable_Cleansing  = 0;

# text formats are special. since they are more oriented towards human instead
# of machine, we remove envelope when status is 2xx, so users only see content.

# XXX color theme?

my $format_text = sub {
    my ($format, $res) = @_;

    my $stack_trace_printed;

    my $print_err = sub {
        require Color::ANSI::Util;
        require Term::Detect::Software;

        my $use_color = $ENV{COLOR} // 1;
        my $terminfo = Term::Detect::Software::detect_terminal_cached();
        $use_color = 0 if !$terminfo->{color_depth};
        my $colorize = sub {
            my ($color, $str) = @_;
            if ($use_color) {
                if (ref($color) eq 'ARRAY') {
                    (defined($color->[0]) ?
                         Color::ANSI::Util::ansifg($color->[0]):"").
                               (defined($color->[1]) ?
                                    Color::ANSI::Util::ansibg($color->[1]):"").
                                          $str . "\e[0m";
                } else {
                    Color::ANSI::Util::ansifg($color) . $str . "\e[0m";
                }
            } else {
                $str;
            }
        };

        my $res = shift;
        my $out = $colorize->("cc0000", "ERROR $res->[0]") .
            ($res->[1] ? ": $res->[1]" : "");
        $out =~ s/\n+\z//;
        my $clog; $clog = $res->[3]{logs}[0]
            if $res->[3] && $res->[3]{logs};
        if ($clog->{file} && $clog->{line}) {
            $out .= " (at ".$colorize->('3399cc', $clog->{file}).
                " line ".$colorize->('3399cc', $clog->{line}).")";
        }
        $out .= "\n";
        if ($clog->{stack_trace} && $INC{"Carp/Always.pm"} &&
                !$stack_trace_printed) {
            require Data::Dump::OneLine;
            my $i;
            for my $c (@{ $clog->{stack_trace} }) {
                next unless $i++; # skip first entry
                my $args;
                if (!$c->[4]) {
                    $args = "()";
                } elsif (!ref($c->[4])) {
                    $args = "(...)";
                } else {
                    # periutil 0.37+ stores call arguments in [4]

                    # XXX a flag to let user choose which

                    # dump version
                    #$args = Data::Dump::OneLine::dump1(@{ $c->[4] });
                    #$args = "($args)" if @{$c->[4]} < 2;

                    # stringify version
                    $args = Data::Dump::OneLine::dump1(
                        map {defined($_) ? "$_":$_} @{ $c->[4] });
                    $args = "($args)" if @{$c->[4]} == 1;
                }
                $out .= "    $c->[3]${args} called at $c->[1] line $c->[2]\n";
            }
            $stack_trace_printed++;
        }
        $out;
    };

    if (!defined($res->[2])) {
        my $out = $res->[0] =~ /\A(?:2..|304)\z/ ? "" : $print_err->($res);
        my $max = 30;
        my $i = 0;
        my $prev = $res;
        while (1) {
            if ($i > $max) {
                $out .= "  Previous error list too deep, stopping here\n";
                last;
            }
            last unless $prev = $prev->[3]{prev};
            last unless ref($prev) eq 'ARRAY';
            $out .= "  " . $print_err->($prev);
            $i++;
        }
        return $out;
    }
    my ($r, $opts);
    if ($res->[0] =~ /\A2../) {
        $r = $res->[2];
        my $rfo = $res->[3]{format_options} // {};
        my $tff = $res->[3]{'table.fields'};
        if ($rfo->{$format}) {
            $opts = $rfo->{$format};
        } elsif ($rfo->{any}) {
            $opts = $rfo->{any};
        } elsif ($tff) {
            $opts = {table_column_orders=>[$tff]};
        }
    } else {
        $r = $res;
    }
    $opts //= {};
    if ($format eq 'text') {
        return Data::Format::Pretty::format_pretty(
            $r, {%$opts, module=>'Console'});
    }
    if ($format eq 'text-simple') {
        return Data::Format::Pretty::format_pretty(
            $r, {%$opts, module=>'SimpleText'});
    }
    if ($format eq 'text-pretty') {
        return Data::Format::Pretty::format_pretty(
            $r, {%$opts, module=>'Text'});
    }
};

our %Formats = (
    # YAML::Tiny::Color currently does not support circular refs
    yaml          => ['YAML', 'text/yaml', {circular=>0}],
    json          => ['CompactJSON', 'application/json', {circular=>0}],
    'json-pretty' => ['JSON', 'application/json', {circular=>0}],
    text          => [$format_text, 'text/plain', {circular=>0}],
    'text-simple' => [$format_text, 'text/plain', {circular=>0}],
    'text-pretty' => [$format_text, 'text/plain', {circular=>0}],
    'perl'        => ['Perl', 'text/x-perl', {circular=>1}],
    #'php'         => ['PHP', 'application/x-httpd-php', {circular=>0}],
    'phpserialization' => ['PHPSerialization', 'application/vnd.php.serialized', {circular=>0}],
    'ruby'        => ['Ruby', 'application/x-ruby', {circular=>1}],
);

sub format {
    require Data::Format::Pretty;

    my ($res, $format, $is_naked) = @_;

    my $fmtinfo = $Formats{$format} or return undef;
    my $formatter = $fmtinfo->[0];

    state $cleanser;
    if ($Enable_Cleansing && !$fmtinfo->[2]{circular}) {
        # currently we only have one type of cleansing, oriented towards JSON
        if (!$cleanser) {
            require Data::Clean::JSON;
            $cleanser = Data::Clean::JSON->get_cleanser;
        }
        $res = $cleanser->clone_and_clean($res);
    }

    my $deco = $Enable_Decoration;

    if (ref($formatter) eq 'CODE') {
        return $formatter->($format, $res);
    } else {
        my %o;
        $o{color} = 0 if !$deco && $format =~ /json|yaml|perl/;
        my $data = $is_naked ? $res->[2] : $res;
        return Data::Format::Pretty::format_pretty(
            $data, {%o, module=>$formatter});
    }
}

1;
# ABSTRACT: Format envelope result

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Result::Format - Format envelope result

=head1 VERSION

This document describes version 0.45 of Perinci::Result::Format (from Perl distribution Perinci-Result-Format), released on 2015-11-29.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module formats enveloped result to YAML, JSON, etc. It uses
L<Data::Format::Pretty> for the backend. It is used by other Perinci modules
like L<Perinci::CmdLine> and L<Perinci::Access::HTTP::Server>.

The default supported formats are:

=over 4

=item * json

Using Data::Format::Pretty::CompactJSON.

=item * json-pretty

Using Data::Format::Pretty::JSON.

=item * text-simple

Using Data::Format::Pretty::SimpleText.

=item * text-pretty

Using Data::Format::Pretty::Text.

=item * text

Using Data::Format::Pretty::Console.

=item * yaml

Using Data::Format::Pretty::YAML.

=item * perl

Using Data::Format::Pretty::Perl.

=item * phpserialization

Using Data::Format::Pretty::PHPSerialization.

=item * ruby

Using Data::Format::Pretty::Ruby.

=back

=for Pod::Coverage .*

=head1 VARIABLES

=head1 %Perinci::Result::Format::Formats => HASH

Contains a mapping between format names and Data::Format::Pretty::* module
names + MIME type.

=head1 $Enable_Decoration => BOOL (default: 1)

Decorations include color or other markup, which might make a data structure
like JSON or YAML string become invalid JSON/YAML. This should be turned off if
one wants to send the formatting over network.

=head1 $Enable_Cleansing => BOOL (default: 0)

If enabled, cleansing will be done to data to help make sure that data does not
contain item that cannot be handled by formatter. for example, JSON format
cannot handle circular references or complex types other than hash/array.

=head1 FUNCTIONS

None is currently exported/exportable.

=head1 format($res, $format[ , $is_naked=0 ]) => STR

Format enveloped result C<$res> with format named C<$format>.

Result metadata (C<< $res->[3] >>) is also checked for key named
C<format_options>. The value should be a hash like this C<< { FORMAT_NAME =>
OPTS, ... } >>. FORMAT_NAME can be C<any> to mean any format. This way, function
results can specify the details of formatting. An example enveloped result:

 [200, "OK", ["foo", "bar", "baz"], {
     format_options => {
         "text"        => {list_max_columns=>1},
         "text-pretty" => {list_max_columns=>1},
     }
 }]

The above result specifies that if it is displayed using C<text> or
C<text-pretty> format, it should be displayed in one columns instead of
multicolumns.

=head1 RESULT METADATA

=over

=item * property: format_options => HASH

=back

=head1 FAQ

=head2 How to list supported formats?

Simply:

 my @supported_formats = keys %Perinci::Result::Format::Formats;

=head2 How to add support for new formats?

First make sure that Data::Format::Pretty::<FORMAT> module is available for your
format. Look on CPAN. If it's not, i't also not hard to create one.

Then, add your format to %Perinci::Result::Format::Formats hash:

 use Perinci::Result::Format;

 # this means format named 'xml' will be handled by Data::Format::Pretty::XML
 $Perinci::Result::Format::Formats{xml} = ['XML', 'text/xml'];

=head1 SEE ALSO

L<Data::Format::Pretty>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Result-Format>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Result-Format>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Result-Format>

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
