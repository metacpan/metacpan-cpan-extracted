package Myriad::Class;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Myriad::Class - common pragmata for L<Myriad> core modules

=head1 SYNOPSIS

 package Example::Class;
 use Myriad::Class;

 async method startup {
  $log->infof('Starting %s', __PACKAGE__);
 }

 1;

=head1 DESCRIPTION

Since L<Myriad> is a framework, by default it attempts to enforce a common
standard on all microservice modules. This same standard is used in most of
the modules which comprise L<Myriad> itself.

The following Perl language features and modules are applied:

=over 4

=item * L<strict>

=item * L<warnings>

=item * L<utf8>

=item * L<perlsub/signatures>

=item * no L<indirect>

=item * no L<multidimensional>

=item * no L<bareword::filehandles>

=item * L<Syntax::Keyword::Try>

=item * L<Syntax::Keyword::Dynamically>

=item * L<Syntax::Keyword::Defer>

=item * L<Future::AsyncAwait>

=item * provides L<Scalar::Util/blessed>, L<Scalar::Util/weaken>, L<Scalar::Util/refaddr>

=item * provides L<List::Util/min>, L<List::Util/max>, L<List::Util/sum0>

=item * provides L<List::Keywords/any>, L<List::Keywords/all>

=item * provides L<JSON::MaybeUTF8/encode_json_text>, L<JSON::MaybeUTF8/encode_json_utf8>,
L<JSON::MaybeUTF8/decode_json_text>, L<JSON::MaybeUTF8/decode_json_utf8>, L<JSON::MaybeUTF8/format_json_text>

=item * provides L<Unicode::UTF8/encode_utf8>, L<Unicode::UTF8/decode_utf8>

=back

In addition, the following core L<feature>s are enabled:

=over 4

=item * L<bitwise|feature>

=item * L<current_sub|feature>

=item * L<evalbytes|feature>

=item * L<fc|feature>

=item * L<postderef_qq|feature>

=item * L<state|feature>

=item * L<unicode_eval|feature>

=item * L<unicode_strings|feature>

=back

The calling package will be marked as an L<Object::Pad> class, providing the
L<Object::Pad/method>, L<Object::Pad/has> and C<async method> keywords.

This also makes available a L<Log::Any> instance in the C<$log> package variable,
and for L<OpenTracing::Any> support you get C<$tracer> as an L<OpenTracing::Tracer>
instance.

It's very likely that future versions will bring in new functionality or
enable/disable a different featureset. This behaviour will be controlled through
version tags:

 use Myriad::Class qw(:v1);

with the default being C<:v1>.

=cut

use Object::Pad;
use Object::Pad qw(:experimental(mop));
no indirect qw(fatal);
no multidimensional;
no bareword::filehandles;
use mro;
use experimental qw(signatures);
use curry;
use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Syntax::Keyword::Defer;
use Syntax::Keyword::Match;
use Syntax::Operator::Equ;
use Scalar::Util;
use List::Util;
use List::Keywords;
use Future::Utils;
use Module::Load ();

use JSON::MaybeUTF8;
use Unicode::UTF8;

use Heap;
use IO::Async::Notifier;

use Log::Any qw($log);
use OpenTracing::Any qw($tracer);
use Metrics::Any;

