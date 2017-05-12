package Perinci::Access::Lite;

our $DATE = '2016-09-25'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::AccessUtil qw(strip_riap_stuffs_from_res);

sub new {
    my ($class, %args) = @_;
    $args{riap_version} //= 1.1;
    bless \%args, $class;
}

# copy-pasted from SHARYANTO::Package::Util
sub __package_exists {
    no strict 'refs';

    my $pkg = shift;

    return unless $pkg =~ /\A\w+(::\w+)*\z/;
    if ($pkg =~ s/::(\w+)\z//) {
        return !!${$pkg . "::"}{$1 . "::"};
    } else {
        return !!$::{$pkg . "::"};
    }
}

sub request {
    no strict 'refs';

    my ($self, $action, $url, $extra) = @_;

    #say "D:request($action => $url)";

    $extra //= {};

    my $v = $extra->{v} // 1.1;
    if ($v ne '1.1' && $v ne '1.2') {
        return [501, "Riap protocol not supported, must be 1.1 or 1.2"];
    }

    my $res;
    if ($url =~ m!\A(?:pl:)?/(\w+(?:/\w+)*)/(\w*)\z!) {
        my ($mod_uripath, $func) = ($1, $2);
        (my $pkg = $mod_uripath) =~ s!/!::!g;
        my $mod_pm = "$mod_uripath.pm";

        my $pkg_exists;

      LOAD:
        {
            last if exists $INC{$mod_pm};
            $pkg_exists = __package_exists($pkg);
            # special names
            last LOAD if $pkg =~ /\A(main)\z/;
            last if $pkg_exists && defined(${"$pkg\::VERSION"});
            #say "D:Loading $pkg ...";
            eval { require $mod_pm };
            return [500, "Can't load module $pkg: $@"] if $@;
        }

        if ($action eq 'list') {
            return [501, "Action 'list' not implemented for ".
                        "non-package entities"]
                if length($func);
            no strict 'refs';
            my $spec = \%{"$pkg\::SPEC"};
            return [200, "OK (list)", [grep {/\A\w+\z/} sort keys %$spec]];
        } elsif ($action eq 'info') {
            my $data = {
                uri => "$mod_uripath/$func",
                type => (!length($func) ? "package" :
                             $func =~ /\A\w+\z/ ? "function" :
                                 $func =~ /\A[\@\$\%]/ ? "variable" :
                                     "?"),
            };
            return [200, "OK (info)", $data];
        } elsif ($action eq 'meta' || $action eq 'call') {
            return [501, "Action 'call' not implemented for package entity"]
                if !length($func) && $action eq 'call';
            my $meta;
            {
                no strict 'refs';
                if (length $func) {
                    $meta = ${"$pkg\::SPEC"}{$func}
                        or return [
                            500, "No metadata for '$url' (".
                                ($pkg_exists ? "package '$pkg' exists, perhaps you mentioned '$pkg' somewhere without actually loading the module, or perhaps '$func' is a typo?" :
                                     "package '$pkg' doesn't exist, perhaps '$mod_uripath' or '$func' is a typo?") .
                                ")"];
                } else {
                    $meta = ${"$pkg\::SPEC"}{':package'} // {v=>1.1};
                }
                $meta->{entity_v}    //= ${"$pkg\::VERSION"};
                $meta->{entity_date} //= ${"$pkg\::DATE"};
            }

            require Perinci::Sub::Normalize;
            $meta = Perinci::Sub::Normalize::normalize_function_metadata($meta);
            if ($action eq 'meta') {
                $meta->{_orig_args_as} = $meta->{args_as};
                $meta->{args_as} = 'hash';
                $meta->{_orig_result_naked} = $meta->{result_naked};
                $meta->{result_naked} = 0;
                return [200, "OK ($action)", $meta];
            }

            # form args (and add special args)
            my $args = { %{$extra->{args} // {}} }; # shallow copy
            if ($meta->{features} && $meta->{features}{progress}) {
                require Progress::Any;
                $args->{-progress} = Progress::Any->get_indicator;
            }

            # convert args
            my $aa = $meta->{args_as} // 'hash';
            my @args;
            if ($aa =~ /array/) {
                require Perinci::Sub::ConvertArgs::Array;
                my $convres = Perinci::Sub::ConvertArgs::Array::convert_args_to_array(
                    args => $args, meta => $meta,
                );
                return $convres unless $convres->[0] == 200;
                if ($aa =~ /ref/) {
                    @args = ($convres->[2]);
                } else {
                    @args = @{ $convres->[2] };
                }
            } elsif ($aa eq 'hashref') {
                @args = ({ %$args });
            } else {
                # hash
                @args = %$args;
            }

            # call!
            {
                no strict 'refs';
                $res = &{"$pkg\::$func"}(@args);
            }

            # add envelope
            if ($meta->{result_naked}) {
                $res = [200, "OK (envelope added by ".__PACKAGE__.")", $res];
            }

            # add hint that result is binary
            if (defined $res->[2]) {
                if ($meta->{result} && $meta->{result}{schema} &&
                        $meta->{result}{schema}[0] eq 'buf') {
                    $res->[3]{'x.hint.result_binary'} = 1;
                }
            }

        } else {
            return [501, "Unknown/unsupported action '$action'"];
        }
    } elsif ($url =~ m!\Ahttps?:/(/?)!i) {
        my $is_unix = !$1;
        my $ht;
        require JSON;
        state $json = JSON->new->allow_nonref;
        if ($is_unix) {
            require HTTP::Tiny::UNIX;
            $ht = HTTP::Tiny::UNIX->new;
        } else {
            require HTTP::Tiny;
            $ht = HTTP::Tiny->new;
        }
        my %headers = (
            "x-riap-v" => $self->{riap_version},
            "x-riap-action" => $action,
            "x-riap-fmt" => "json",
            "content-type" => "application/json",
        );
        my $args = $extra->{args} // {};
        for (keys %$extra) {
            next if /\Aargs\z/;
            $headers{"x-riap-$_"} = $extra->{$_};
        }
        my $htres = $ht->post(
            $url, {
                headers => \%headers,
                content => $json->encode($args),
            });
        return [500, "Network error: $htres->{status} - $htres->{reason}"]
            if $htres->{status} != 200;
        return [500, "Server error: didn't return JSON (".$htres->{headers}{'content-type'}.")"]
            unless $htres->{headers}{'content-type'} eq 'application/json';
        return [500, "Server error: didn't return Riap 1.1 response (".$htres->{headers}{'x-riap-v'}.")"]
            unless $htres->{headers}{'x-riap-v'} =~ /\A1\.1(\.\d+)?\z/;
        $res = $json->decode($htres->{content});
    } else {
        return [501, "Unsupported scheme or bad URL '$url'"];
    }

    strip_riap_stuffs_from_res($res);
}

1;
# ABSTRACT: A lightweight Riap client library

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::Lite - A lightweight Riap client library

=head1 VERSION

This document describes version 0.14 of Perinci::Access::Lite (from Perl distribution Perinci-Access-Lite), released on 2016-09-25.

=head1 DESCRIPTION

This module is a lightweight alternative to L<Perinci::Access>. It has less
prerequisites but does fewer things. The things it supports:

=over

=item * Local (in-process) access to Perl modules and functions

Currently only C<call>, C<meta>, and C<list> actions are implemented. Variables
and other entities are not yet supported.

The C<list> action only gathers keys from C<%SPEC> and do not yet list
subpackages.

=item * HTTP/HTTPS

=item * HTTP over Unix socket

=back

Differences with Perinci::Access:

=over

=item * For network access, uses HTTP::Tiny module family instead of LWP

This results in fewer dependencies.

=item * No wrapping, no argument checking

For 'pl' or schemeless URL, no wrapping (L<Perinci::Sub::Wrapper>) is done, only
normalization (using L<Perinci::Sub::Normalize>).

=item * No transaction or logging support

=item * No support for some schemes

This includes: Riap::Simple over pipe/TCP socket.

=back

=head1 ADDED RESULT METADATA

This class might add the following property/attribute in result metadata:

=head2 x.hint.result_binary => bool

If result's schema type is C<buf>, then this class will set this attribute to
true, to give hints to result formatters.

=head1 ATTRIBUTES

=head2 riap_version => float (default: 1.1)

=head1 METHODS

=head2 new(%attrs) => obj

=head2 $pa->request($action, $url, $extra) => hash

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Access-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Access>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
