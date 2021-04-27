package Myriad::Service;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Myriad::Service - starting point for building microservices

=head1 SYNOPSIS

 package Example::Service;
 use Myriad::Service;

 async method startup {
  $log->infof('Starting %s', __PACKAGE__);
 }

 # Trivial RPC call, provides the `example` method
 async method example : RPC {
  return { ok => 1 };
 }

 # Slightly more useful - return all the original parameters.
 # Due to an unfortunate syntactical choice in core Perl, the
 # whitespace before the (%args) is *mandatory*, without that
 # you're actually passing (%args) to the RPC attribute...
 async method echo : RPC (%args) {
  return \%args;
 }

 # Default internal diagnostics checks are performed automatically,
 # this method is called after the microservice status such as Redis
 # connections, exception status etc. are verified
 async method diagnostics ($level) {
  my ($self, $level) = @_;
  return 'ok';
 }

 1;

=head1 DESCRIPTION

Since this is a framework, by default it attempts to enforce a common standard on all microservice
modules. See L<Myriad::Class> for the details.

The calling package will be marked as an L<Object::Pad> class, providing the
L<Object::Pad/method>, L<Object::Pad/has> and C<async method> keywords.

This also makes available a L<Log::Any> instance in the C<$log> package variable,
and for L<OpenTracing::Any> support you get C<$tracer> as an L<OpenTracing::Tracer>
instance.

=head2 Custom language features

B<You can disable the language behaviour defaults> by specifying C<< :custom >> as an L</import> parameter:

    package Example::Service;
    use strict;
    use warnings;
    use Myriad::Service qw(:custom);
    use Log::Any qw($log);

This will only apply the L<Myriad::Service::Implementation> parent class, and avoid
any changes to syntax or other features.

=cut

no indirect qw(fatal);
no multidimensional;
no bareword::filehandles;
use mro;
use experimental qw(signatures);
use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Object::Pad;
use Scalar::Util;

use Heap;
use IO::Async::Notifier;
use IO::Async::SSL;
use Net::Async::HTTP;

use Myriad::Service::Implementation;
use Myriad::Config;

use Log::Any qw($log);
use OpenTracing::Any qw($tracer);

use Myriad::Exception::Builder category => 'service';

declare_exception SecureDefaultValue => (
    message => 'Secure configuration parameter may not have a default value'
);

our %SLOT;

sub import ($called_on, @args) {
    my $class = __PACKAGE__;
    my $pkg = caller(0);
    $INC{($pkg =~ s{::}{/}gr) . '.pm'} //= 1;

    if(grep { $_ eq ':custom' } @args) {
        push @{$pkg . '::ISA' }, 'Myriad::Service::Implementation', 'Myriad::Service';
        return;
    }

    my $version = 1;
    if(@args and $args[0] =~ /^:v([0-9]+)/) {
        $version = $1;
    }

    my $meta = Myriad::Class->import(
        ":v$version",
        target  => $pkg,
        extends => 'Myriad::Service::Implementation',
    );

    # Now we populate various slots, to be filled in when instantiating.
    # Currently we have `$api`, but might be helpful to provide `$storage`
    # and others directly here.
    $SLOT{$pkg} = {
        map { $_ => $meta->add_slot('$' . $_) } qw(
            api
        )
    };

    {
        no strict 'refs';

        push @{$pkg . '::ISA' }, 'Myriad::Service';

        *{$pkg . '::config'} = sub {
            my ($varname, %args) = @_;
            die 'config name is required' unless $varname;

            Myriad::Exception::Service::SecureDefaultValue->throw
                if defined($args{default}) and $args{secure};

            $Myriad::Config::SERVICES_CONFIG{$pkg}->{$varname} = \%args;

            $log->tracef("registered config %s for service %s", $varname, $pkg);
        }
    }
    return;
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