sub import {
    my $called_on = shift;

    # Unused, but we'll support it for now.
    my $version = 1;
    if(@_ and $_[0] =~ /^:v([0-9]+)/) {
        $version = $1;
        shift;
    }
    my %args = @_;

    my $class = __PACKAGE__;
    my $pkg = $args{target} // caller(0);

    # Apply core syntax and rules
    strict->import;
    warnings->import;
    utf8->import;

    # We want mostly the 5.26 featureset, but since that includes `say` and `switch`
    # we need to customise the list somewhat
    feature->import(qw(
        bitwise
        current_sub
        evalbytes
        fc
        postderef_qq
        state
        unicode_eval
        unicode_strings
    ));

    # Indirect syntax is problematic due to `unknown_sub { ... }` compiling and running
    # the block without complaint, and only failing at runtime *after* the code has
    # executed once - particularly unfortunate with try/catch
    indirect->unimport(qw(fatal));
    # Multidimensional array access - $x{3,4} - is usually a sign that someone wanted
    # `@x{3,4}` or similar instead, so we disable this entirely
    multidimensional->unimport;
    # Plain STDIN/STDOUT/STDERR are still allowed, although hopefully never used by
    # service code - new filehandles need to be lexical.
    bareword::filehandles->unimport;

    # This one's needed for nested scope, e.g. { package XX; use Myriad::Service; method xxx (%args) ... }
    experimental->import('signatures');

    # We don't really care about diamond inheritance, since microservices are expected
    # to have minimal inheritance in the first place, but might as well have a standard
    # decision to avoid surprises in future
    mro::set_mro($pkg => 'c3');

    # Helper functions which are used often enough to be valuable as a default
    Scalar::Util->export($pkg => qw(refaddr blessed weaken));
    List::Util->export($pkg => qw(min max sum0));
    {
        no strict 'refs';
        *{$pkg . '::' . $_} = JSON::MaybeUTF8->can($_) for qw(
            encode_json_text
            encode_json_utf8
            decode_json_text
            decode_json_utf8
            format_json_text
        );
        *{$pkg . '::' . $_} = Unicode::UTF8->can($_) for qw(
            encode_utf8
            decode_utf8
        );
    }
    {
        no strict 'refs';
        *{$pkg . '::' . $_} = Future::Utils->can($_) for qw(
            fmap_void
            fmap_concat
            fmap_scalar
            fmap0
            fmap1
        );
    }

    {
        no strict 'refs';
        # trim() might appear in core perl at some point, so let's reserve the
        # word and include a basic implementation first. Avoiding Text::Trim
        # here because it sometimes returns an empty list, which would be
        # dangerous - my %hash = (key => trim($value)) for example.
        *{$pkg . '::trim'} = sub ($txt) {
            return undef unless defined $txt;
            $txt =~ s{^\s+}{};
            $txt =~ s{\s+$}{};
            return $txt;
        };
    }

    # Some well-designed modules provide direct support for import target
    Syntax::Keyword::Try->import_into($pkg, try => ':experimental(typed)');
    Syntax::Keyword::Dynamically->import_into($pkg);
    Syntax::Keyword::Defer->import_into($pkg);
    Syntax::Operator::Equ->import_into($pkg);
    Future::AsyncAwait->import_into($pkg, ':experimental(cancel)');
    Metrics::Any->import_into($pkg, '$metrics');

    # Others use lexical hints
    List::Keywords->import(qw(any all));
    Syntax::Keyword::Match->import(qw(match));

    {
        no strict 'refs';
        # Essentially the same as importing Log::Any qw($log) for now,
        # but we may want to customise this with some additional attributes.
        # Note that we have to store a ref to the returned value, don't
        # drop that backslash...
        *{$pkg . '::log'} = \Log::Any->get_logger(
            category => $pkg
        );
        *{$pkg . '::tracer'}  = \(OpenTracing->global_tracer);
    }

    if(my $class = $args{class} // $pkg) {
        # For history here, see this:
        # https://rt.cpan.org/Ticket/Display.html?id=132337
        # We do this first to get the keywords...
        Object::Pad->import_into($pkg);
        # ... and then _again_ to disable the experimental warnings
        Object::Pad->import_into($pkg, qw(:experimental));
        my $method = 'begin_' . ($args{type} || 'class');
        my $meta = Object::Pad::MOP::Class->$method(
            $class,
            (
                $args{extends}
                ? (extends => $args{extends})
                : ()
            ),
        );
        $args{does} = [ $args{does} // () ] unless ref $args{does};
        for my $role ($args{does}->@*) {
            Module::Load::load($role) unless eval { Object::Pad::MOP::Class->for_class($role) };
            $meta->add_role($role);
        }
        return $meta;
    }
    return $pkg;
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

