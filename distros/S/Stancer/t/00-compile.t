use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 88 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Stancer.pm',
    'Stancer/Auth.pm',
    'Stancer/Auth/Status.pm',
    'Stancer/Card.pm',
    'Stancer/Config.pm',
    'Stancer/Core/Iterator.pm',
    'Stancer/Core/Iterator/Dispute.pm',
    'Stancer/Core/Iterator/Payment.pm',
    'Stancer/Core/Object.pm',
    'Stancer/Core/Request.pm',
    'Stancer/Core/Request/Call.pm',
    'Stancer/Core/Types.pm',
    'Stancer/Core/Types/ApiKeys.pm',
    'Stancer/Core/Types/Bank.pm',
    'Stancer/Core/Types/Bases.pm',
    'Stancer/Core/Types/Dates.pm',
    'Stancer/Core/Types/Helper.pm',
    'Stancer/Core/Types/Network.pm',
    'Stancer/Core/Types/Object.pm',
    'Stancer/Core/Types/String.pm',
    'Stancer/Customer.pm',
    'Stancer/Device.pm',
    'Stancer/Dispute.pm',
    'Stancer/Exceptions/BadMethodCall.pm',
    'Stancer/Exceptions/Http.pm',
    'Stancer/Exceptions/Http/BadRequest.pm',
    'Stancer/Exceptions/Http/ClientSide.pm',
    'Stancer/Exceptions/Http/Conflict.pm',
    'Stancer/Exceptions/Http/InternalServerError.pm',
    'Stancer/Exceptions/Http/NotFound.pm',
    'Stancer/Exceptions/Http/ServerSide.pm',
    'Stancer/Exceptions/Http/Unauthorized.pm',
    'Stancer/Exceptions/InvalidAmount.pm',
    'Stancer/Exceptions/InvalidArgument.pm',
    'Stancer/Exceptions/InvalidAuthInstance.pm',
    'Stancer/Exceptions/InvalidBic.pm',
    'Stancer/Exceptions/InvalidCardExpiration.pm',
    'Stancer/Exceptions/InvalidCardInstance.pm',
    'Stancer/Exceptions/InvalidCardNumber.pm',
    'Stancer/Exceptions/InvalidCardVerificationCode.pm',
    'Stancer/Exceptions/InvalidCurrency.pm',
    'Stancer/Exceptions/InvalidCustomerInstance.pm',
    'Stancer/Exceptions/InvalidDescription.pm',
    'Stancer/Exceptions/InvalidDeviceInstance.pm',
    'Stancer/Exceptions/InvalidEmail.pm',
    'Stancer/Exceptions/InvalidExpirationMonth.pm',
    'Stancer/Exceptions/InvalidExpirationYear.pm',
    'Stancer/Exceptions/InvalidExternalId.pm',
    'Stancer/Exceptions/InvalidIban.pm',
    'Stancer/Exceptions/InvalidIpAddress.pm',
    'Stancer/Exceptions/InvalidMethod.pm',
    'Stancer/Exceptions/InvalidMobile.pm',
    'Stancer/Exceptions/InvalidName.pm',
    'Stancer/Exceptions/InvalidOrderId.pm',
    'Stancer/Exceptions/InvalidPaymentInstance.pm',
    'Stancer/Exceptions/InvalidPort.pm',
    'Stancer/Exceptions/InvalidRefundInstance.pm',
    'Stancer/Exceptions/InvalidSearchCreation.pm',
    'Stancer/Exceptions/InvalidSearchFilter.pm',
    'Stancer/Exceptions/InvalidSearchLimit.pm',
    'Stancer/Exceptions/InvalidSearchOrderId.pm',
    'Stancer/Exceptions/InvalidSearchStart.pm',
    'Stancer/Exceptions/InvalidSearchUniqueId.pm',
    'Stancer/Exceptions/InvalidSearchUntilCreation.pm',
    'Stancer/Exceptions/InvalidSepaCheckInstance.pm',
    'Stancer/Exceptions/InvalidSepaInstance.pm',
    'Stancer/Exceptions/InvalidUniqueId.pm',
    'Stancer/Exceptions/InvalidUrl.pm',
    'Stancer/Exceptions/MissingApiKey.pm',
    'Stancer/Exceptions/MissingPaymentId.pm',
    'Stancer/Exceptions/MissingPaymentMethod.pm',
    'Stancer/Exceptions/MissingReturnUrl.pm',
    'Stancer/Exceptions/Throwable.pm',
    'Stancer/Payment.pm',
    'Stancer/Payment/Status.pm',
    'Stancer/Refund.pm',
    'Stancer/Refund/Status.pm',
    'Stancer/Role/Amount/Read.pm',
    'Stancer/Role/Amount/Write.pm',
    'Stancer/Role/Country.pm',
    'Stancer/Role/Name.pm',
    'Stancer/Role/Payment/Auth.pm',
    'Stancer/Role/Payment/Methods.pm',
    'Stancer/Role/Payment/Page.pm',
    'Stancer/Role/Payment/Refund.pm',
    'Stancer/Sepa.pm',
    'Stancer/Sepa/Check.pm',
    'Stancer/Sepa/Check/Status.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


